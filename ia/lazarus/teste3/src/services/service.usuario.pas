unit service.usuario;

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
  service.ServiceProvider, service.ServiceProviderCadastros, service.commons;

type

  { TUsuarioService }

  TUsuarioService = class(TServiceProviderCadastros)
    private
    public
      constructor Create(ConnectionId: String);
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function delete(id: String): Boolean; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
      function login(AValue: String): Boolean;
  end;

implementation

{ TUsuarioService }

constructor TUsuarioService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
end;

function TUsuarioService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere: String;
    pCond: TPair<String,String>;
begin
  try
    sWhere := '';
    for pCond in AParams do
       sWhere := sWhere + IfThen(sWhere.IsEmpty,'',' AND ') + pCond.Key + ' = ''' + pCond.Value + '''';
    if sWhere.IsEmpty then
      sWhere := 'WHERE STATUS = ''A'''
    else
      sWhere := 'WHERE '+sWhere+' AND STATUS = ''A''';

    Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
             .Select('SELECT * FROM USUARIO '+sWhere)
      	     .Open;
    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TUsuarioService.delete(id: String): Boolean;
begin
  Result := inherited delete(id, 'USUARIO');
end;

function TUsuarioService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue, 'USUARIO');
end;

function TUsuarioService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, 'USUARIO');
end;

function TUsuarioService.login(AValue: String): Boolean;
var jV: TJSONObject;
    Query: IQuery;
    sUser, sPass: String;
begin
  Result := True;
  try
    jv := GetJSON(AValue) as TJSONObject;
    if (jV.Find('usuario') <> nil) and (jV.Find('senha') <> nil) then
    begin
      sUser := jV.Get('usuario');
      sPass := jV.Get('senha');
      Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
                            .Open('SELECT * FROM USUARIO WHERE ID = '''+sUser+'''');
      with Query.AsDataSet do
      begin
        if FieldByName('senha').Text = sPass then
          SetServiceResult(ToJSONObjectString,THTTPStatus.Accepted)
        else
          SetServiceResult('{"error": "Usuário ou senha inválidos!"}',THTTPStatus.Unauthorized);
      end;
    end else
      SetServiceResult('{"error": "É necessário informar usuário e senha!"}',THTTPStatus.BadRequest);
  finally
    FreeAndNil(jV);
  end;
end;

end.

