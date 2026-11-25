program sgtapi_d;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  main in 'main.pas',
  adapter.json in 'adapters\adapter.json.pas',
  adapter.query.impl in 'adapters\adapter.query.impl.pas',
  adapter.query.intf in 'adapters\adapter.query.intf.pas',
  connector.configuration in 'connectors\connector.configuration.pas',
  connector.factory in 'connectors\connector.factory.pas',
  connector.firedac in 'connectors\connector.firedac.pas',
  connector.zeos in 'connectors\connector.zeos.pas',
  constants.common in 'constants\constants.common.pas',
  controller.auth in 'controllers\controller.auth.pas',
  controller.root in 'controllers\controller.root.pas',
  controller.routes in 'controllers\controller.routes.pas',
  controller.session in 'controllers\controller.session.pas',
  controller.usuario in 'controllers\controller.usuario.pas',
  connection in 'db\connection.pas' {dmConn: TDataModule},
  cipherdata in 'security\cipherdata.pas',
  CredentialClaims in 'security\CredentialClaims.pas',
  JWT in 'security\JWT.pas',
  service.auth in 'services\service.auth.pas',
  service.serviceprovider in 'services\service.serviceprovider.pas',
  service.usuario in 'services\service.usuario.pas',
  controller.cfg in 'controllers\controller.cfg.pas',
  controller.cfop in 'controllers\controller.cfop.pas',
  controller.empresa in 'controllers\controller.empresa.pas',
  controller.entidade in 'controllers\controller.entidade.pas',
  controller.estado in 'controllers\controller.estado.pas',
  controller.municipio in 'controllers\controller.municipio.pas',
  controller.tabela in 'controllers\controller.tabela.pas',
  service.cfg in 'services\service.cfg.pas',
  service.cfop in 'services\service.cfop.pas',
  service.empresa in 'services\service.empresa.pas',
  service.entidade in 'services\service.entidade.pas',
  service.estado in 'services\service.estado.pas',
  service.municipio in 'services\service.municipio.pas',
  service.serviceprovidercadastros in 'services\service.serviceprovidercadastros.pas',
  service.tabela in 'services\service.tabela.pas',
  service.commons in 'services\service.commons.pas',
  controller.icms in 'controllers\controller.icms.pas',
  controller.produto in 'controllers\controller.produto.pas',
  controller.produtoorigem in 'controllers\controller.produtoorigem.pas',
  controller.setor in 'controllers\controller.setor.pas',
  controller.unidade in 'controllers\controller.unidade.pas',
  service.icms in 'services\service.icms.pas',
  service.produto in 'services\service.produto.pas',
  service.produtoorigem in 'services\service.produtoorigem.pas',
  service.setor in 'services\service.setor.pas',
  service.unidade in 'services\service.unidade.pas',
  service.cpgto in 'services\service.cpgto.pas',
  service.modalidade in 'services\service.modalidade.pas',
  service.movimento in 'services\service.movimento.pas',
  service.movitem in 'services\service.movitem.pas',
  service.movpagamento in 'services\service.movpagamento.pas',
  service.movvenda in 'services\service.movvenda.pas',
  controller.cpgto in 'controllers\controller.cpgto.pas',
  controller.modalidade in 'controllers\controller.modalidade.pas',
  controller.movimento in 'controllers\controller.movimento.pas',
  controller.movitem in 'controllers\controller.movitem.pas',
  controller.movpagamento in 'controllers\controller.movpagamento.pas',
  controller.movvenda in 'controllers\controller.movvenda.pas',
  logfile.logger in 'utils\logfile.logger.pas',
  request.logger.manager in 'utils\request.logger.manager.pas',
  service.estoque in 'services\service.estoque.pas',
  controller.estoque in 'controllers\controller.estoque.pas',
  utils in 'utils\utils.pas',
  utils.parsejsontosql in 'utils\utils.parsejsontosql.pas';

begin
  try
    ReportMemoryLeaksOnShutdown := True;
    TConfiguration.Initialize;
    if (ParamCount > 0) and (ParamStr(1).ToLower = 'stop') then
      StopServer
    else
      TServerMain.CreateServer.Start;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
