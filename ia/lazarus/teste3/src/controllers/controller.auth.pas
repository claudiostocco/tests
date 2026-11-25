unit controller.auth;

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
  , Horse, adapter.json, service.auth, service.usuario;

type

{ TAuthController }

  TAuthController = class
  private
  public
    class procedure registerRoutes;
  end;

implementation

procedure onPost(req: THorseRequest; res: THorseResponse);
var json, jsonRes: TJSONObject;
    sClient_Id, sClient_Secret, sUser, sResponse: String;
    svcUsuario: TUsuarioService;
    tmpStatus: THTTPStatus;
begin
  try
    with TAuthService.Create do
    begin
      try
        sClient_Id := '';
        sClient_Secret := '';
        sUser := '';
        if req.Body.Contains('&client_id=') and req.Body.Contains('&client_secret=') then
        begin
          with TStringList.Create do
          begin
            try
              Delimiter := '&';
              DelimitedText := Req.Body;
              sClient_Id := Values['client_id'];
              sClient_Secret := Values['client_secret'];
            finally
              Free;
            end;
          end;
        end else
        begin
          json := GetJSON(req.Body) as TJSONObject;
          try
            if json <> nil then
            begin
              if json.Find('client_id') <> nil then
                sClient_Id := json.Get('client_id');
              if json.Find('client_secret') <> nil then
                sClient_Secret := json.Get('client_secret');
              if json.Find('usuario') <> nil then
                sUser := json.Get('usuario');
            end;
          finally
            FreeAndNil(json);
          end;
        end;
        if (not sClient_Id.IsEmpty) and (not sClient_Secret.IsEmpty) then
        begin
          if Authorize(sClient_Id, sClient_Secret, sUser) then
          begin
            //WriteLn(DadosConexao);
            if req.PathInfo.Contains('/login') and (ServiceResult.Status = THTTPStatus.OK) then
            begin
              try
                svcUsuario := TUsuarioService.Create(ConnId);
                svcUsuario.login(Req.Body);
                //WriteLn(svcUsuario.DadosConexao);
                //WriteLn(DadosConexao);
                tmpStatus := svcUsuario.ServiceResult.Status;
                if tmpStatus = THTTPStatus.Accepted then
                begin
                  try
                    jsonRes := GetJSON(ServiceResult.MessageResponse) as TJSONObject;
                    jsonRes.Add('usuario',GetJSON(svcUsuario.ServiceResult.MessageResponse) as TJSONObject);
                    sResponse := jsonRes.AsJSON;
                  finally
                    FreeAndNil(jsonRes);
                  end;
                end else
                  sResponse := svcUsuario.ServiceResult.MessageResponse;
                SetServiceResult(sResponse,tmpStatus);
              finally
                FreeAndNil(svcUsuario);
                //WriteLn(DadosConexao);
                //DestroyConnection;
              end;
            end;
            res.Status(ServiceResult.Status)
               .Send(ServiceResult.MessageResponse)
          end else
            raise EHorseException.New.Status(THTTPStatus.Unauthorized).Error('Função de verificação retornou não autorizado!');
        end else
          raise EHorseException.New.Status(THTTPStatus.BadRequest).Error('Dados da requisição inválidos!');
      finally
        Free;
      end;
    end;
  except
  on e: EHorseException do
    raise;
  on e: Exception do
     if not (e is EHorseException) then
       raise EHorseException.New.Status(THTTPStatus.InternalServerError).Error('Erro na solicitação do recursso: '''+THorseRequest(req).RawWebRequest.PathInfo+''' Msg de erro: '+e.Message);
  end;
end;

procedure onDecryptPost(req: THorseRequest; res: THorseResponse);
begin
  res.ContentType('text/plain')
     .Send(TAuthService.Decrypt(req.body));
end;

procedure onGetTesteConexao(req: THorseRequest; res: THorseResponse);
begin
  try
    with TAuthService.Create do
    begin
      try
        TesteConexao;
        res.Status(ServiceResult.Status)
           .Send(ServiceResult.MessageResponse);
      finally
        Free;
      end;
    end;
  except
  on e: EHorseException do
    raise;
  on e: Exception do
     if not (e is EHorseException) then
       raise EHorseException.New.Status(THTTPStatus.InternalServerError).Error('Erro na solicitação do recursso: '''+THorseRequest(req).RawWebRequest.PathInfo+''' Msg de erro: '+e.Message);
  end;
end;

{ TAuthController }

class procedure TAuthController.registerRoutes;
begin
  THorse.Post('/auth', onPost);
  THorse.Post('/auth/login', onPost);
  THorse.Post('/decrypt', onDecryptPost);

  THorse.Get('/auth/testeconexao',onGetTesteConexao);
end;

end.

