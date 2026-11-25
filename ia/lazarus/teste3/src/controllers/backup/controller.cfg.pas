unit controller.cfg;

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
  , Horse, controller.session, service.cfg;

  type
    { TCfgController }

    TCfgController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  try
    with TcfgService.Create(ProcessSession(Req).ConnectionID) do
    begin
      try
        if Req.Params.ContainsKey('tmcodigo') and Req.Params.ContainsKey('tipo') and Req.Params.ContainsKey('nome') then SetResumo;
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
      with TcfgService.Create(ProcessSession(Req).ConnectionID) do
      begin
        try
          if Req.Params.ContainsKey('id') then
            update(Req.Params.Items['id'],Req.Body)
          else
            insert(Req.Body);

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

{ TCfgController }

class procedure TCfgController.registerRoutes;
begin
  THorse.Get('/cfg/:proprietario',onGet);
  THorse.Get('/cfg/:proprietario/:nivel',onGet);
  THorse.Get('/cfg/:tmcodigo/:tipo/:nome',onGet);
  THorse.Post('/cfg',onPost);
end;

end.
