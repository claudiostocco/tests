unit service.auth;

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
  , DB, Generics.Collections,
  (* Project units *)
  connector.configuration, JWT, CipherData,
  adapter.query.intf, connector.factory,
  service.ServiceProvider, service.commons;

  type

    { TAuthService }

    TAuthService = class(TServiceProvider)
    private
      FConnId: String;
    public
      constructor Create;
      function Authorize(ClientId, ClientSecret, User: String): boolean;
      function TesteConexao: Boolean; override;
      class function Decrypt(Data: String): String;
      property ConnId: String read FConnId;
    end;

implementation

{ TAuthService }

constructor TAuthService.Create;
begin
  inherited Create(TConfiguration.CredentialDataBase);
end;

function TAuthService.Authorize(ClientId, ClientSecret, User: String): boolean;
var Query: IQuery;
begin
  try
    Query := TQueryFactory
               .New(dmConn,dmConn.dbConnection)
               .Select('SELECT ID, SECRETKEY, CONNECTIONID FROM EMPRESACREDENCIAL WHERE ID = :ID')
               .SetParamByName('ID',ClientId)
               .Open;
    with Query.AsDataSet do
    begin
      FConnId := FieldByName('CONNECTIONID').Text;
      if (not FieldByName('ID').Text.IsEmpty) and (not FConnId.IsEmpty) then
      begin
        if ClientSecret.Equals(FieldByName('SECRETKEY').Text) then
          (* Sending the token *)
          SetServiceResult('{"access_token": "'+createToken(FieldByName('ID').Text,ClientId, User, FConnId)+'"}',THTTPStatus.OK)
        else
          SetServiceResult('{"erro": "Client_Secret inválido!"}',THTTPStatus.Unauthorized);
      end else
        SetServiceResult('{"erro": "Empresa não cadastrada!"}',THTTPStatus.Unauthorized);
      Result := True;
    end;
  finally
    DestroyConnection;
  end;
end;

function TAuthService.TesteConexao: Boolean;
begin
  try
    Result := inherited TesteConexao;
  finally
    DestroyConnection;
  end;
end;

class function TAuthService.Decrypt(Data: String): String;
begin
  Result := TCipherData.Decrypt(Data,DATA_SK);
end;

end.

