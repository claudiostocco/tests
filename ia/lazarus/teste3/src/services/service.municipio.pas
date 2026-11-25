unit service.municipio;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, DB, Generics.Collections, StrUtils,
  (* Project units *)
  DataSet.Serialize,
  adapter.query.intf, connector.factory, adapter.json,
  service.ServiceProvider, service.ServiceProvidercadastros, service.commons;

type

  { TMunicipioService }

  TMunicipioService = class(TServiceProviderCadastros)
    private
      FSQLSelect: String;
    public
      constructor Create(ConnectionId: String);
      procedure SetResumo;
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
  end;

implementation

{ TMunicipioService }

constructor TMunicipioService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM MUNICIPIO ';
end;

procedure TMunicipioService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, CIDADE, (SELECT UF FROM ESTADO WHERE ID = SUBSTRING(MUNICIPIO.ID FROM 1 FOR 2)) AS UF '+
                'FROM MUNICIPIO ';
end;

function TMunicipioService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere, sIDUf: String;
    pCond: TPair<String,String>;
begin
  try
    sWhere := '';
    for pCond in AParams do
    begin
      if pCond.Key = 'uf' then
      begin
        sIDUf := TQueryFactory.New(dmConn,dmConn.dbConnection)
                              .Open('SELECT ID FROM ESTADO WHERE UF = '''+pCond.Value.toUpper+'''')
                              .AsDataSet
                              .FieldByName('ID')
                              .Text;
        if sIDUf.IsEmpty then
          raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Estado inválido!');
        sWhere := sWhere + IfThen(sWhere.IsEmpty,'',' AND ') + 'ESTADOID = ' + sIDUf;
      end else if pCond.Key = 'cidade' then
        sWhere := sWhere + IfThen(sWhere.IsEmpty,'',' AND ') + 'UPPER(' + pCond.Key + ') CONTAINING ''' + pCond.Value.toUpper + ''''
      else
        sWhere := sWhere + IfThen(sWhere.IsEmpty,'',' AND ') + pCond.Key + ' = ''' + pCond.Value + '''';
    end;
    if not sWhere.IsEmpty then
      sWhere := 'WHERE '+sWhere;

    Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
             .Select(FSQLSelect+sWhere)
      	     .Open;
    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TMunicipioService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue, 'MUNICIPIO');
end;

function TMunicipioService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, 'MUNICIPIO');
end;

end.
