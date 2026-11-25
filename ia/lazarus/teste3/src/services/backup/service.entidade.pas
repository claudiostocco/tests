unit service.entidade;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, DB, Generics.Collections, StrUtils,
  (* Project units *)
  DataSet.Serialize,
  service.ServiceProvider, service.ServiceProvidercadastros, service.commons,
  adapter.query.intf, connector.factory, adapter.json;

type

  { TEntidadeService }

  TEntidadeService = class(TServiceProviderCadastros)
    private
      FSQLSelect: String;
      FSQLWhere: String;
      FSQLTabela: String;
      //FIncluiCancelado: Boolean;
      qEmail, qFone, qEnd: IQuery;
      function GetFiltroCancelado: String;
      //procedure SetIncluiCancelado(AValue: Boolean);
    public
      constructor Create(ConnectionId: String);
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function insert(AValue: String): Boolean; override;
      function delete(id: String): Boolean; override;
      function update(AValue: String): Boolean; override;
      procedure SetFiltroEntidade(ST: String);
      procedure SetEntidade(id: String);
      procedure SetEmail(entidadeId: String);
      procedure SetFone(entidadeId: String);
      procedure SetEndereco(entidadeId: String);
      //property IncluiCancelado: Boolean read FIncluiCancelado write SetIncluiCancelado;
  end;

implementation

const SELECT_ENDERECO = 'SELECT ENTIDADEID,ID,ENDERECO,BAIRRO,MUNICIPIOID,CEP,COMPLEMENTO,PAISID,STC,STF,'+
                        '(SELECT CIDADE FROM MUNICIPIO WHERE ID = ENTIDADEENDERECO.MUNICIPIOID) AS CIDADE,'+
                        '(SELECT UF FROM ESTADO WHERE ID = SUBSTRING(ENTIDADEENDERECO.MUNICIPIOID FROM 1 FOR 2)) AS UF '+
                        'FROM ENTIDADEENDERECO ';

{ TEntidadeService }

//procedure TEntidadeService.SetIncluiCancelado(AValue: Boolean);
//begin
//  if FIncluiCancelado = AValue then Exit;
//  FIncluiCancelado := AValue;
//end;

constructor TEntidadeService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := '';
  FSQLWhere := '';
end;

function TEntidadeService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere, sKey: String;
    pCond: TPair<String,String>;
    aFiltroParcial: Array of String;
begin
  try
    sWhere := '';
    aFiltroParcial := ['cnpj', 'nome'];
    for pCond in AParams do
    begin
      if MatchStr(pCond.Key,aFiltroParcial) then
      begin
        if pCond.Key = 'cnpj' then
          sKey := 'id'
        else
          sKey := pCond.Key;
        sWhere := sWhere + IfThen(sWhere.IsEmpty,'',' AND ') + 'UPPER(' + sKey + ') CONTAINING ''' + pCond.Value.toUpper + ''''
      end else
        sWhere := sWhere + IfThen(sWhere.IsEmpty,'',' AND ') + pCond.Key + ' = ''' + pCond.Value + '''';
    end;

    if not FSQLWhere.IsEmpty then
    begin
      if sWhere.IsEmpty then
        sWhere := FSQLWhere
      else
        sWhere := sWhere+' AND '+FSQLWhere;
    end;
    if not sWhere.IsEmpty then
      sWhere := 'WHERE '+sWhere;

    Query := TQueryFactory.New
                          .Select(FSQLSelect+sWhere);
    if (qEmail <> nil) and (qEnd <> nil) and (qFone <> nil) then
    begin
      Query.SetChildQuery('','',qEmail)
           .SetChildQuery('','',qFone)
           .SetChildQuery('','',qEnd);
    end;
    Query.Open;

    SetServiceResult(Query.AsDataSet.ToJSONArrayString,THTTPStatus.ok);
    Result := True;
  finally
  end;
end;

function TEntidadeService.insert(AValue: String): Boolean;
var jsonValue: TJSONObject;
    qCad: IQuery;
    sID, sEntID: String;
    iNovoId: Integer;
begin
  if FSQLTabela.Equals('ENTIDADEENDERECO') then
  begin
    jsonValue := GetJSON(AValue) as TJSONObject;
    try
      sID := jsonValue.Get('id');
      if sID.Equals('0') and (jsonValue.Find('entidadeid') <> nil) and (jsonValue.Get('entidadeid') <> '') then
      begin
        sEntID := 'ENTIDADEID = '''+jsonValue.Get('entidadeid')+'''';
        qCad := TQueryFactory.New
                             .Select('SELECT MAX(ID) AS ID FROM '+FSQLTabela+' WHERE '+sEntID)
                             .Open;
        iNovoId := StrToIntDef(qCad.AsDataSet.FieldByName('ID').Text,0)+1;
        jsonValue.Integers['id'] := iNovoId;
        sID := jsonValue.Integers['id'].ToString;
      end;
      AValue := jsonValue.AsJSON;
    finally
      jsonValue.Free;
    end;
  end;
  Result := inherited insert(AValue,FSQLTabela);
  if FSQLTabela.Equals('ENTIDADEENDERECO') then
  begin
    try
      jsonValue := GetJSON(ServiceResult.MessageResponse) as TJSONObject;
      qCad := TQueryFactory.New
                           .Select(SELECT_ENDERECO+' WHERE ID = '''+sID+''' AND '+sEntID)
                           .Open;
      jsonValue.Elements['ReturnedDataSet'] := qCad.AsDataSet.ToJSONArray();
      SetServiceResult(jsonValue.AsJSON,ServiceResult.Status);
    finally
      jsonValue.Free;
    end;
  end;
end;

function TEntidadeService.delete(id: String): Boolean;
begin
  Result := inherited delete(id,FSQLTabela);
end;

//function TEntidadeService.delete(id: String): Boolean;
//var iExc: Integer;
//begin
//  Result := True;
//  iExc := TQueryFactory.New
//                       .Exec('UPDATE '+FSQLTabela+' SET '+StatusFieldName+' = ''C'' WHERE ID = '''+id+'''')
//                       .RowsAffected;
//  if iExc > 0 then
//    SetServiceResult('{}',THTTPStatus.ok)
//  else
//    SetServiceResult('{"error": "Registro não foi cancelado!"}',THTTPStatus.NotModified);
//end;

function TEntidadeService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, FSQLTabela);
end;

function TEntidadeService.GetFiltroCancelado: String;
begin
  //Result := StatusFieldName + ' ' + IfThen(FIncluiCancelado, '<> ''N''', '= ''S''');
  Result := StatusFieldName + ' ' + IfThen(CanceledOnly, '= ''C''', '= ''S''');
end;

procedure TEntidadeService.SetFiltroEntidade(ST: String);
begin
  if ST.Contains('/fornecedor') then
    StatusFieldName := 'STF'
  else
    StatusFieldName := 'STC';

  if ST.Contains('/email') then
    FSQLTabela := 'ENTIDADEEMAIL'
  else if ST.Contains('/endereco') then
    FSQLTabela := 'ENTIDADEENDERECO'
  else if ST.Contains('/fone') then
    FSQLTabela := 'ENTIDADEFONE'
  else
    FSQLTabela := 'ENTIDADE';
end;

procedure TEntidadeService.SetEntidade(id: String);
var
  sCidade, sCfop, sTabela: String;
begin
  if not id.IsEmpty then
  begin
    SetEmail(id);
    qEmail := TQueryFactory.New
                           .Select(FSQLSelect+FSQLWhere)
                           .SetQueryName('emails')
                           .Open;

    SetFone(id);
    qFone := TQueryFactory.New
                          .Select(FSQLSelect+FSQLWhere)
                          .SetQueryName('fones')
                          .Open;

    SetEndereco(id);
    qEnd := TQueryFactory.New
                         .Select(FSQLSelect+FSQLWhere)
                         .SetQueryName('enderecos')
                         .Open;
  end;
  sCidade := '(SELECT FIRST 1 m.CIDADE FROM ENTIDADEENDERECO ee INNER JOIN MUNICIPIO m ON m.ID = ee.MUNICIPIOID '+
             'WHERE ee.ENTIDADEID = ENTIDADE.ID) AS CIDADE';
  if StatusFieldName <> 'STF' then
  begin
    sCfop := ', (SELECT FIRST 1 cfo.DESCRICAO FROM CFOP cfo WHERE cfo.ID = ENTIDADE.CFOPID) AS CFOPDESCRICAO';
    sTabela := ', (SELECT FIRST 1 t.DESCRICAO FROM TABELA t WHERE t.ID = ENTIDADE.TABELAID) AS TABELADESCRICAO';
  end else
  begin
    sCfop := '';
    sTabela := '';
  end;

  FSQLSelect := 'SELECT ID, EMPRESAID, TABELAID, CFOPID, NOME, IE, RG, TXDESCONTO, ISENTOICMS, BLOQUEADO, DESDE, '+
                'ATUALIZADO, REFERENCIA, OBSERVACAO, STC, STF, '+sCidade+sCfop+sTabela+
                ' FROM ENTIDADE ';

  FSQLWhere := GetFiltroCancelado;
end;

procedure TEntidadeService.SetEmail(entidadeId: String);
begin
  FSQLSelect := 'SELECT * FROM ENTIDADEEMAIL ';
  if not entidadeId.IsEmpty then
    FSQLWhere := 'WHERE ENTIDADEID = '''+entidadeId+''' AND '+GetFiltroCancelado
  else
    FSQLWhere := '';
end;

procedure TEntidadeService.SetFone(entidadeId: String);
begin
  FSQLSelect := 'SELECT * FROM ENTIDADEFONE ';
  if not entidadeId.IsEmpty then
    FSQLWhere := 'WHERE ENTIDADEID = '''+entidadeId+''' AND '+GetFiltroCancelado
  else
    FSQLWhere := '';
end;

procedure TEntidadeService.SetEndereco(entidadeId: String);
begin
  FSQLSelect := SELECT_ENDERECO;
  if not entidadeId.IsEmpty then
    FSQLWhere := 'WHERE ENTIDADEID = '''+entidadeId+''' AND '+GetFiltroCancelado
  else
    FSQLWhere := '';
end;

end.
