unit controller.movpagamento;

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
  , Horse, Horse.Commons, logfile.logger, controller.session, service.movpagamento;

  type
    { TMovPagamentoController }

    TMovPagamentoController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  try
     with TMovPagamentoService.Create(ProcessSession(Req).ConnectionID) do
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
    if (Req.Body.Trim.IndexOf('{') = 0) and (Req.Body.Trim.Chars[Req.Body.Trim.Length-1] = '}') then
    begin
       with TMovPagamentoService.Create(ProcessSession(Req).ConnectionID) do
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
    begin
      log(THorseRequest(req).RawWebRequest.PathInfo.Replace('/','.'),e.Message);
      if not (e is EHorseException) then
        raise EHorseException.New.Status(THTTPStatus.InternalServerError).Error('Erro na solicitação do recursso: '''+THorseRequest(req).RawWebRequest.PathInfo+''' Msg de erro: '+e.Message);
    end;
  end;
end;

procedure onDelete(Req: THorseRequest; Res: THorseResponse);
begin
  try
    if Req.Params.ContainsKey('id') and Req.Params.ContainsKey('item') then
    begin
       with TMovPagamentoService.Create(ProcessSession(Req).ConnectionID) do
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

{ TMovPagamentoController }

class procedure TMovPagamentoController.registerRoutes;
begin
  THorse.Get('/movpagamento',onGet);
  THorse.Get('/movpagamento/:id',onGet);
  THorse.Get('/movpagamento/:id/full',onGet);

  THorse.Post('/movpagamento',onPost);
  THorse.Put('/movpagamento',onPost);
  THorse.Delete('/movpagamento/:id/:item',onDelete);
end;

end.
