unit main;

{$ifdef FPC}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  {$ifdef FPC}
  Classes, SysUtils,
  {$else}
  System.Classes, System.SysUtils, Winapi.Windows,
  {$endif}
  Horse, Horse.HandleException, Horse.CORS, Horse.Logger,
  Horse.Logger.Provider.LogFile, Horse.Jhonson, Request.Logger.Manager,
  connector.configuration, controller.routes, CredentialClaims, controller.session;

  type

    { TServerMain }

    TServerMain = class
    private
      class var FInstance: TServerMain;
      FHorseThread: TThread;
      function LoadConfig: Boolean;
      procedure StopHorseService(Sender: TObject);
    public
      class function CreateServer: TServerMain;
      class function GetInstance: TServerMain;
      class procedure FreeInstance;
      function Start: Boolean;
      function Stop: Boolean;
    end;

    procedure StopServer;

implementation

{ TServerMain }

class procedure TServerMain.FreeInstance;
begin
  GetInstance.Free;
end;

class function TServerMain.GetInstance: TServerMain;
begin
  if FInstance = nil then
    FInstance := TServerMain.Create;
  Result := FInstance;
end;

function UseRequestLogger(LocalLog: String): THorseCallback;
var sFormat: String;
    LLogFileConfig: THorseLoggerLogFileConfig;
begin
  sFormat := '${request_clientip} [${time}] - "${request_method} ${request_url} ${request_version}"';
  LLogFileConfig := THorseLoggerLogFileConfig.New
                                             .SetLogFormat(sFormat)
                                             .SetDir(LocalLog)
                                             .SetLogName('req');
  TRequestLoggerManager.RegisterProvider(THorseLoggerProviderLogFile.New(LLogFileConfig));
  Result := TRequestLoggerManager.HorseCallback();
end;

function UseLogger(LocalLog: String): THorseCallback;
var sFormat: String;
    LLogFileConfig: THorseLoggerLogFileConfig;
begin
  sFormat := '${request_clientip} [${time}] - "${request_method} ${request_url} ${request_version}" -> '+
             '${response_status} ${response_content_length} - exec: ${execution_time}ms';
  LLogFileConfig := THorseLoggerLogFileConfig.New.SetLogFormat(sFormat).SetDir(LocalLog);
  THorseLoggerManager.RegisterProvider(THorseLoggerProviderLogFile.New(LLogFileConfig));
  Result := THorseLoggerManager.HorseCallback();
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
begin
  try
    Res.RawWebResponse.ContentType := 'application/json; charset=UTF-8';
  finally
    Next;
  end;
end;

function ResponseContentType: THorseCallback;
begin
  Result := Middleware;
end;

procedure SessionMiddleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
var sEmpresaID: String;
    ASession: TSessionManager;
begin
  try
    sEmpresaID := Req.Headers['EmpresaID'];
    if not sEmpresaID.IsEmpty then
    begin
      ASession := TSessionManager.New
                                 .EmpresaID(sEmpresaID);
      Req.Sessions.SetSession(TSessionManager,ASession);
    end;
  finally
    Next;
  end;
end;

function UserSession: THorseCallBack;
begin
  Result := SessionMiddleware;
end;

function TServerMain.LoadConfig: Boolean;
begin
  Result := True;
end;

procedure onListen;
begin
  {$ifdef console}
     WriteLn(Format('Server started on port %d',[THorse.Port]));
  {$endif}
end;

procedure CreateHorseService;
begin
  (* Registra o log antes de processar a req *)
  THorse.Use(UseRequestLogger('./logs'));
  (* Registra o log depois de processar a req, inclui response *)
  THorse.Use(UseLogger('./logs'));

  THorse.Use(CORS);
  THorse.Use(ResponseContentType);
  THorse.Use(Jhonson);
  THorse.Use(HandleException);
  THorse.Use(UserSession);

  THorse.Port := TConfiguration.ApiPort;

  TControllerRoutes.registerRoutes;

  {$ifndef FPC}
    IsConsole := False;
  {$endif}
  THorse.Listen(onListen);
  {$ifndef FPC}
    IsConsole := True;
    Readln;
  {$endif}
end;

procedure TServerMain.StopHorseService(Sender: TObject);
begin
  THorse.StopListen;
end;

class function TServerMain.CreateServer: TServerMain;
begin
  TConfiguration.Initialize;
  Result := GetInstance;
  Result.LoadConfig;
  Result.FHorseThread := TThread.CreateAnonymousThread(CreateHorseService);
  Result.FHorseThread.OnTerminate := StopHorseService;
end;

function TServerMain.Start: Boolean;
begin
  with GetInstance do
  begin
    FHorseThread.Start;
    {$IF DEFINED(HORSE_DAEMON)}
      Result := False;
    {$ELSE}
      Result := True;
    {$ENDIF}
  end;
end;

function TServerMain.Stop: Boolean;
begin
  {$IF DEFINED(HORSE_DAEMON)}
    THorse.StopListen;
  {$ELSE}
    GetInstance.FHorseThread.Terminate;
    //GetInstance.FHorseThread.WaitFor;
  {$ENDIF}
  Result := True;
end;

procedure StopServer;
{$ifndef FPC}
var iHandle: UInt64;
{$endif}
begin
  {$ifndef FPC}
    iHandle := FindWindow('TServerMain',nil);
    SendMessage(iHandle,WAIT_ABANDONED,0,0);
  {$endif}
end;

initialization

finalization
  Writeln('Freeing instances.');
  TConfiguration.FreeInstance;
  TServerMain.FreeInstance;

end.

