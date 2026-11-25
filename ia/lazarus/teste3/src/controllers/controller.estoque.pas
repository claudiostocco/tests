unit controller.estoque;

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
  , service.estoque;

  type
    { TEstoqueController }

    TEstoqueController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  try
    with TEstoqueService.Create(ProcessSession(Req).ConnectionID) do
    begin
      try
        (* filter=ltz               *
         *   ltz: less than zero    *
         *   etz: equal to zero     *
         *   gtz: greater than zero *
         * canceled=y               *)

        CanceledOnly := Req.Query.ContainsKey('canceled');
        if Req.Query.ContainsKey('filter') then
          SetFilter(Req.Query.Items['filter']);
        if Req.PathInfo.Contains('empresa') then
          SetByCompany;

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
    if (Req.Body.Trim.IndexOf('[') = 0) and (Req.Body.Trim.Chars[Req.Body.Trim.Length-1] = ']') then
    begin
       with TEstoqueService.Create(ProcessSession(Req).ConnectionID) do
       begin
         try
           User := ProcessSession(Req).User;
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

{ TEstoqueController }

class procedure TEstoqueController.registerRoutes;
begin
  THorse.Get('/estoque',onGet);
  THorse.Get('/estoque/:produtoid',onGet);
  THorse.Get('/estoque/:produtoid/:empresaid',onGet);
  THorse.Get('/estoque/empresa/:empresaid',onGet);
  THorse.Get('/estoque/empresa',onGet);

  THorse.Post('/estoque',onPost);
end;

end.
