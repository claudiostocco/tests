unit controller.usuario;

{$ifdef FPC}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  {$ifdef FPC}
  Classes, SysUtils
  {$else}
  System.Classes, System.SysUtils, Web.HTTPApp
  {$endif}
  , Horse, Horse.Commons, controller.session, service.usuario;

  type
    { TUsuarioController }

    TUsuarioController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  try
    with TUsuarioService.Create(ProcessSession(Req).ConnectionID) do
    begin
      try
        if listAll(Req.Params.Dictionary) then
        begin
          Res.Status(ServiceResult.Status)
             .Send(ServiceResult.MessageResponse);
	end;
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

procedure onPost(Req: THorseRequest; Res: THorseResponse);
var user: String;
begin
  try
    if (Req.Body.Trim.IndexOf('{') = 0) and (Req.Body.Trim.Chars[Req.Body.Trim.Length-1] = '}') then
    begin
      with TUsuarioService.Create(ProcessSession(Req).ConnectionID) do
      begin
        try
          user := ProcessSession(Req).User;
          if Req.MethodType = mtPut then
            update(Req.Body,user)
          else
            insert(Req.Body,user);

          Res.Status(ServiceResult.Status)
             .Send(ServiceResult.MessageResponse);
        finally
	  Free;
        end;
      end;
    end else
      raise EHorseException.New.Status(THTTPStatus.BadRequest).Error('É obrigatório corpo para a requisição!');
  except
  on e: EHorseException do
    raise;
  on e: Exception do
     if not (e is EHorseException) then
       raise EHorseException.New.Status(THTTPStatus.InternalServerError).Error('Erro na solicitação do recursso: '''+THorseRequest(req).RawWebRequest.PathInfo+''' Msg de erro: '+e.Message);
  end;
end;

procedure onDelete(Req: THorseRequest; Res: THorseResponse);
begin
  try
    if Req.Params.ContainsKey('id') then
    begin
      with TUsuarioService.Create(ProcessSession(Req).ConnectionID) do
      begin
        try
          delete(Req.Params.Items['id'],ProcessSession(Req).User);
          Res.Status(ServiceResult.Status)
             .Send(ServiceResult.MessageResponse);
        finally
	  Free;
        end;
      end;
    end else
      raise EHorseException.New.Status(THTTPStatus.BadRequest).Error('É obrigatório informar o identificador para a exclusão!');
  except
  on e: EHorseException do
    raise;
  on e: Exception do
     if not (e is EHorseException) then
       raise EHorseException.New.Status(THTTPStatus.InternalServerError).Error('Erro na solicitação do recursso: '''+THorseRequest(req).RawWebRequest.PathInfo+''' Msg de erro: '+e.Message);
  end;
end;

procedure onLogin(Req: THorseRequest; Res: THorseResponse);
begin
  try
    if (Req.Body.Trim.IndexOf('{') = 0) and (Req.Body.Trim.Chars[Req.Body.Trim.Length-1] = '}') then
    begin
      with TUsuarioService.Create(ProcessSession(Req).ConnectionID) do
      begin
        try
          login(Req.Body);
          Res.Status(ServiceResult.Status)
             .Send(ServiceResult.MessageResponse);
        finally
	  Free;
        end;
      end;
    end else
      raise EHorseException.New.Status(THTTPStatus.BadRequest).Error('É obrigatório corpo para a requisição!');
  except
  on e: EHorseException do
    raise;
  on e: Exception do
     if not (e is EHorseException) then
       raise EHorseException.New.Status(THTTPStatus.InternalServerError).Error('Erro na solicitação do recursso: '''+THorseRequest(req).RawWebRequest.PathInfo+''' Msg de erro: '+e.Message);
  end;
end;

procedure onGetTesteConexao(req: THorseRequest; res: THorseResponse);
begin
  try
    with TUsuarioService.Create(ProcessSession(Req).ConnectionID) do
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

{ TUsuarioController }

class procedure TUsuarioController.registerRoutes;
begin
  THorse.Get('/usuario',onGet);
  THorse.Get('/usuario/:id',onGet);
  THorse.Post('/usuario',onPost);
  THorse.Put('/usuario',onPost);
  THorse.Delete('/usuario/:id',onDelete);

  THorse.Post('/usuario/login',onLogin);

  THorse.Get('/usuario/testeconexao',onGetTesteConexao);
end;

end.

