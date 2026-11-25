unit controller.routes;

{$ifdef FPC}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  {$ifdef FPC}
  Classes, SysUtils,
  {$else}
  System.Classes, System.SysUtils,
  {$endif}
  Horse, Horse.JWT, JWT, CredentialClaims, controller.root, controller.auth,
  controller.empresa, controller.usuario, controller.entidade, controller.cfg,
  controller.estado, controller.municipio, controller.tabela, controller.cfop,
  controller.unidade, controller.icms, controller.produtoorigem,
  controller.setor, controller.produto, controller.cpgto, controller.modalidade,
  controller.movitem, controller.movimento, controller.movvenda,
  controller.movpagamento, controller.estoque, controller.naturezaop;

  type

    { TControllerRoutes }

    TControllerRoutes = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

{ TControllerRoutes }

class procedure TControllerRoutes.registerRoutes;
begin
  (* Without authorization *)
  TRootController.registerRoutes;
  TAuthController.registerRoutes;

  (* With authorization *)
  THorse.Use('/empresa',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TEmpresaController.registerRoutes;

  THorse.Use('/cfg',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TCfgController.registerRoutes;

  THorse.Use('/usuario',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TUsuarioController.registerRoutes;

  THorse.Use('/estado',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TEstadoController.registerRoutes;

  THorse.Use('/municipio',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TMunicipioController.registerRoutes;

  THorse.Use('/tabela',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TTabelaController.registerRoutes;

  THorse.Use('/cfop',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TCfopController.registerRoutes;

  THorse.Use('/cliente',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  THorse.Use('/fornecedor',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TEntidadeController.registerRoutes;

  THorse.Use('/unidade',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TUnidadeController.registerRoutes;

  THorse.Use('/icms',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TIcmsController.registerRoutes;

  THorse.Use('/produtoorigem',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TProdutoOrigemController.registerRoutes;

  THorse.Use('/setor',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TSetorController.registerRoutes;

  THorse.Use('/produto',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TProdutoController.registerRoutes;

  THorse.Use('/estoque',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TEstoqueController.registerRoutes;

  THorse.Use('/cpgto',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TCPgtoController.registerRoutes;

  THorse.Use('/modalidade',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TModalidadeController.registerRoutes;

  THorse.Use('/movimento',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TMovimentoController.registerRoutes;

  THorse.Use('/movvenda',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TMovVendaController.registerRoutes;

  THorse.Use('/movitem',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TMovItemController.registerRoutes;

  THorse.Use('/movpagamento',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TMovPagamentoController.registerRoutes;

  THorse.Use('/naturezaop',HorseJWT(SERVER_SK,THorseJWTConfig.New.SessionClass(TCredentialClaims)));
  TNaturezaOpController.registerRoutes;
end;

end.

