unit Request.Logger.Manager;

{$IFDEF FPC }
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC }
  SysUtils, Classes, SyncObjs, Generics.Collections, fpjson,
{$ELSE}
  System.SysUtils, System.JSON, System.SyncObjs, System.Classes, System.Generics.Collections,
{$ENDIF}
  Horse.Logger.Types, Horse.Logger.Provider.Contract, Horse, Horse.Logger.Thread;

type
  TRequestLoggerManager = class;
  TRequestLoggerManagerClass = class of TRequestLoggerManager;

  TRequestLoggerManager = class(THorseLoggerThread)
  private
    class var FProviderList: TList<IHorseLoggerProvider>;
    class var FDefaultManager: TRequestLoggerManager;
  protected
    procedure DispatchLogCache; override;
    class function GetProviderList: TList<IHorseLoggerProvider>;
    class function ByteArrayToHexString(const AValue: TBytes; const ASeparator: string = ''): string;
    class function ValidateValue(const AValue: Integer): THorseLoggerLogItemNumber; overload;
    class function ValidateValue(const AValue: string): THorseLoggerLogItemString; overload;
    class function ValidateValue(const AValue: TBytes; const ASeparator: string = ''): THorseLoggerLogItemString; overload;
  	class function ValidateValue(const AValue: TDateTime; const AShort: Boolean): THorseLoggerLogItemString; overload;
    class function GetDefaultManager: TRequestLoggerManager; static;
  public
    class function HorseCallback: THorseCallback; overload;
    class function RegisterProvider(const AProvider: IHorseLoggerProvider): TRequestLoggerManagerClass;
    class property DefaultManager: TRequestLoggerManager read GetDefaultManager;
    class destructor UnInitialize;
  end;

implementation

uses
{$IFDEF FPC }
  DateUtils, HTTPDefs,
{$ELSE}
  Web.HTTPApp, System.DateUtils,
{$ENDIF}
  Horse.Utils.ClientIP;

{ TRequestLoggerManager }

procedure DefaultHorseCallback(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc);
var
  LLog: THorseLoggerLog;
  LBeforeDateTime: TDateTime;
begin
  LBeforeDateTime := Now();
  try
    LLog := THorseLoggerLog.Create;
    try
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('time', TRequestLoggerManager.ValidateValue(LBeforeDateTime, False));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('time_short', TRequestLoggerManager.ValidateValue(LBeforeDateTime, True));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_clientip', TRequestLoggerManager.ValidateValue(ClientIP(AReq)));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_method', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.Method));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_version', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.ProtocolVersion));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_url', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.URL));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_query', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.Query));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_path_info', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.PathInfo));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_path_translated', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.PathTranslated));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_cookie', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.Cookie));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_accept', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.Accept));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_from', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.From));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_host', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.Host));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_referer', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.Referer));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_user_agent', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.UserAgent));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_connection', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.Connection));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_remote_addr', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.RemoteAddr));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_remote_host', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.RemoteHost));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_server_port', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.ServerPort.ToString));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_script_name', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.ScriptName));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_authorization', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.Authorization));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_content_encoding', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.ContentEncoding));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_content_type', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.ContentType));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_content_length', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.ContentLength.ToString));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_content', TRequestLoggerManager.ValidateValue({$IF DEFINED(FPC)} TEncoding.ANSI.GetBytes({$ENDIF}AReq.RawWebRequest.{$IF DEFINED(FPC)}Content){$ELSE}RawContent{$ENDIF}, ''));
      //LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_server', TRequestLoggerManager.ValidateValue(ARes.RawWebResponse.Server));
      //LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_allow', TRequestLoggerManager.ValidateValue(ARes.RawWebResponse.Allow));
      //LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_location', TRequestLoggerManager.ValidateValue(ARes.RawWebResponse.Location));
      //LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_content_encoding', TRequestLoggerManager.ValidateValue(ARes.RawWebResponse.ContentEncoding));
      //LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_content_type', TRequestLoggerManager.ValidateValue(ARes.RawWebResponse.ContentType));
      //LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_content_length', TRequestLoggerManager.ValidateValue(ARes.RawWebResponse.ContentLength.ToString));
      //LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_content', TRequestLoggerManager.ValidateValue(ARes.RawWebResponse.Content));
      //LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_status', TRequestLoggerManager.ValidateValue(ARes.RawWebResponse.{$IF DEFINED(FPC)}Code.ToString(){$ELSE}StatusCode.ToString{$ENDIF}));
      {$IF NOT DEFINED(FPC)}
        LLog.AddPair('request_derived_from', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.DerivedFrom));
        LLog.AddPair('request_remote_ip', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.RemoteIP));
        LLog.AddPair('request_internal_path_info', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.InternalPathInfo));
        LLog.AddPair('request_raw_path_info', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.RawPathInfo));
        LLog.AddPair('request_cache_control', TRequestLoggerManager.ValidateValue(AReq.RawWebRequest.CacheControl));
//        LLog.AddPair('response_realm', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.Realm));
//        LLog.AddPair('response_log_message', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.LogMessage));
//        LLog.AddPair('response_title', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.Title));
//        LLog.AddPair('response_content_version', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.ContentVersion));
      {$ENDIF}
    finally
      TRequestLoggerManager.GetDefaultManager.NewLog(LLog);
    end;
  finally
    ANext();
  end;
end;

class function TRequestLoggerManager.ByteArrayToHexString(const AValue: TBytes; const ASeparator: string): string;
var
  LIndex: integer;
begin
  Result := '';
  for LIndex := Low(AValue) to High(AValue) do
    Result := Result + ASeparator + IntToHex(AValue[LIndex], 2);
end;

procedure TRequestLoggerManager.DispatchLogCache;
var
  LLogCache: THorseLoggerCache;
  LHorseLoggerProvider: IHorseLoggerProvider;
  I: Integer;
begin
  LLogCache := ExtractLogCache;
  try
    for I := 0 to Pred(GetProviderList.Count) do
    begin
      if Supports(GetProviderList.Items[I], IHorseLoggerProvider, LHorseLoggerProvider)  then
        LHorseLoggerProvider.DoReceiveLogCache(LLogCache);
    end;
  finally
    LLogCache.Free;
  end;
end;

class function TRequestLoggerManager.GetDefaultManager: TRequestLoggerManager;
begin
  if not Assigned(FDefaultManager) then
  begin
    FDefaultManager := TRequestLoggerManager.Create(True);
    FDefaultManager.FreeOnTerminate := False;
    FDefaultManager.Start;
  end;
  Result := FDefaultManager;
end;

class function TRequestLoggerManager.GetProviderList: TList<IHorseLoggerProvider>;
begin
  if FProviderList = nil then
    FProviderList := TList<IHorseLoggerProvider>.Create;
  Result := FProviderList;
end;

class function TRequestLoggerManager.HorseCallback: THorseCallback;
begin
  Result := DefaultHorseCallback;
end;

class function TRequestLoggerManager.RegisterProvider(const AProvider: IHorseLoggerProvider): TRequestLoggerManagerClass;
begin
  Result := TRequestLoggerManager;
  GetProviderList.Add(AProvider);
end;

class destructor TRequestLoggerManager.UnInitialize;
begin
  if FProviderList <> nil then
  begin
    FProviderList.Free;
  end;
  if FDefaultManager <> nil then
  begin
    FDefaultManager.Terminate;
    FDefaultManager.GetEvent.SetEvent;
    FDefaultManager.WaitFor;
    FDefaultManager.Free;
  end;
end;

class function TRequestLoggerManager.ValidateValue(const AValue: TBytes; const ASeparator: string = ''): THorseLoggerLogItemString;
begin
  Result := THorseLoggerLogItemString.Create(ByteArrayToHexString(AValue, ASeparator));
end;

class function TRequestLoggerManager.ValidateValue(const AValue: Integer): THorseLoggerLogItemNumber;
begin
  Result := THorseLoggerLogItemNumber.Create(AValue);
end;

class function TRequestLoggerManager.ValidateValue(const AValue: string): THorseLoggerLogItemString;
begin
  Result := THorseLoggerLogItemString.Create(AValue);
end;

class function TRequestLoggerManager.ValidateValue(const AValue: TDateTime; const AShort: Boolean): THorseLoggerLogItemString;
begin
  if AShort then
  	Result := THorseLoggerLogItemString.Create(FormatDateTime('dd/mm/yyyy hh:mm:ss.zzz', AValue))
  else
    Result := THorseLoggerLogItemString.Create(FormatDateTime('dd/MMMM/yyyy hh:mm:ss.zzz', AValue));
end;

end.
