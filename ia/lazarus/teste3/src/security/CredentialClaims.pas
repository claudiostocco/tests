unit CredentialClaims;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  {$ifdef FPC}
  (* Lazarus *)
  Classes, SysUtils, fpjwt
  {$else}
  (* Delphi *)
  System.Classes, System.SysUtils, System.DateUtils, System.JSON,
  (* Horse *)
  JOSE.Core.JWT, JOSE.Types.JSON
  {$endif}
  ;

type

  { TCredentialClaims }

  {$ifdef FPC}
    TCredentialClaims = class(TClaims)
  {$else}
    TCredentialClaims = class(TJWTClaims)
  {$endif}
  strict private
  {$ifdef FPC}
    FConnectionID: String;
    FID: String;
    FCNPJ: String;
    FUser: String;
    FEmpresaID: String;
  {$endif}
  private
    function GetConnectionID: String;
    function GetEmpresaID: String;
    function GetUser: String;
    procedure SetConnectionID(Value: String);
    procedure SetEmpresaID(Value: String);
    procedure SetID(const Value: String);
    function GetID: String;
    function GetCNPJ: String;
    procedure SetCNPJ(const Value: String);
    procedure SetUser(AValue: String);
  published
    property ConnectionID: String read GetConnectionID write SetConnectionID;
    property ID: String read GetID write SetID;
    property CNPJ: String read GetCNPJ write SetCNPJ;
    property User: String read GetUser write SetUser;
    property EmpresaID: String read GetEmpresaID write SetEmpresaID;
  end;

implementation

{ TCredentialClaims }

function TCredentialClaims.GetCNPJ: String;
begin
  {$ifdef FPC}
    Result := FCNPJ;
  {$else}
    if FJSON <> nil then
      Result := TJSONUtils.GetJSONValue('cnpj',FJSON).AsString
    else
      Result := '';
  {$endif}
end;

function TCredentialClaims.GetConnectionID: String;
begin
  {$ifdef FPC}
    Result := FConnectionID;
  {$else}
    if FJSON <> nil then
      Result := TJSONUtils.GetJSONValue('connectionId',FJSON).AsString
    else
      Result := '';
  {$endif}
end;

function TCredentialClaims.GetEmpresaID: String;
begin
  {$ifdef FPC}
    Result := FEmpresaID;
  {$else}
    if FJSON <> nil then
      Result := TJSONUtils.GetJSONValue('empresaId',FJSON).AsString
    else
      Result := '';
  {$endif}
end;

function TCredentialClaims.GetUser: String;
begin
  {$ifdef FPC}
    Result := FUser;
  {$else}
    if FJSON <> nil then
      Result := TJSONUtils.GetJSONValue('user',FJSON).AsString
    else
      Result := '';
  {$endif}
end;

function TCredentialClaims.GetID: String;
begin
  {$ifdef FPC}
    Result := FID;
  {$else}
    if FJSON <> nil then
      Result := TJSONUtils.GetJSONValue('id',FJSON).AsString
    else
      Result := '';
  {$endif}
end;

procedure TCredentialClaims.SetCNPJ(const Value: String);
begin
  {$ifdef FPC}
    FCNPJ := Value;
  {$else}
    TJSONUtils.SetJSONValueFrom<String>('cnpj',Value,FJSON);
  {$endif}
end;

procedure TCredentialClaims.SetUser(AValue: String);
begin
  {$ifdef FPC}
    FUser := AValue;
  {$else}
    TJSONUtils.SetJSONValueFrom<String>('user',AValue,FJSON);
  {$endif}
end;

procedure TCredentialClaims.SetConnectionID(Value: String);
begin
  {$ifdef FPC}
    FConnectionID := Value;
  {$else}
    TJSONUtils.SetJSONValueFrom<String>('connectionId',Value,FJSON);
  {$endif}
end;

procedure TCredentialClaims.SetEmpresaID(Value: String);
begin
  {$ifdef FPC}
    FEmpresaID := Value;
  {$else}
    TJSONUtils.SetJSONValueFrom<String>('empresaId',Value,FJSON);
  {$endif}
end;

procedure TCredentialClaims.SetID(const Value: String);
begin
  {$ifdef FPC}
    FID := Value;
  {$else}
    TJSONUtils.SetJSONValueFrom<String>('id',Value,FJSON);
  {$endif}
end;

end.
