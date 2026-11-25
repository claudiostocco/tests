unit service.estoque;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, Generics.Collections, StrUtils, DateUtils,
  (* Project units *)
  DataSet.Serialize, adapter.json, adapter.query.intf, connector.factory,
  service.ServiceProvider, service.commons;

type

  { TEstoqueService }

  TStockResult = record
    ProdutoId: String;
    Custo: Currency;
    Saldo: Double;
    Preco: Double;
  end;

  TEstoqueService = class(TServiceProvider)
    private
      FSQLSelect: String;
      FSQLWhere: String;
      function movimentoInit(empresaId, tipoMov: SmallInt): Integer;
      function checkStock(produtoId: String; empresaId: SmallInt): TStockResult;
    public
      constructor Create(ConnectionId: String);
      procedure SetByCompany;
      procedure SetFilter(value: String);
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function delete(id: String): Boolean; overload; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
  end;

implementation

{ TEstoqueService }

function TEstoqueService.movimentoInit(empresaId, tipoMov: SmallInt): Integer;
var Query: IQuery;
    sSQL, sInsert: String;
begin
  sSQL := 'SELECT m.ID '+
          'FROM MOVIMENTO m '+
          'WHERE m.EMPRESAID = '+empresaId.ToString+' '+
          'AND m.EMISSAO >= CURRENT_DATE '+
          'AND m.MOVTIPOID = '+tipoMov.ToString;  (* 4: Entrada 5: Saida *)
  Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
                        .Select(sSQL)
    	                .Open;
  if Query.AsDataSet.IsEmpty or (Query.AsDataSet.FieldByName('ID').AsInteger = 0) then
  begin
    sInsert := 'INSERT INTO MOVIMENTO (ID,EMPRESAID,TERMINALID,MOVTIPOID,MDFID,NUMERO,EMISSAO,STATUS) '+
               'VALUES (0,'+empresaId.ToString+',0,'+tipoMov.ToString+',''99'',0,CURRENT_TIMESTAMP,''F'')';
    with TQueryFactory.New(dmConn,dmConn.dbConnection)
                      .SetReturningFields(['ID'])
                      .Insert(sInsert)
                      .Open do
    begin
      Result := AsDataSet.FieldByName('ID').AsInteger;
      if Result = 0 then
        raise EHttpException.New.Status(THTTPStatus.InternalServerError).Error('Erro ao inserir registro de estoque!');
    end;
  end else
    Result := Query.AsDataSet.FieldByName('ID').AsInteger;
end;

function TEstoqueService.checkStock(produtoId: String; empresaId: SmallInt): TStockResult;
var Query: IQuery;
    sWhere: String;
begin
  try
    Result.ProdutoId := '-1';
    sWhere := '('''+produtoid+''','+empresaid.ToString+')';
    Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
                          .Select(FSQLSelect+sWhere)
                          .Open;
    if (not Query.AsDataSet.IsEmpty) and (Query.AsDataSet.FieldByName('PRODUTOID').Text <> '') then
    begin
      Result.ProdutoId := Query.AsDataSet.FieldByName('PRODUTOID').Text;
      Result.Custo := Query.AsDataSet.FieldByName('CUSTO').AsCurrency;
      Result.Saldo := Query.AsDataSet.FieldByName('SALDO').AsFloat;
      Result.Preco := Query.AsDataSet.FieldByName('PRECO').AsFloat;
    end;
  finally
    // Precisa liberar memoria
  end;
end;

constructor TEstoqueService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT PRODUTOID, DESCRICAO, CUSTO, PRECO, SALDO FROM ESTOQUE';
  FSQLWhere := '';
end;

procedure TEstoqueService.SetByCompany;
const sSQL_Company = '(SELECT NOMEEXIBICAO FROM EMPRESA WHERE ID = ESTOQUE.EMPRESAID) EMPRESANOME';
begin
  FSQLSelect := 'SELECT PRODUTOID, DESCRICAO, CUSTO, PRECO, EMPRESAID, '+sSQL_Company+', SALDO FROM ESTOQUEEMPRESA';
end;

procedure TEstoqueService.SetFilter(value: String);
var sFilter: String;
begin
  if value = 'ltz' then sFilter := '<'
  else if value = 'etz' then sFilter := '='
  else if value = 'gtz' then sFilter := '>';

  if not FSQLWhere.IsEmpty then
      FSQLWhere := FSQLWhere + ' AND ';
  FSQLWhere := FSQLWhere + 'SALDO '+sFilter+' 0';
end;

function TEstoqueService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere: String;
begin
  try
    sWhere := '(';
    if AParams.ContainsKey('produtoid') then
      sWhere := sWhere + ''''+AParams.Items['produtoid']+''''
    else
      sWhere := sWhere + 'null';
    sWhere := sWhere + ',';
    if AParams.ContainsKey('empresaid') then
      sWhere := sWhere + AParams.Items['empresaid']
    else
      sWhere := sWhere + 'null';
    if CanceledOnly then
      sWhere := sWhere + ',true';
    sWhere := sWhere + ')';
    if not FSQLWhere.IsEmpty then
      sWhere := sWhere + ' WHERE '+FSQLWhere;

    Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
             .Select(FSQLSelect+sWhere)
      	     .Open;
    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TEstoqueService.delete(id: String): Boolean;
begin
  Result := False;
  raise EHttpException.New.Status(THTTPStatus.MethodNotAllowed).Error('Not implemented');
end;

function TEstoqueService.insert(AValue: String): Boolean;
var jsonValues, jsonReturn: TJSONArray;
    jsonValue, jsonTmp: TJSONObject;
    sID, sInsert, sCusto, sQtd: String;
    iEp: SmallInt;
    i, iIDEnt, iIDSaida: Integer;
    srStock: TStockResult;
    dNewStock, dStockDiff: Double;
begin
  try
    Result := True;
    iIDEnt := 0;
    iIDSaida := 0;
    jsonReturn := TJSONArray.Create;
    try
      jsonValues := GetJSON(AValue) as TJSONArray;
      for i := 0 to jsonValues.Count - 1 do
      begin
        jsonValue := jsonValues.Items[i] as TJSONObject;
        sID := jsonValue.Get('produtoid','');
        if sID.IsEmpty then
          raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Identificador do produto não informado!');
        iEp := jsonValue.Get('empresaid',0);
        if iEp = 0 then
          raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Identificador da empresa não informado!');
        dNewStock := jsonValue.Get('saldo',0);

        (* Check stock balance *)
        srStock := checkStock(sID,iEp);
        if srStock.ProdutoId <> '-1' then
        begin
          dStockDiff := dNewStock - srStock.Saldo;
          if dStockDiff <> 0 then
          begin
            sInsert := 'INSERT INTO MOVITEM (ID,ITEM,PRODUTOID,CUSTO,QUANTIDADE,STATUS,CONTROLAESTOQUE) VALUES (';
            if dStockDiff > 0 then
            begin
              if iIDEnt = 0 then iIDEnt := movimentoInit(iEp,4);
              sInsert := sInsert+iIDEnt.ToString+',';
            end else if dStockDiff < 0 then
            begin
              if iIDSaida = 0 then iIDSaida := movimentoInit(iEp,5);
              sInsert := sInsert+iIDSaida.ToString+',';
              dStockDiff := dStockDiff * -1;
            end;
            sCusto := CurrToStr(srStock.Custo).Replace(',','.');
            sQtd := dStockDiff.ToString.Replace(',','.');
            sInsert := sInsert+'0,'''+sID+''','+sCusto+','+sQtd+',''F'',true)';
            TQueryFactory.New(dmConn,dmConn.dbConnection)
                         .Insert(sInsert)
                         .Exec;

            (* Check stock balance *)
            srStock := checkStock(sID,iEp);
          end;
        end else
          raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Produto não cadastrado: '+sID);

        jsonTmp := TJSONObject.Create;
        jsonTmp.Add('produtoid',srStock.ProdutoId);
        jsonTmp.Add('custo',srStock.Custo);
        jsonTmp.Add('empresaid',iEp);
        jsonTmp.Add('saldo',srStock.Saldo);
        jsonTmp.Add('preco',srStock.Preco);
        jsonReturn.Add(jsonTmp);
      end;
    finally
      jsonValues.Free;
      SetServiceResult('{"inserted": '+jsonReturn.Count.ToString+', "ReturnedDataSet": '+jsonReturn.AsJSON+'}',THTTPStatus.Created);
      jsonReturn.Free;
    end;
  except on E: Exception do
    raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Erro ao processar corpo da requisição: '+E.Message);
  end;
end;

function TEstoqueService.update(AValue: String): Boolean;
begin
  Result := False;
  raise EHttpException.New.Status(THTTPStatus.MethodNotAllowed).Error('Not implemented');
end;

end.
