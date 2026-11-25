unit controller.root;

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
  , Horse, constants.common;

  type
    { TRootController }

    TRootController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  Res.ContentType('text/html')
     .Status(200)
     .Send(Format(
           '<html>'+
           '  <head><title>SGT API Server home page</title></head>'+
           '  <body>'+
           '    <h1>SGT API Server home page - Server is running on port %d - Horse version %s</h1>'+
           '  </body>'+
           '</html>',
           [THorse.Port,THorse.Version]));
end;

procedure onVersion(Req: THorseRequest; Res: THorseResponse);
var jVer: String;
begin
  jVer := Format('{"version": "%d.%d.%d"}',[MajorVersion,MinorVersion,Release]);
  Res.Status(THTTPStatus.OK)
     .Send(jVer);
end;

{ TRootController }

class procedure TRootController.registerRoutes;
begin
  THorse.Get('/',onGet);
  THorse.Get('/version',onVersion);
end;

end.

