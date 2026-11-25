unit service.produto;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, Generics.Collections, StrUtils,
  (* Project units *)
  DataSet.Serialize,
  adapter.json, adapter.query.intf,
  service.ServiceProvider, service.ServiceProviderCadastros, connector.factory;

type

  { TProdutoService }

  TProdutoService = class(TServiceProviderCadastros)
    private
      FSQLSelect, FSQLTabela: String;
      qPPreco: IQuery;
      qPIcms: IQuery;
      qPPisCofins: IQuery;
      function GetWherePEmp(ProdutoId, EmpresaId: String): String;
      procedure SetQueryPPreco(ProdutoId, EmpresaId: String);
      procedure SetQueryPIcms(ProdutoId, EmpresaId: String);
      procedure SetQueryPPisCofins(ProdutoId, EmpresaId: String);
      procedure LogError(error: Exception; datails: String);
    public
      constructor Create(ConnectionId: String);
      procedure SetTabela(Path: String);
      procedure SetProduto(Id: String; EmpresaId: String = '');
      procedure SetResumo;
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function delete(id: String): Boolean; overload; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
  end;


implementation

const SQL_PRD_PRECO = 'SELECT CURRENT_CONNECTION, ID, EMPRESAID, CUSTO, PRECO, PRECOPROMOCAO, PROMOCAODE, PROMOCAOATE FROM PRODUTOPRECO ';
const SQL_PRD_ICMS = 'SELECT CURRENT_CONNECTION, ID, EMPRESAID, ICMSID, (SELECT DESCRICAO FROM ICMS WHERE ID = PRODUTOICMS.ICMSID) AS ICMSDESCRICAO '+
                     'FROM PRODUTOICMS ';
const SQL_PRD_PISCOFINS = 'SELECT CURRENT_CONNECTION, ID, EMPRESAID, CSTCOFINSID, CSTPISID, CSTCOFINSIDENT, CSTPISIDENT FROM PRODUTOPISCOFINS ';

const SQL_PRD = 'SELECT CURRENT_CONNECTION, ID, DESCRICAO, COMPLEMENTO, REFERENCIA, FABRICANTEID, SETORID, UNIDADEID, PRODUTOORIGEMID, '+
                'PRODUTOTIPOID, COMBUSTIVEL, NCMID, CODIGONR, CONTROLAESTOQUE, ESTOQUEMINIMO, STATUS, DTCADASTRO, '+
                '(SELECT NOME FROM ENTIDADE WHERE ID = PRODUTO.FABRICANTEID) AS FABRICANTE, '+
                '(SELECT DESCRICAO FROM SETOR WHERE ID = PRODUTO.SETORID) AS SETORDESCRICAO '+
                'FROM PRODUTO ';

{ TProdutoService }

function TProdutoService.GetWherePEmp(ProdutoId, EmpresaId: String): String;
begin
  if not ProdutoId.IsEmpty then Result := 'ID = ''' + ProdutoId + '''';
  if not EmpresaId.IsEmpty then Result := IfThen(Result.IsEmpty,'',' AND ')+'EMPRESAID = '+EmpresaId;
  Result := 'WHERE '+Result+' AND STATUS <> ''C'' ';
end;

procedure TProdutoService.SetQueryPPreco(ProdutoId, EmpresaId: String);
var sWhere, sOrder: String;
begin
  try
    sWhere := GetWherePEmp(ProdutoId,EmpresaId);
    sOrder := ' ORDER BY EMPRESAID';
    qPPreco := TQueryFactory.New
                          .Select(SQL_PRD_PRECO+sWhere+sOrder)
                          .SetQueryName('precos')
                          .Open;
  except on e: Exception do
    LogError(e,SQL_PRD_PRECO+sWhere+sOrder);
  end;
end;

procedure TProdutoService.SetQueryPIcms(ProdutoId, EmpresaId: String);
var sWhere, sOrder: String;
begin
  try
    sWhere := GetWherePEmp(ProdutoId,EmpresaId);
    sOrder := ' ORDER BY EMPRESAID';
    qPIcms := TQueryFactory.New
                          .Select(SQL_PRD_ICMS+sWhere+sOrder)
                          .SetQueryName('icms')
                          .Open;
  except on e: Exception do
    LogError(e,SQL_PRD_ICMS+sWhere+sOrder);
  end;
end;

procedure TProdutoService.SetQueryPPisCofins(ProdutoId, EmpresaId: String);
var sWhere, sOrder: String;
begin
  try
    sWhere := GetWherePEmp(ProdutoId,EmpresaId);
    sOrder := ' ORDER BY EMPRESAID';
    qPPisCofins := TQueryFactory.New
                          .Select(SQL_PRD_PISCOFINS+sWhere+sOrder)
                          .SetQueryName('piscofins')
                          .Open;
  except on e: Exception do
    LogError(e,SQL_PRD_PISCOFINS+sWhere+sOrder);
  end;
end;

procedure TProdutoService.LogError(error: Exception; datails: String);
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

constructor TProdutoService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLTabela := 'PRODUTO ';
  FSQLSelect := 'SELECT * FROM PRODUTO ';
end;

procedure TProdutoService.SetTabela(Path: String);
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

procedure TProdutoService.SetProduto(Id: String; EmpresaId: String = '');
begin
  if not Id.IsEmpty then
  begin
    SetQueryPPreco(Id,EmpresaId);
    SetQueryPIcms(Id,EmpresaId);
    SetQueryPPisCofins(Id,EmpresaId);
  end;
end;

procedure TProdutoService.SetResumo;
begin
  FSQLSelect := 'SELECT CURRENT_CONNECTION, p.ID, p.DESCRICAO, pp.PRECO FROM PRODUTO p '+
                'LEFT JOIN PRODUTOPRECO pp ON pp.ID = p.ID AND pp.STATUS <> ''C'' ';
end;

function TProdutoService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere, sKey, sAlias: String;
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

    Query := TQueryFactory.New
             .Select(FSQLSelect+sWhere)
             .Open;

    if qPPreco <> nil then
      Query.SetChildQuery('','',qPPreco.Open);
    if qPIcms <> nil then
      Query.SetChildQuery('','',qPIcms.Open);
    if qPPisCofins <> nil then
      Query.SetChildQuery('','',qPPisCofins.Open);

    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TProdutoService.delete(id: String): Boolean;
begin
  Result := inherited delete(id,'PRODUTO');
end;

function TProdutoService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue, FSQLTabela);
end;

function TProdutoService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, FSQLTabela);
end;

end.
