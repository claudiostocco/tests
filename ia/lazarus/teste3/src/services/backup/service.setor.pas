unit service.setor;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, Generics.Collections, StrUtils,
  (* Project units *)
  DataSet.Serialize,
  service.commons, service.ServiceProvider, service.ServiceProviderCadastros, adapter.query.intf,
  connector.factory, adapter.json;

type

  { TSetorService }

  TSetorService = class(TServiceProviderCadastros)
    private
      FSQLSelect: String;
      function processRequest(Value: String): String;
    public
      constructor Create(ConnectionId: String);
      procedure SetResumo;
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function delete(id: String): Boolean; overload; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
  end;

implementation

const SQL_NOME_SETOR = '(SELECT DESCRICAO FROM SETOR WHERE ID = s.SETORID) AS SETORDESCRICAO';
const SQL_NOME_ICMS = '(SELECT DESCRICAO FROM ICMS WHERE ID = s.ICMSID) AS ICMSDESCRICAO';
const SQL_FULL = 'SELECT s.ID, s.DESCRICAO, s.STATUS, s.SETORID, s.ICMSID, s.HIERARQUIA, '+
                 SQL_NOME_SETOR+', '+SQL_NOME_ICMS+' FROM SETOR s ';

{ TSetorService }

function TSetorService.processRequest(Value: String): String;
var jsonValue: TJSONObject;
    sIDPai, sHierarquia: String;
begin
  try
    try
      jsonValue := GetJSON(Value) as TJSONObject;
      sIDPai := jsonValue.Strings['setorid'];
      sHierarquia := '';
      if StrToIntDef(sIDPai.Trim,0) > 0 then
      begin
        with TQueryFactory.New
                             .Open('SELECT HIERARQUIA FROM SETOR WHERE ID = '+sIDPai)
                             .AsDataSet do
        begin
          if IsEmpty then
            raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Sertor pai não encontrado!');

          sHierarquia := FieldByName('HIERARQUIA').Text;
          sHierarquia := sHierarquia+IfThen(sHierarquia.Trim.IsEmpty,'',',')+sIDPai
        end;
      end;
    finally
      jsonValue.Add('hierarquia',sHierarquia);
      Result := jsonValue.AsJSON;
      jsonValue.Free;
    end;
  except on E: Exception do
    raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Erro ao processar corpo da requisição: '+E.Message);
  end;
end;

constructor TSetorService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := SQL_FULL;
end;

procedure TSetorService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, DESCRICAO FROM SETOR ';
end;

function TSetorService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere: String;
    pCond: TPair<String,String>;
begin
  try
    sWhere := 'WHERE ';
    for pCond in AParams do
    begin
      if pCond.Key = 'descricao' then
        sWhere := sWhere + 'UPPER(' + pCond.Key + ') CONTAINING ''' + pCond.Value.toUpper + ''' AND '
      else
        sWhere := sWhere + pCond.Key + ' = ''' + pCond.Value + ''' AND ';
    end;
    sWhere := sWhere + IfThen(CanceledOnly,'STATUS = ''C'' ', 'STATUS <> ''C'' ');

    Query := TQueryFactory.New
             .Select(FSQLSelect+sWhere)
      	     .Open;
    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TSetorService.delete(id: String): Boolean;
begin
  Result := inherited delete(id,'SETOR');
end;

function TSetorService.insert(AValue: String): Boolean;
begin
  AValue := processRequest(AValue);
  Result := inherited insert(AValue,'SETOR');
end;

function TSetorService.update(AValue: String): Boolean;
begin
  AValue := processRequest(AValue);
  Result := inherited update(AValue, 'SETOR');
end;

end.
