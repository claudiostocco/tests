unit service.produto;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, Generics.Collections, StrUtils,
  {$ifndef FPC}
  Winapi.Windows,
  {$endif}
  (* Project units *)
  DataSet.Serialize,
  adapter.json, adapter.query.intf, service.commons,
  service.ServiceProvider, service.ServiceProviderCadastros, connector.factory
  , controller.session;

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
      function getNextAvailableCode: String;
    public
      constructor Create(Session: TSessionInstance);
      procedure SetTabela(Path: String);
      procedure SetProduto(Id: String; EmpresaId: String = '');
      procedure SetResumo(EmpresaId: String);
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function delete(id: String): Boolean; overload; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
  end;


implementation

const SQL_PRD_PRECO = 'SELECT pp.ID, pp.EMPRESAID, pp.CUSTO, pp.PRECO, pp.PRECOPROMOCAO, pp.PROMOCAODE, pp.PROMOCAOATE FROM PRODUTOPRECO pp ';
const SQL_PRD_ICMS = 'SELECT ID, EMPRESAID, ICMSID, (SELECT DESCRICAO FROM ICMS WHERE ID = PRODUTOICMS.ICMSID) AS ICMSDESCRICAO '+
                     'FROM PRODUTOICMS ';
const SQL_PRD_PISCOFINS = 'SELECT ID, EMPRESAID, CSTCOFINSID, CSTPISID, CSTCOFINSIDENT, CSTPISIDENT FROM PRODUTOPISCOFINS ';
const SQL_ESTOQUE = '(SELECT SALDO FROM ESTOQUE(p.ID,:empresaId)) AS ESTOQUE ';

const SQL_PRD = 'SELECT p.ID, p.DESCRICAO, p.COMPLEMENTO, p.REFERENCIA, p.FABRICANTEID, p.SETORID, p.UNIDADEID, p.PRODUTOORIGEMID, '+
                'p.PRODUTOTIPOID, p.COMBUSTIVEL, p.NCMID, p.CODIGONR, p.CONTROLAESTOQUE, p.ESTOQUEMINIMO, p.STATUS, p.DTCADASTRO, '+
                '(SELECT NOME FROM ENTIDADE WHERE ID = p.FABRICANTEID) AS FABRICANTE, '+
                '(SELECT DESCRICAO FROM SETOR WHERE ID = p.SETORID) AS SETORDESCRICAO, '+
                SQL_ESTOQUE+
                'FROM PRODUTO p ';

{ TProdutoService }

function TProdutoService.GetWherePEmp(ProdutoId, EmpresaId: String): String;
begin
  if not ProdutoId.IsEmpty then Result := 'ID = ''' + ProdutoId + ''' AND ';
  if not EmpresaId.IsEmpty then Result := 'EMPRESAID = '+EmpresaId+' AND ';
  Result := 'WHERE '+Result+'STATUS <> ''C'' ';
end;

procedure TProdutoService.SetQueryPPreco(ProdutoId, EmpresaId: String);
var sWhere, sOrder: String;
begin
  try
    sWhere := GetWherePEmp(ProdutoId,EmpresaId);
    sOrder := ' ORDER BY EMPRESAID';
    qPPreco := TQueryFactory.New(dmConn,dmConn.dbConnection)
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
    qPIcms := TQueryFactory.New(dmConn,dmConn.dbConnection)
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
    qPPisCofins := TQueryFactory.New(dmConn,dmConn.dbConnection)
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

function TProdutoService.getNextAvailableCode: String;
var query: IQuery;
begin
  query := TQueryFactory.New(dmConn,dmConn.dbConnection);
  repeat
    Result := query.GenerateID('PRODUTOID').ToString;
  until query.Select('SELECT ID FROM PRODUTO WHERE ID = '''+Result+'''').Open.IsEmpty;
end;

constructor TProdutoService.Create(Session: TSessionInstance);
begin
  inherited Create(Session);
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
    if EmpresaId.IsEmpty then
      EmpresaId := Session.EmpresaID;
    if EmpresaId.IsEmpty then
      FSQLSelect := FSQLSelect.Replace(':empresaId','null')
    else
      FSQLSelect := FSQLSelect.Replace(':empresaId',EmpresaId);
    SetQueryPPreco(Id,EmpresaId);
    SetQueryPIcms(Id,EmpresaId);
    SetQueryPPisCofins(Id,EmpresaId);
  end;
end;

procedure TProdutoService.SetResumo(EmpresaId: String);
begin
  FSQLSelect := 'SELECT p.ID, p.DESCRICAO FROM PRODUTO p ';
  if EmpresaId.IsEmpty then
    EmpresaId := Session.EmpresaID;
  SetQueryPPreco('',EmpresaId);
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
        sWhere := sWhere + 'UPPER(' + sAlias+sKey + ') LIKE ''%' + pCond.Value.toUpper + '%'' AND '
      end else
        sWhere := sWhere + sAlias+pCond.Key + ' = ''' + pCond.Value + ''' AND ';
    end;
    sWhere := sWhere + sAlias+IfThen(CanceledOnly,'STATUS = ''C'' ', 'STATUS <> ''C'' ');

    Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
             .Select(FSQLSelect+sWhere)
             .Open;

    if qPPreco <> nil then
      Query.SetChildQuery('ID','ID',qPPreco);
    if qPIcms <> nil then
      Query.SetChildQuery('','',qPIcms);
    if qPPisCofins <> nil then
      Query.SetChildQuery('','',qPPisCofins);

    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  except on e: Exception do
  begin
    LogError(e,'listAll');
    raise;
  end; end;
end;

function TProdutoService.delete(id: String): Boolean;
begin
  Result := inherited delete(id,'PRODUTO');
end;

function TProdutoService.insert(AValue: String): Boolean;
var jsonValue: TJSONObject;
    sID: String;
begin
  try
    try
      try
        jsonValue := GetJSON(AValue) as TJSONObject;
        sID := jsonValue.Strings['id'];
        if sID.IsEmpty then
        begin
          sID := getNextAvailableCode;
          jsonValue.Strings['id'] := sID;
          if jsonValue.Find('produtoicms') <> nil then
            (jsonValue.Find('produtoicms').Items[0] as TJSONObject).Strings['id'] := sID;
          if jsonValue.Find('produtopiscofins') <> nil then
            (jsonValue.Find('produtopiscofins').Items[0] as TJSONObject).Strings['id'] := sID;
          if jsonValue.Find('produtopreco') <> nil then
            (jsonValue.Find('produtopreco').Items[0] as TJSONObject).Strings['id'] := sID;
          if jsonValue.Find('produtosw') <> nil then
            (jsonValue.Find('produtosw').Items[0] as TJSONObject).Strings['id'] := sID;
          AValue := jsonValue.AsJSON;
        end;
      finally
        jsonValue.Free;
      end;
    except on E: Exception do
      raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Erro ao processar corpo da requisição: '+E.Message);
    end;
    Result := inherited insert(AValue, FSQLTabela);
  except on e: Exception do
  begin
    if e is EHttpException then
    begin
      if (e as EHttpException).Code = Integer(IdNotDefined) then
        writeln('');
    end;
    LogError(e,'insert');
    if e.Message.Contains('"PRODUTOUK"') then
      TServiceResponse.Error(THTTPStatus.BadRequest, TServiceResponseStatus.ProductUniqueKeyError)
    else
      raise;
  end; end;
end;

function TProdutoService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, FSQLTabela);
end;

end.
