unit controller.movimento;

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
  , Horse, Horse.Commons, logfile.logger, controller.session
  , service.movimento, utils;

  type
    { TMovimentoController }

    TMovimentoController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onBadRequest(Req: THorseRequest; Res: THorseResponse);
begin
  raise EHorseException.New.Status(THTTPStatus.BadRequest).Error('Method not allowed!');
end;

procedure onGet(Req: THorseRequest; Res: THorseResponse);
var TipoMovId: SmallInt;
begin
  try
    with TMovimentoService.Create(ProcessSession(Req).ConnectionID) do
    begin
      try
        CanceledOnly := Req.Query.ContainsKey('canceled');
        TipoMovId := StrToIntDef(Req.Params.Items['movtipoid'],0);
        SetTipoMovId(TipoMovId);
        if Req.PathInfo.Contains('report') then
        begin
          if not BodyIsJsonObject(Req.Body) then
            raise EHorseException.New.Status(THTTPStatus.BadRequest).Error('É obrigatório corpo para a requisição!');
          SetReport(Req.Body);
        end else if Req.PathInfo.Contains('last') then
          SetLastSale
        else if Req.PathInfo.Contains('full') then
          SetFull
        else
        begin
          if Req.PathInfo.Contains('today') then
            SetTodayFilter;
          SetResumo;
        end;
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
    begin
      log(THorseRequest(req).RawWebRequest.PathInfo.Replace('/','.'),e.Message);
      if not (e is EHorseException) then
        raise EHorseException.New.Status(THTTPStatus.InternalServerError).Error('Erro na solicitação do recursso: '''+THorseRequest(req).RawWebRequest.PathInfo+''' Msg de erro: '+e.Message);
    end;
  end;
end;

procedure onPost(Req: THorseRequest; Res: THorseResponse);
begin
  try
    if BodyIsJsonObject(Req.Body) then
    begin
      with TMovimentoService.Create(ProcessSession(Req).ConnectionID) do
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
    if Req.Params.ContainsKey('id') then
    begin
       with TMovimentoService.Create(ProcessSession(Req).ConnectionID) do
       begin
         try
           User := ProcessSession(Req).User;
           delete(Req.Params.Items['id']);
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

{ TMovimentoController }

class procedure TMovimentoController.registerRoutes;
begin
  THorse.Get('/movimento',onBadRequest);
  //THorse.Post('/movimento',onBadRequest);
  //THorse.Put('/movimento',onBadRequest);
  THorse.Delete('/movimento',onBadRequest);

  THorse.Get('/movimento/:empresaid/:movtipoid',onGet);
  THorse.Get('/movimento/:empresaid/:movtipoid/last/:terminalid',onGet);
  THorse.Get('/movimento/:empresaid/:movtipoid/today',onGet);
  THorse.Get('/movimento/:empresaid/:movtipoid/:id',onGet);
  THorse.Get('/movimento/:empresaid/:movtipoid/:id/full',onGet);
  THorse.Get('/movimento/:empresaid/:movtipoid/emissao/:emissao',onGet);
  THorse.Get('/movimento/:empresaid/:movtipoid/numero/:numero',onGet);

  THorse.Patch('/movimento/:empresaid/:movtipoid/report',onGet);

  THorse.Post('/movimento/',onPost);
  THorse.Put('/movimento/',onPost);
  THorse.Delete('/movimento/:id',onDelete);
end;

end.
