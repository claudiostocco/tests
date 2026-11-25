unit controller.municipio;

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
  , Horse, Horse.Commons, controller.session, service.municipio;

  type
    { TMunicipioController }

    TMunicipioController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  try
    with TmunicipioService.Create(ProcessSession(Req).ConnectionID) do
    begin
      try
        if not Req.PathInfo.Contains('full') then SetResumo;
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
      with TmunicipioService.Create(ProcessSession(Req).ConnectionID) do
      begin
        try
          User := ProcessSession(Req).User;
          if Req.MethodType = mtPut then
            update(Req.Body)
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

{ TMunicipioController }

class procedure TMunicipioController.registerRoutes;
begin
  THorse.Get('/municipio',onGet);
  THorse.Get('/municipio/:id',onGet);
  THorse.Get('/municipio/:id/full',onGet);
  THorse.Get('/municipio/estadoid/:estadoid',onGet);
  THorse.Get('/municipio/cidade/:cidade',onGet);
  THorse.Get('/municipio/uf/:uf',onGet);
  THorse.Post('/municipio',onPost);
  THorse.Put('/municipio',onPost);
end;

end.
