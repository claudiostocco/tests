unit logfile.logger;
{$ifdef FPC}
  {$mode delphi}{$H+}
{$ifend}

interface

uses
  Classes, SysUtils;

const log_path = './logs';

procedure log(Name: String; Content: String);

implementation

procedure log(Name: String; Content: String);
var sLogName: String;
    LogFile: TextFile;
begin
  try
    sLogName := log_path+'/log_'+FormatDateTime('yyyy-mm-dd',Now)+'_'+Name;
    AssignFile(LogFile,sLogName);
    if FileExists(sLogName) then
      Append(LogFile)
    else
      Rewrite(LogFile);
    try
      WriteLn(LogFile,FormatDateTime('yyyy-mm-dd hh:nn:ss',Now)+'  ---------------------------------');
      WriteLn(LogFile,Content);
      {$ifdef console}
        WriteLn(FormatDateTime('yyyy-mm-dd hh:nn:ss',Now)+'  ---------------------------------');
        WriteLn(Content);
      {$endif}
    finally
      CloseFile(LogFile);
    end;
  except
  end;
end;

end.

