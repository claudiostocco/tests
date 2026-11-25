unit service.movimento;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, Generics.Collections, StrUtils, DateUtils,
  (* Project units *)
  DataSet.Serialize,
  service.ServiceProvider, service.ServiceProviderCadastros, adapter.query.intf,
  service.commons, connector.factory, adapter.json, utils;

type

  { TMovimentoService }

  TMovimentoService = class(TServiceProviderCadastros)
    private
      FSQLSelect: String;
      FSQLValor: String;
      FSQLCusto: String;
      FSQLWhere: String;
      FSQLOrder: String;
      FTipoMovId: SmallInt;
    public
      constructor Create(ConnectionId: String);
      procedure SetTipoMovId(value: SmallInt);
      procedure SetResumo;
      procedure SetReport(ABody: String);
      procedure SetFull;
      procedure SetLastSale;
      procedure SetTodayFilter;
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function delete(id: String): Boolean; overload; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
  end;

implementation

const SQL_ENTNOME = '(SELECT NOME FROM ENTIDADE WHERE ID = MOVIMENTO.ENTIDADEID) AS ENTIDADENOME ';
const SQL_MOV = 'SELECT ID, EMPRESAID, TERMINALID, MOVTIPOID, MDFID, NUMERO, EMISSAO, '+
                'ENTIDADEID, STATUS, CPGTOID, OBSERVACAO, NATUREZAOPID, '+SQL_ENTNOME;
const SQL_MOV_VALOR_VENDA = 'COALESCE((SELECT SUM(TOTAL) FROM MOVITEM '+
                            'WHERE ID = MOVIMENTO.ID AND STATUS <> ''C''),0) AS VALOR ';
const SQL_MOV_CUSTO_VENDA = 'COALESCE((SELECT SUM(CUSTO*QUANTIDADE) FROM MOVITEM '+
                            'WHERE ID = MOVIMENTO.ID AND STATUS <> ''C''),0) AS CUSTO ';
const SQL_MOV_VALOR_CTRC = 'COALESCE((SELECT SUM(TOTAL) FROM MOVITEM '+
                           'WHERE ID = MOVIMENTO.ID AND STATUS <> ''C''),0) AS VALOR ';

{ TMovimentoService }

constructor TMovimentoService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := '';
  FSQLWhere := '';
  FSQLOrder := '';
  FSQLCusto := '';
end;

procedure TMovimentoService.SetTipoMovId(value: SmallInt);
begin
  FTipoMovId := value;
  case FTipoMovId of
    0,1,2,4: FSQLValor := SQL_MOV_VALOR_VENDA;
    3: FSQLValor := SQL_MOV_VALOR_CTRC;
  end;
end;

procedure TMovimentoService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, TERMINALID, MDFID, NUMERO, EMISSAO, ENTIDADEID, STATUS, '+
                SQL_ENTNOME+', '+FSQLValor+'FROM MOVIMENTO ';
  FSQLOrder := 'ORDER BY EMISSAO';
end;

procedure TMovimentoService.SetReport(ABody: String);
var jsonBody: TJSONValue;
begin
  if (not ABody.IsEmpty) then
  begin
    jsonBody := GetJSON(ABody);
    if not (jsonBody is TJSONObject) then
      raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('É obrigatório corpo para a requisição!');
    try
      with (jsonBody as TJSONObject) do
      begin
        if (Find('fields') <> nil) and ((Find('fields') as TJSONArray).Count > 0) then
          FSQLSelect := 'SELECT '+ProcessJsonFields(Find('fields') as TJSONArray)+' FROM MOVIMENTO '
        else
        begin
          if FTipoMovId in [0,1,2,4] then FSQLCusto := ', '+SQL_MOV_CUSTO_VENDA;
          SetFull; // Mesmo SQL que a consulta completa.
        end;
        if (Find('filters') <> nil) and ((Find('filters') as TJSONArray).Count > 0) then
          FSQLWhere := ' AND '+ProcessJsonFilters(Find('filters') as TJSONArray)
        else
          raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('É obrigatório informar filtro para esta consulta!');
      end;
    except on E: Exception do
      raise EHttpException.New.Status(THTTPStatus.BadRequest).Error(e.Message);
    end;
  end;
end;

procedure TMovimentoService.SetFull;
begin
  FSQLSelect := SQL_MOV+', '+FSQLValor+FSQLCusto+'FROM MOVIMENTO ';
end;

procedure TMovimentoService.SetLastSale;
begin
  (* Necessário executar SetFull antes *)
  SetFull;

  FSQLSelect := 'SELECT FIRST 1 '+FSQLSelect.Substring(6);
  FSQLOrder := 'ORDER BY ID DESC';
end;

procedure TMovimentoService.SetTodayFilter;
begin
  FSQLWhere := FSQLWhere+' AND EMISSAO >= CURRENT_DATE ';
end;

function TMovimentoService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere, sValue: String;
    pCond: TPair<String,String>;
    dValue: TDateTime;
begin
  try
    sWhere := 'WHERE ';
    for pCond in AParams do
    begin
      if MatchStr(pCond.Key,['emissao','numero']) then
      begin
        if pCond.Key = 'emissao' then
        begin
          if pCond.Value.Length < 4 then Exit;
          if TryISO8601ToDate(pCond.Value,dValue) then
            sValue := FormatDateTime('dd.mm.yyyy',dValue)
          else
            sValue := '01.01.1900';
          sWhere := sWhere + pCond.Key + ' BETWEEN ''' + sValue + ''' AND ''' + sValue + ' 23:59:59'' AND '
        end else
        begin
          sValue := pCond.Value;
          sWhere := sWhere + pCond.Key + ' CONTAINING ''' + sValue + ''' AND '
        end;
      end else
        sWhere := sWhere + pCond.Key + ' = ''' + pCond.Value + ''' AND ';
    end;
    sWhere := sWhere + IfThen(CanceledOnly,'STATUS = ''C'' ', 'STATUS <> ''C'' ');
    sWhere := sWhere + FSQLWhere;

    Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
             .Select(FSQLSelect+sWhere+FSQLOrder)
      	     .Open;
    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TMovimentoService.delete(id: String): Boolean;
begin
  Result := inherited delete(id,'MOVIMENTO');
end;

function TMovimentoService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue,'MOVIMENTO');
end;

function TMovimentoService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, 'MOVIMENTO');
end;

end.
