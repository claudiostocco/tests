program sgtapi;

{$ifdef FPC}
  {$mode objfpc}{$H+}
{$endif}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, SysUtils, zcomponent, main, controller.auth,
  service.ServiceProvider, service.auth, connector.configuration, CipherData,
  controller.session, adapter.json, controller.entidade, service.entidade,
  service.empresa, controller.empresa, service.cfg, service.estado,
  controller.cfg, controller.estado, service.municipio, controller.municipio,
  service.tabela, service.serviceprovidercadastros, controller.tabela,
  service.cfop, controller.cfop, service.commons, controller.unidade, service.unidade,
  service.produtoorigem, service.icms, service.setor, service.produto;

begin
  if (ParamCount > 0) and (ParamStr(1) = 'stop') then
  begin
    TServerMain.GetInstance.Stop;
  end else
  begin
    TConfiguration.Initialize;
    TServerMain.CreateServer.Start;
  end;
end.

