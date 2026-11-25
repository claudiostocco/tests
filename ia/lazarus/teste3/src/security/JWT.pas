unit JWT;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  {$ifdef FPC}
  (* Lazarus *)
  Classes, SysUtils, DateUtils, fpjson, fpjwt, HlpIHashInfo, HlpConverters, HlpHashFactory, base64,
  {$else}
  (* Delphi *)
  System.Classes, System.SysUtils, System.DateUtils, System.JSON,
  (* Horse *)
  JOSE.Core.JWT, JOSE.Core.Builder,
  {$endif}

  (* Horse *)
  Horse, Horse.JWT,

  (* Aplicação *)
  CredentialClaims, CipherData;

const SERVER_SK = 'SGT_%..0G5E7P5g.2e0p5G9E.0P0g0e1p.5G0#';
      DATA_SK = 'SGT_Utg..%539%_J$';

function createToken(ID, ClientID, User, ConnectionID: String): String;
//function getCredential(Session: TJSONObject): TCredentialClaims;

implementation

{$ifdef FPC}
  function HexToAscii(const HexStr: string): AnsiString;
  Var
    B: Byte;
    Cmd: string;
    I, L: Integer;
  begin
    Result := '';
    Cmd := Trim(HexStr);
    I := 1;
    L := Length(Cmd);
    while I < L do
    begin
       B := StrToInt('$' + copy(Cmd, I, 2));
       Result := Result + AnsiChar(chr(B));
       Inc( I, 2);
    end;
  end;
{$endif}

function createToken(ID, ClientID, User, ConnectionID: String): String;
var LJWT: TJWT;
    {$ifdef FPC}
      LHMAC: IHMAC;
      LSignCalc: String;
    {$endif}
    ccCredential: TCredentialClaims;
begin
   if (ID <> '') and (ClientID <> '') then
   begin
      {$ifdef FPC}
        LJWT := TJWT.Create;
        LJWT.JOSE.alg := 'HS256';
        LJWT.JOSE.typ := 'JWT';
      {$else}
        LJWT := TJWT.Create(TCredentialClaims);
      {$endif}
      try
         (* Enter the payload data *)
         {$ifdef FPC}
           ccCredential := TCredentialClaims.Create;
           ccCredential.exp := DateTimeToUnix(IncHour(Now, 12));
         {$else}
           ccCredential := TCredentialClaims(LJWT.Claims);
           ccCredential.Expiration := IncMinute(Now, 180);
         {$endif}
         ccCredential.ConnectionID := TCipherData.Encrypt(ConnectionID,DATA_SK);
         ccCredential.ID := ID;
         ccCredential.CNPJ := TCipherData.Encrypt(ClientId,DATA_SK);
         ccCredential.User := TCipherData.Encrypt(User,DATA_SK);
         ccCredential.EmpresaID := '';

         (* Generating the token *)
         {$ifdef FPC}
           LJWT.Claims := ccCredential;
       	   if (LJWT.JOSE.alg = 'HS256') then
             LHMAC := THashFactory.THMAC.CreateHMAC(THashFactory.TCrypto.CreateSHA2_256)
           else if (LJWT.JOSE.alg = 'HS384') then
             LHMAC := THashFactory.THMAC.CreateHMAC(THashFactory.TCrypto.CreateSHA2_384)
           else if (LJWT.JOSE.alg = 'HS512') then
             LHMAC := THashFactory.THMAC.CreateHMAC(THashFactory.TCrypto.CreateSHA2_512)
           else
             LHMAC := THashFactory.THMAC.CreateHMAC(THashFactory.TCrypto.CreateSHA2_256);
           LHMAC.Key := TConverters.ConvertStringToBytes(UTF8Encode(SERVER_SK), TEncoding.UTF8);
           LSignCalc := HexToAscii(TConverters.ConvertBytesToHexString(LHMAC.ComputeString(UTF8Encode(Trim(LJWT.AsString)), TEncoding.UTF8).GetBytes,False));
           Result := Trim(LJWT.AsString)+'.'+LJWT.Base64ToBase64URL(EncodeStringBase64(LSignCalc));
         {$else}
           Result := TJOSE.SHA256CompactToken(SERVER_SK,LJWT);
         {$endif}
      finally
        if Assigned(LJWT) then
          FreeAndNil(LJWT);
      end;
   end;
end;

//function getCredential(Session: TJSONObject): TCredentialClaims;
//begin
//   Result := TCredentialClaims.Create;
//   Result.JSON := Session;
//// Para usar a sessão como um JSON direto
//// WriteLn(getCredential(Req.Session<TJSONObject>).ID);
//end;

end.
