program sgtapi;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, Classes, SysUtils, unidac10, ibprovider10, zcomponent, CustApp,
  (* App units *)
  main, controller.auth,
  service.ServiceProvider, service.auth, connector.configuration, CipherData,
  controller.session, adapter.json, controller.entidade, service.entidade,
  service.empresa, controller.empresa, service.cfg, service.estado,
  controller.cfg, controller.estado, service.municipio, controller.municipio,
  service.tabela, service.serviceprovidercadastros, controller.tabela,
  service.cfop, controller.cfop, service.commons, service.unidade,
  controller.unidade, service.produtoorigem, service.icms, service.setor,
  service.produto, controller.icms, controller.produtoorigem, controller.setor,
  controller.produto, service.produto.dm, system.config, service.modalidade,
  service.cpgto, service.movimento, service.movvenda, service.movitem, 
  service.movpagamento, controller.modalidade, controller.cpgto,
  controller.movimento, controller.movvenda, controller.movitem,
  controller.movpagamento, Request.Logger.Manager, logfile.logger,
  service.estoque, controller.estoque, utils, utils.parsejsontosql,
  service.naturezaop, controller.naturezaop;

type
  TSgtApi = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TSgtApi }

procedure TSgtApi.DoRun;
var
  ErrorMsg, Action: String;
  bRunning: Boolean;
begin
  // quick check parameters
  ErrorMsg := CheckOptions('h', 'help');
  if ErrorMsg <> '' then
  begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  { add your program here }
  Action := '';
  bRunning := TServerMain.CreateServer.Start;
  while bRunning do
  begin
    WriteLn('stop: Stop API');
    WriteLn('help: Show help');
    WriteLn('');
    WriteLn('Choice option:');
    Readln(Action);
    if Action.ToLower.Equals('stop') then
      bRunning := not TServerMain.GetInstance.Stop
    else if Action.ToLower.Equals('help') then
      WriteHelp;
  end;

  // stop program loop
  Terminate;
end;

constructor TSgtApi.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

destructor TSgtApi.Destroy;
begin
  inherited Destroy;
end;

procedure TSgtApi.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
end;

var
  Application: TSgtApi;

begin
  Application := TSgtApi.Create(nil);
  Application.Title := 'Sgt - Api';
  Application.Run;
  Application.Free;
end.

