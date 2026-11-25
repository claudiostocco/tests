unit service.ServiceProvider;

{$ifdef FPC}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  {$ifdef FPC}
  Classes, SysUtils
  {$else}
  System.Classes, System.SysUtils
  {$endif}
  , Generics.Collections
  , DataSet.Serialize
  , adapter.json
  , connection, adapter.query.intf, connector.factory
  , service.commons
  , controller.session;

type
  TServiceProviderResult = record
     Status: THTTPStatus;
     MessageResponse: String;
  end;

  { TServiceProvider }

  TServiceProvider = class
  strict private
    FdmConn: TdmConn;
  private
    FCanceledOnly: Boolean;
    FReturningFields: String;
    FServiceResult: TServiceProviderResult;
    FStatusFieldName: String;
    FUser: String;
    FSession: TSessionInstance;
    function NewConnection(ConnectionId: String): TComponent;
    procedure SetReturningFields(AValue: String);
    procedure SetUser(AValue: String);
    procedure SetRecordToResponse;
  public
    destructor Destroy; override;
    constructor Create(ConnectionId: String); overload;
    constructor Create(Session: TSessionInstance); overload;
    procedure DestroyConnection;
    function DadosConexao: String;
    function TesteConexao: Boolean; virtual;
    function delete(id: String): Boolean; overload; virtual; abstract;
    function delete(AFilters: TDictionary<String, String>): Boolean; overload; virtual; abstract;
    function delete(ATableName: String; AFilters: TDictionary<String, String>): Boolean; overload; virtual;
    function delete(id, ATableName: String; AExtraCondition: String = ''): Boolean; overload; virtual;
    function insert(AValue: String): Boolean; overload; virtual;
    function insert(AValue: String; ATableName: String): Boolean; overload; virtual;
    //function insert(AValue, AUser: String; ATableName: String): Boolean; overload; virtual; abstract;
    function listAll(AParams: TDictionary<String, String>): Boolean; overload; virtual;
    function listAll(Sql: String; AParams: TDictionary<String, String>; Childs: TList<IChildQuery> = nil): Boolean; overload; virtual;
    function update(AValue: String): Boolean; overload; virtual;
    function update(AValue: String; ATableName: String): Boolean; overload; virtual;
    //function update(AValue, AUser, ATableName: String): Boolean; overload; virtual; abstract;
    procedure SetServiceResult(MessageResponseValue: String; StatusValue: THTTPStatus = THTTPStatus.OK);
    property ServiceResult: TServiceProviderResult read FServiceResult;
    property CanceledOnly: Boolean read  FCanceledOnly write FCanceledOnly;
    property ReturningFields: String read FReturningFields write SetReturningFields;
    property StatusFieldName: String read FStatusFieldName write FStatusFieldName;
    property User: String read FUser write SetUser;
    property Session: TSessionInstance read FSession;
    property dmConn: TdmConn read FdmConn;
  end;

implementation

{ TServiceProvider }

destructor TServiceProvider.Destroy;
begin
  DestroyConnection;
end;

constructor TServiceProvider.Create(ConnectionId: String);
begin
  FCanceledOnly := False;
  FReturningFields := '';
  FStatusFieldName := 'STATUS';
  NewConnection(ConnectionId);
end;

constructor TServiceProvider.Create(Session: TSessionInstance);
begin
  FSession := Session;
  Create(FSession.ConnectionID);
  SetUser(FSession.User);
end;

function TServiceProvider.NewConnection(ConnectionId: String): TComponent;
begin
  (* Será necessário implementar um pool de conexões com um map de TdmConn *)
  FdmConn := TdmConn.CreateConnection(ConnectionId);
  Result := FdmConn;
end;

procedure TServiceProvider.SetReturningFields(AValue: String);
begin
  if FReturningFields = AValue then Exit;
  FReturningFields := AValue;
end;

procedure TServiceProvider.SetUser(AValue: String);
var sSql: String;
begin
  if FUser = AValue then Exit;
  FUser := AValue;
  sSql := 'SELECT RDB$SET_CONTEXT(''USER_SESSION'',''APP_LOGGED_USER'', :User) FROM RDB$DATABASE';
  TQueryFactory.New(dmConn,dmConn.dbConnection)
               .Select(sSql)
               .SetParamByName('User',FUser)
               .Open;
end;

procedure TServiceProvider.SetRecordToResponse;
var jsonValue: TJSONObject;
    qCad: IQuery;
begin
  try
    jsonValue := GetJSON(ServiceResult.MessageResponse) as TJSONObject;
    //qCad := TQueryFactory.New(dmConn,dmConn.dbConnection)
    //                     .Select(SELECT_ENDERECO+' WHERE ID = '''+sID+''' AND '+sEntID)
    //                     .Open;
    jsonValue.Add('record',qCad.AsDataSet.ToJSONObjectString);
    SetServiceResult(jsonValue.AsJSON,ServiceResult.Status);
  finally
    jsonValue.Free;
  end;
end;

procedure TServiceProvider.DestroyConnection;
begin
  if Assigned(FdmConn) then FreeAndNil(FdmConn);
end;

function TServiceProvider.DadosConexao: String;
var sSql: String;
begin
  sSql := 'SELECT MON$ATTACHMENT_ID'+
          '     , MON$ATTACHMENT_NAME'+
          '     , MON$REMOTE_ADDRESS'+
          '     , CAST(MON$TIMESTAMP AS TIMESTAMP) AS MON$TIMESTAMP'+
          '     , MON$REMOTE_PROCESS'+
          '     , MON$REMOTE_HOST'+
          '     , MON$CLIENT_VERSION '+
          'FROM MON$ATTACHMENTS '+
          'WHERE MON$ATTACHMENT_ID = CURRENT_CONNECTION';
  Result := TQueryFactory.New(dmConn,dmConn.dbConnection)
                         .Open(sSql)
                         .AsDataSet
                         .ToJSONArrayString();
end;

function TServiceProvider.TesteConexao: Boolean;
begin
  SetServiceResult(DadosConexao(),THTTPStatus.OK);
  Result := True;
end;

function TServiceProvider.delete(ATableName: String; AFilters: TDictionary<String, String>): Boolean;
var iExc: Integer;
    pFilterPair: TPair<String, String>;
    sWhere: String;
    Query: IQuery;
begin
  Result := True;
  sWhere := '';
  Query := TQueryFactory.New(dmConn,dmConn.dbConnection);

  for pFilterPair in AFilters do
  begin
    if not sWhere.IsEmpty then sWhere := sWhere + ' AND ';
    sWhere := sWhere + pFilterPair.Key + ' = :' + pFilterPair.Key;
    Query.SetParamByName(pFilterPair.Key, pFilterPair.Value);
  end;
  
  iExc := Query.Exec('UPDATE '+ATableName+' SET '+StatusFieldName+' = ''C'' WHERE '+sWhere)
               .RowsAffected;
               
  if iExc > 0 then
    SetServiceResult('{}',THTTPStatus.ok)
  else
    SetServiceResult('{"error": "Registro não ENCONTRADO!"}',THTTPStatus.NotModified);
end;

function TServiceProvider.delete(id, ATableName: String; AExtraCondition: String = ''): Boolean;
var iExc: Integer;
begin
  Result := True;
  iExc := TQueryFactory.New(dmConn,dmConn.dbConnection)
                       .Select('UPDATE '+ATableName+' SET '+StatusFieldName+' = ''C'' WHERE ID = :ID '+AExtraCondition)
                       .SetParamByName('ID',id)
                       .Exec
                       .RowsAffected;
  if iExc > 0 then
    SetServiceResult('{}',THTTPStatus.ok)
  else
    SetServiceResult('{"error": "Registro não ENCONTRADO!"}',THTTPStatus.NotModified);
end;

function TServiceProvider.insert(AValue: String; ATableName: String): Boolean;
var sDataSet: String;
begin
  Result := True;
  with TQueryFactory.New(dmConn,dmConn.dbConnection)
                    .SetReturningFields(FReturningFields.Split([',']))
                    .InsertJSON(AValue,ATableName) do
  begin
    if AsDataSet.IsEmpty then
      sDataSet := ''
    else
      sDataSet := ', "ReturnedDataSet": '+AsDataSet.ToJSONArray().AsJSON;

    SetServiceResult('{"inserted": '+InsertedRecords.ToString+sDataSet+'}',THTTPStatus.Created);
  end;
end;

function TServiceProvider.insert(AValue: String): Boolean;
begin
  Result := False;
  raise EHttpException.New.Status(THTTPStatus.MethodNotAllowed).Error('Not implemented');
end;

function TServiceProvider.listAll(AParams: TDictionary<String, String>): Boolean;
begin
  Result := False;
  if FServiceResult.MessageResponse.IsEmpty then
     raise EHttpException.New.Status(THTTPStatus.MethodNotAllowed).Error('Not implemented')
  else
     Result := True;
end;

function TServiceProvider.listAll(Sql: String; AParams: TDictionary<String, String>; Childs: TList<IChildQuery>): Boolean;
var Query: IQuery;
    Child: IChildQuery;
begin
  Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
           .Select(Sql)
           .SetParamsOfDict(AParams)
      	   .Open;

  if Childs <> nil then
  begin
    for Child in Childs do
      Query.SetChildQuery(Child.MasterField,Child.LinkedField,Child.Query);
  end;

  SetServiceResult(Query.AsDataSet.ToJSONArrayString);
  Result := True;
end;

function TServiceProvider.update(AValue: String): Boolean;
begin
  Result := False;
  raise EHttpException.New.Status(THTTPStatus.MethodNotAllowed).Error('Not implemented');
end;

function TServiceProvider.update(AValue: String; ATableName: String): Boolean;
var sDataSet: String;
begin
  Result := True;
  ReturningFields := '*';
  with TQueryFactory.New(dmConn,dmConn.dbConnection)
                    .SetReturningFields(FReturningFields.Split([',']))
                    .InsertJSON(AValue,ATableName,True) do
    begin
      if AsDataSet.IsEmpty then
        sDataSet := ''
      else
        sDataSet := ', "ReturnedDataSet": '+AsDataSet.ToJSONArray().AsJSON;

      SetServiceResult('{"updated": '+InsertedRecords.ToString+sDataSet+'}',THTTPStatus.OK);
    end;
end;

procedure TServiceProvider.SetServiceResult(MessageResponseValue: String; StatusValue: THTTPStatus);
begin
  FServiceResult.Status := StatusValue;
  FServiceResult.MessageResponse := MessageResponseValue;
end;

end.

