unit controller.movitem;

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
  , Horse, Horse.Commons, controller.session, service.movitem;

  type
    { TMovItemController }

    TMovItemController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  try
     with TMovItemService.Create(ProcessSession(Req).ConnectionID) do
     begin
       try
         CanceledOnly := Req.Query.ContainsKey('canceled');
         if Req.PathInfo.Contains('full') or Req.Params.ContainsKey('id') then
           SetFull
         else
           SetResumo;
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
    if ((Req.Body.Trim.IndexOf('{') = 0) and (Req.Body.Trim.Chars[Req.Body.Trim.Length-1] = '}')) or
       ((Req.Body.Trim.IndexOf('[') = 0) and (Req.Body.Trim.Chars[Req.Body.Trim.Length-1] = ']')) then
    begin
       with TMovItemService.Create(ProcessSession(Req).ConnectionID) do
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

procedure onDelete(Req: THorseRequest; Res: THorseResponse);
begin
  try
    if Req.Params.ContainsKey('id') and Req.Params.ContainsKey('item') then
    begin
       with TMovItemService.Create(ProcessSession(Req).ConnectionID) do
       begin
         try
           User := ProcessSession(Req).User;
           delete(Req.Params.Dictionary);
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

{ TMovItemController }

class procedure TMovItemController.registerRoutes;
begin
  THorse.Get('/movitem',onGet);
  THorse.Get('/movitem/:id',onGet);
  THorse.Get('/movitem/:id/:item/full',onGet);

  THorse.Post('/movitem',onPost);
  THorse.Put('/movitem',onPost);
  THorse.Delete('/movitem/:id/:item',onDelete);
end;

end.
