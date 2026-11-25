unit CipherData;

{$ifdef FPC}
  {$mode ObjFPC}{$H+}
{$endif}

interface

uses
  {$ifdef FPC}
    Classes, SysUtils, DCPtwofish, DCPsha256;
  {$else}
    (* Delphi *)
    System.Classes, System.SysUtils;
  {$endif}

type

	{ TCipherData }

  TCipherData = class
  private
  public
    class function Encrypt(Data, Key: String): String;
    class function Decrypt(Data, Key: String): String;
  end;

implementation

{ TCipherData }

class function TCipherData.Encrypt(Data, Key: String): String;
{$ifdef FPC}
var LCipher: TDCP_twofish;
begin
  try
    LCipher := TDCP_twofish.Create(nil);
    LCipher.InitStr(Key,TDCP_sha256);
    Result := LCipher.EncryptString(Data);
  finally
    FreeAndNil(LCipher);
  end;
end;
{$else}
begin
  try
    Result := Data;
  finally
  end;
end;
{$endif}

class function TCipherData.Decrypt(Data, Key: String): String;
{$ifdef FPC}
var LCipher: TDCP_twofish;
begin
  try
    LCipher := TDCP_twofish.Create(nil);
    LCipher.InitStr(Key,TDCP_sha256);
    Result := LCipher.DecryptString(Data);
  finally
    FreeAndNil(LCipher);
  end;
end;
{$else}
begin
  try
    Result := Data;
  finally
  end;
end;
{$endif}

end.

