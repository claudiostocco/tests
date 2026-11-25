unit controller.session;

{$ifdef FPC}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  Classes, SysUtils, Horse, CredentialClaims, JWT, CipherData, Horse.Session;

type

  { TSessionManager }

  TSessionManager = class(TSession)
  private
    FEmpresaID: String;
  public
    class function New: TSessionManager;
    function EmpresaID(Value: String): TSessionManager; overload;
    function EmpresaID: String; overload;
  end;

{ TSessionInstance }

  TSessionInstance = record
  private
    FReq: THorseRequest;
  public
    function ConnectionID: String;
    function ID: String;
    function CNPJ: String;
    function User: String;
    function EmpresaID: String;
  end;

function ProcessSession(Req: THorseRequest): TSessionInstance;

implementation

function ProcessSession(Req: THorseRequest): TSessionInstance;
begin
  if Req.Session<TCredentialClaims> <> nil then
  begin
    Result.FReq := Req;
  end;
end;

{ TSessionManager }

class function TSessionManager.New: TSessionManager;
begin
  Result := TSessionManager.Create;
end;

function TSessionManager.EmpresaID(Value: String): TSessionManager;
begin
  FEmpresaID := Value;
  Result := Self;
end;

function TSessionManager.EmpresaID: String;
begin
  Result := FEmpresaID;
end;

{ TSessionInstance }

function TSessionInstance.ConnectionID: String;
begin
  Result := TCipherData.Decrypt(FReq.Session<TCredentialClaims>.ConnectionID,DATA_SK);
end;

function TSessionInstance.ID: String;
begin
  Result := FReq.Session<TCredentialClaims>.ID;
end;

function TSessionInstance.CNPJ: String;
begin
  Result := TCipherData.Decrypt(FReq.Session<TCredentialClaims>.CNPJ,DATA_SK);
end;

function TSessionInstance.User: String;
begin
  Result := TCipherData.Decrypt(FReq.Session<TCredentialClaims>.User,DATA_SK);
end;

function TSessionInstance.EmpresaID: String;
begin
  Result := TSessionManager(FReq.Sessions.Session[TSessionManager]).EmpresaID;
end;

end.

