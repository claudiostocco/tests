unit controller.empresa;

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
  , Horse, controller.session, service.empresa;

  type
    { TEmpresaController }

    TEmpresaController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  try
    with TEmpresaService.Create(ProcessSession(Req).ConnectionID) do
    begin
      try
        if not Req.Params.ContainsKey('id') then SetResumo;
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
begin
  try
    if (Req.Body.Trim.IndexOf('{') = 0) and (Req.Body.Trim.Chars[Req.Body.Trim.Length-1] = '}') then
    begin
      with TEmpresaService.Create(ProcessSession(Req).ConnectionID) do
      begin
        try
          User := ProcessSession(Req).User;
          if Req.Params.ContainsKey('id') then
          begin
            if Req.PathInfo.Contains('/logo') then
              setLogo(Req.Params.Items['id'],Req.Body);
          end else
          begin
            if Req.Params.ContainsKey('key') and verifyKey(Req.Params.Items['key']) then
              insert(Req.Body)
            else
              EHorseException.New.Status(THTTPStatus.Forbidden).Error('Chave inválida!');
          end;

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
      with TEmpresaService.Create(ProcessSession(Req).ConnectionID) do
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

{ TEmpresaController }

class procedure TEmpresaController.registerRoutes;
begin
  THorse.Get('/empresa',onGet);
  THorse.Get('/empresa/:id',onGet);
  THorse.Get('/empresa/:id/logo',onGet);
  THorse.Post('/empresa/:key',onPost);
  THorse.Post('/empresa/:id/logo',onPost);
  THorse.Delete('/empresa/:id',onDelete);
end;

end.
