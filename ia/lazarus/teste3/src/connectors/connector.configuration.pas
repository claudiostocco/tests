unit connector.configuration;

{$ifdef FPC}
  {$mode ObjFPC}{$H+}
{$endif}

interface

uses
  Classes, SysUtils, IniFiles;

type

  { TConfiguration }

  TConfiguration = class
  private
    class var FInstance: TConfiguration;
    FConnectionProtocol: String;
    FConnectionHostName: String;
    FConnectionPort: Integer;
    FConnectionDatabase: String;
    FConnectionUser: String;
    FConnectionPassword: String;
    FConnectionLibraryLocation: String;
    FConnectionCharSet: String;
    FCredentialDataBase: String;
    FLogLocation: String;
    FApiPort: Integer;
    constructor Create;
  public
    class procedure Initialize;
    class procedure FreeInstance;
    class function ConnectionProtocol: String;
    class function ConnectionHostName: String;
    class function ConnectionPort: Integer;
    class function ConnectionDatabase: String;
    class function ConnectionUser: String;
    class function ConnectionPassword: String;
    class function ConnectionLibraryLocation: String;
    class function ConnectionCharSet: String;
    class function CredentialDataBase: String;
    class function LogLocation: String;
    class function ApiPort: Integer;
  end;

implementation

{ TConfiguration }

constructor TConfiguration.Create;
var sPath: String;
    Ini: TIniFile;
begin
  sPath := ExtractFilePath(ParamStr(0));
  try
    try
      Ini := TIniFile.Create(sPath+'application.ini');

      FConnectionProtocol := GetEnvironmentVariable('DB_DRIVER');
      if FConnectionProtocol.IsEmpty then FConnectionProtocol := Ini.ReadString('database','driver','');

      FConnectionHostName := GetEnvironmentVariable('DB_HOST');
      if FConnectionHostName.IsEmpty then FConnectionHostName := Ini.ReadString('database','host','');

      FConnectionPort := StrToIntDef(GetEnvironmentVariable('DB_PORT'), 0);
      if FConnectionPort = 0 then FConnectionPort := Ini.ReadInteger('database','port',0);

      FConnectionDatabase := GetEnvironmentVariable('DB_NAME');
      if FConnectionDatabase.IsEmpty then FConnectionDatabase := Ini.ReadString('database','dbfile','');

      FConnectionUser := GetEnvironmentVariable('DB_USER');
      if FConnectionUser.IsEmpty then FConnectionUser := Ini.ReadString('database','user','');

      FConnectionPassword := GetEnvironmentVariable('DB_PASS');
      if FConnectionPassword.IsEmpty then FConnectionPassword := Ini.ReadString('database','password','');

      FConnectionLibraryLocation := GetEnvironmentVariable('DB_LIB');
      if FConnectionLibraryLocation.IsEmpty then FConnectionLibraryLocation := Ini.ReadString('database','libraryClient','');

      FConnectionCharSet := GetEnvironmentVariable('DB_CHARSET');
      if FConnectionCharSet.IsEmpty then FConnectionCharSet := Ini.ReadString('database','charset','');

      FCredentialDataBase := GetEnvironmentVariable('CRED_DB');
      if FCredentialDataBase.IsEmpty then FCredentialDataBase := Ini.ReadString('credential','database','sgt_cred');

      FLogLocation := GetEnvironmentVariable('LOG_DIR');
      if FLogLocation.IsEmpty then FLogLocation := Ini.ReadString('log','location','./log');

      FApiPort := StrToIntDef(GetEnvironmentVariable('API_PORT'), 0);
      if FApiPort = 0 then FApiPort := Ini.ReadInteger('api','port',5000);
    finally
       FreeAndNil(Ini);
    end;
  except on e: Exception do
  begin

  end; end;
end;

class procedure TConfiguration.Initialize;
begin
  FInstance := TConfiguration.Create;
end;

class function TConfiguration.ConnectionProtocol: String;
begin
  Result := FConnectionProtocol;
end;

class function TConfiguration.ConnectionHostName: String;
begin
  Result := FConnectionHostName;
end;

class function TConfiguration.ConnectionPort: Integer;
begin
  Result := FConnectionPort;
end;

class function TConfiguration.ConnectionDatabase: String;
begin
  Result := FConnectionDatabase;
end;

class function TConfiguration.ConnectionUser: String;
begin
  Result := FConnectionUser;
end;

class function TConfiguration.ConnectionPassword: String;
begin
  Result := FConnectionPassword;
end;

class function TConfiguration.ConnectionLibraryLocation: String;
begin
  Result := FConnectionLibraryLocation;
end;

class function TConfiguration.ConnectionCharSet: String;
begin
  Result := FConnectionCharSet;
end;

class function TConfiguration.CredentialDataBase: String;
begin
  Result := FCredentialDataBase;
end;

class procedure TConfiguration.FreeInstance;
begin
  FInstance.Free;
end;

class function TConfiguration.LogLocation: String;
begin
  Result := FLogLocation;
end;

class function TConfiguration.ApiPort: Integer;
begin
  Result := FApiPort;
end;

end.

