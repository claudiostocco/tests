unit service.produto.dm;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  Classes, SysUtils, ZConnection, ZDataset, Generics.Collections, DB, StrUtils,
  (* Project units *)
  DataSet.Serialize,
  adapter.json, connector.configuration, service.commons, service.ServiceProvider;

type

  { TdmProdutoService }

  TdmProdutoService = class(TDataModule)
    DataSource: TDataSource;
    ZConnection: TZConnection;
    Query: TZQuery;
    precos: TZQuery;
    icms: TZQuery;
    piscofins: TZQuery;
  private
    FSQLTabela, FSQLSelect: String;
    function GetWherePEmp(ProdutoId, EmpresaId: String): String;
    procedure SetQueryPPreco(ProdutoId, EmpresaId: String);
    procedure SetQueryPIcms(ProdutoId, EmpresaId: String);
    procedure SetQueryPPisCofins(ProdutoId, EmpresaId: String);
    procedure LogError(error: Exception; datails: String);
  public
    CanceledOnly: Boolean;
    ServiceResult: TServiceProviderResult;
    constructor Create(ConnectionId: String);
    procedure SetTabela(Path: String);
    procedure SetProduto(Id: String; EmpresaId: String = '');
    procedure SetResumo;
    function listAll(AParams: TDictionary<String,String>): Boolean;
    function delete(id: String): Boolean;
    function insert(AValue: String): Boolean;
    function update(AValue: String): Boolean;
  end;

var
  dmProdutoService: TdmProdutoService;

const SQL_PRD_PRECO = 'SELECT CURRENT_CONNECTION, ID, EMPRESAID, CUSTO, PRECO, PRECOPROMOCAO, PROMOCAODE, PROMOCAOATE FROM PRODUTOPRECO ';
const SQL_PRD_ICMS = 'SELECT CURRENT_CONNECTION, ID, EMPRESAID, ICMSID, (SELECT DESCRICAO FROM ICMS WHERE ID = PRODUTOICMS.ICMSID) AS ICMSDESCRICAO '+
                     'FROM PRODUTOICMS ';
const SQL_PRD_PISCOFINS = 'SELECT CURRENT_CONNECTION, ID, EMPRESAID, CSTCOFINSID, CSTPISID, CSTCOFINSIDENT, CSTPISIDENT FROM PRODUTOPISCOFINS ';

const SQL_PRD = 'SELECT CURRENT_CONNECTION, ID, DESCRICAO, COMPLEMENTO, REFERENCIA, FABRICANTEID, SETORID, UNIDADEID, PRODUTOORIGEMID, '+
                'PRODUTOTIPOID, COMBUSTIVEL, NCMID, CODIGONR, CONTROLAESTOQUE, ESTOQUEMINIMO, STATUS, DTCADASTRO, '+
                '(SELECT NOME FROM ENTIDADE WHERE ID = PRODUTO.FABRICANTEID) AS FABRICANTE, '+
                '(SELECT DESCRICAO FROM SETOR WHERE ID = PRODUTO.SETORID) AS SETORDESCRICAO '+
                'FROM PRODUTO ';

implementation

{$R *.lfm}

{ TdmProdutoService }

function TdmProdutoService.GetWherePEmp(ProdutoId, EmpresaId: String): String;
begin
  if not ProdutoId.IsEmpty then Result := 'ID = ''' + ProdutoId + '''';
  if not EmpresaId.IsEmpty then Result := IfThen(Result.IsEmpty,'',' AND ')+'EMPRESAID = '+EmpresaId;
  Result := 'WHERE '+Result+' AND STATUS <> ''C'' ';
end;

procedure TdmProdutoService.SetQueryPPreco(ProdutoId, EmpresaId: String);
var sWhere, sOrder: String;
begin
  try
    sWhere := GetWherePEmp(ProdutoId,EmpresaId);
    sOrder := ' ORDER BY EMPRESAID';
    precos.SQL.Text := SQL_PRD_PRECO+sWhere+sOrder;
    precos.Open;
  except on e: Exception do
    LogError(e,SQL_PRD_PRECO+sWhere+sOrder);
  end;
end;

procedure TdmProdutoService.SetQueryPIcms(ProdutoId, EmpresaId: String);
var sWhere, sOrder: String;
begin
  try
    sWhere := GetWherePEmp(ProdutoId,EmpresaId);
    sOrder := ' ORDER BY EMPRESAID';
    icms.SQL.Text := SQL_PRD_ICMS+sWhere+sOrder;
    icms.Open;
  except on e: Exception do
    LogError(e,SQL_PRD_ICMS+sWhere+sOrder);
  end;
end;

procedure TdmProdutoService.SetQueryPPisCofins(ProdutoId, EmpresaId: String);
var sWhere, sOrder: String;
begin
  try
    sWhere := GetWherePEmp(ProdutoId,EmpresaId);
    sOrder := ' ORDER BY EMPRESAID';
    piscofins.SQL.Text := SQL_PRD_PISCOFINS+sWhere+sOrder;
    piscofins.Open;
  except on e: Exception do
    LogError(e,SQL_PRD_PISCOFINS+sWhere+sOrder);
  end;
end;

procedure TdmProdutoService.LogError(error: Exception; datails: String);
var sl: TStringList;
begin
  try
    try
      sl := TStringList.Create;
      sl.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now)+' -> '+error.Message);
      sl.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now)+' -> '+datails);
      sl.Add('---');
      sl.SaveToFile('./logs/service.produto.'+GetTickCount.ToString+'.log');
    finally
      sl.Free;
    end;
  except
  end;
end;

constructor TdmProdutoService.Create(ConnectionId: String);
var
  sStrConn: String;
begin
  inherited Create(nil);

  FSQLTabela := 'PRODUTO ';
  FSQLSelect := 'SELECT * FROM PRODUTO ';
  DataSource.DataSet := nil;
  sStrConn := TConfiguration.ConnectionDatabase+ConnectionId;
  ZConnection.Connected := False;
  ZConnection.Protocol := TConfiguration.ConnectionProtocol;
  ZConnection.HostName := TConfiguration.ConnectionHostName;
  ZConnection.Port := TConfiguration.ConnectionPort;
  ZConnection.Database := sStrConn;
  ZConnection.User := TConfiguration.ConnectionUser;
  ZConnection.Password := TConfiguration.ConnectionPassword;
  ZConnection.LibraryLocation := TConfiguration.ConnectionLibraryLocation;
  ZConnection.Connected := True;
end;

procedure TdmProdutoService.SetTabela(Path: String);
begin
  if Path.Contains('/preco') then
  begin
    FSQLTabela := 'PRODUTOPRECO ';
    FSQLSelect := SQL_PRD_PRECO;
  end else if Path.Contains('/icms') then
  begin
    FSQLTabela := 'PRODUTOICMS ';
    FSQLSelect := SQL_PRD_ICMS;
  end else if Path.Contains('/piscofins') then
  begin
    FSQLTabela := 'PRODUTOPISCOFINS ';
    FSQLSelect := SQL_PRD_PISCOFINS;
  end else
  begin
    FSQLTabela := 'PRODUTO ';
    FSQLSelect := SQL_PRD;
  end;
end;

procedure TdmProdutoService.SetProduto(Id: String; EmpresaId: String);
begin
  if not Id.IsEmpty then
  begin
    DataSource.DataSet := Query;
    SetQueryPPreco(Id,EmpresaId);
    SetQueryPIcms(Id,EmpresaId);
    SetQueryPPisCofins(Id,EmpresaId);
  end;
end;

procedure TdmProdutoService.SetResumo;
begin
  FSQLSelect := 'SELECT CURRENT_CONNECTION, p.ID, p.DESCRICAO, pp.PRECO FROM PRODUTO p '+
                'LEFT JOIN PRODUTOPRECO pp ON pp.ID = p.ID AND pp.STATUS <> ''C'' ';
end;

function TdmProdutoService.listAll(AParams: TDictionary<String, String>): Boolean;
var sWhere, sKey, sAlias: String;
    aFiltroParcial: Array of String;
    pCond: TPair<String,String>;
    jRes: TJSONArray;
begin
  try
    sWhere := 'WHERE ';
    aFiltroParcial := ['codigo', 'descricao', 'referencia'];
    if FSQLSelect.Contains('FROM PRODUTO p') then
      sAlias := 'p.'
    else
      sAlias := '';
    for pCond in AParams do
    begin
      if MatchStr(pCond.Key,aFiltroParcial) then
      begin
        if pCond.Key = 'codigo' then
          sKey := 'id'
        else
          sKey := pCond.Key;
        sWhere := sWhere + 'UPPER(' + sAlias+sKey + ') CONTAINING ''' + pCond.Value.toUpper + ''' AND '
      end else
        sWhere := sWhere + sAlias+pCond.Key + ' = ''' + pCond.Value + ''' AND ';
    end;
    sWhere := sWhere + sAlias+IfThen(CanceledOnly,'STATUS = ''C'' ', 'STATUS <> ''C'' ');

    Query.SQL.Text := FSQLSelect+sWhere;
    Query.Open;

    ServiceResult.Status := THTTPStatus.OK;
    ServiceResult.MessageResponse := Query.ToJSONArrayString;
    Result := True;
  finally
  end;
end;

function TdmProdutoService.delete(id: String): Boolean;
begin
  Result := False;
end;

function TdmProdutoService.insert(AValue: String): Boolean;
begin
  Result := False;
end;

function TdmProdutoService.update(AValue: String): Boolean;
begin
  Result := False;
end;

end.

