unit controller.produto;

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
  , service.produto
  //, service.produto.dm
  ;

  type
    { TProdutoController }

    TProdutoController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  try
    with TProdutoService.Create(ProcessSession(Req)) do
    //with TdmProdutoService.Create(ProcessSession(Req)) do
    begin
      try
        CanceledOnly := Req.Query.ContainsKey('canceled');
        if Req.Params.ContainsKey('id') then
        begin
          SetTabela(Req.PathInfo);
          if Req.PathInfo.Contains('full') then
            SetProduto(Req.Params['id']); (* Este método pode receber o parâmetro "EmpresaId" *)
        end else
          SetResumo('');  (* Este método pode receber o parâmetro "EmpresaId" *)

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
    if (Req.Body.Trim.IndexOf('{') = 0) and (Req.Body.Trim.Chars[Req.Body.Trim.Length-1] = '}') then
    begin
      with TProdutoService.Create(ProcessSession(Req)) do
      begin
        try
          SetTabela(Req.PathInfo);
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
       with TProdutoService.Create(ProcessSession(Req)) do
       begin
         try
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

{ TProdutoController }

class procedure TProdutoController.registerRoutes;
begin
  THorse.Get('/produto',onGet);
  THorse.Get('/produto/:id',onGet);
  THorse.Get('/produto/:id/full',onGet);
  THorse.Get('/produto/codigo/:codigo',onGet);
  THorse.Get('/produto/descricao/:descricao',onGet);
  THorse.Get('/produto/referencia/:referencia',onGet);

  THorse.Get('/produto/:id/preco',onGet);
  THorse.Get('/produto/:id/icms',onGet);
  THorse.Get('/produto/:id/piscofins',onGet);

  THorse.Post('/produto',onPost);
  THorse.Put('/produto',onPost);

  THorse.Post('/produto/preco',onPost);
  THorse.Put('/produto/preco',onPost);

  THorse.Post('/produto/icms',onPost);
  THorse.Put('/produto/icms',onPost);

  THorse.Post('/produto/piscofins',onPost);
  THorse.Put('/produto/piscofins',onPost);

  THorse.Delete('/produto/:id',onDelete);
end;

end.
