unit controller.entidade;

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
  , Horse, Horse.Commons, controller.session, service.entidade;

  type
    { TEntidadeController }

    TEntidadeController = class
    private
    public
      class procedure registerRoutes;
    end;

implementation

procedure onGet(Req: THorseRequest; Res: THorseResponse);
begin
  try
    with TEntidadeService.Create(ProcessSession(Req).ConnectionID) do
    begin
      try
        User := ProcessSession(Req).User;
        //IncluiCancelado := Req.Query.ContainsKey('IncluirCancelado') and (Req.Query.Items['IncluirCancelado'] = '1');
        CanceledOnly := Req.Query.ContainsKey('canceled');
        SetFiltroEntidade(Req.PathInfo);
        if Req.Params.ContainsKey('entidadeid') then
        begin
          if Req.PathInfo.Contains('/email') then
            SetEmail('');
          if Req.PathInfo.Contains('/endereco') then
            SetEndereco('');
          if Req.PathInfo.Contains('/fone') then
            SetFone('');
        end else if Req.Params.ContainsKey('id') and Req.PathInfo.Contains('/entidade') then
          SetEntidade(Req.Params['id'])
        else
          SetEntidade('');

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
      with TEntidadeService.Create(ProcessSession(Req).ConnectionID) do
      begin
        try
          User := ProcessSession(Req).User;
          SetFiltroEntidade(Req.PathInfo);
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
    if Req.Params.ContainsKey('id') then
    begin
      with TEntidadeService.Create(ProcessSession(Req).ConnectionID) do
      begin
        try
          User := ProcessSession(Req).User;
          SetFiltroEntidade(Req.PathInfo);
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

{ TEntidadeController }

class procedure TEntidadeController.registerRoutes;
begin
  (* Rotas para endpoints de clientes *)
  THorse.Get('/cliente',onGet);
  THorse.Get('/cliente/:id',onGet);
  THorse.Get('/cliente/:id/entidade',onGet);
  THorse.Get('/cliente/nome/:nome',onGet);
  THorse.Get('/cliente/cnpj/:cnpj',onGet);
  THorse.Get('/cliente/:entidadeid/email',onGet);
  THorse.Get('/cliente/:entidadeid/endereco',onGet);
  THorse.Get('/cliente/:entidadeid/fone',onGet);
  THorse.Get('/cliente/:entidadeid/email/:id',onGet);
  THorse.Get('/cliente/:entidadeid/endereco/:id',onGet);
  THorse.Get('/cliente/:entidadeid/fone/:id',onGet);

  THorse.Post('/cliente',onPost);
  THorse.Post('/cliente/email',onPost);
  THorse.Post('/cliente/endereco',onPost);
  THorse.Post('/cliente/fone',onPost);
  THorse.Put('/cliente',onPost);
  THorse.Put('/cliente/email',onPost);
  THorse.Put('/cliente/endereco',onPost);
  THorse.Put('/cliente/fone',onPost);

  THorse.Delete('/cliente/:id',onDelete);
  THorse.Delete('/cliente/:entidadeid/email/:id',onDelete);
  THorse.Delete('/cliente/:entidadeid/endereco/:id',onDelete);
  THorse.Delete('/cliente/:entidadeid/fone/:id',onDelete);

  (* Rotas para endpoints de fornecedores *)
  THorse.Get('/fornecedor',onGet);
  THorse.Get('/fornecedor/:id',onGet);
  THorse.Get('/fornecedor/:id/entidade',onGet);
  THorse.Get('/fornecedor/nome/:nome',onGet);
  THorse.Get('/fornecedor/cnpj/:cnpj',onGet);
  THorse.Get('/fornecedor/:entidadeid/email',onGet);
  THorse.Get('/fornecedor/:entidadeid/endereco',onGet);
  THorse.Get('/fornecedor/:entidadeid/fone',onGet);
  THorse.Get('/fornecedor/:entidadeid/email/:id',onGet);
  THorse.Get('/fornecedor/:entidadeid/endereco/:id',onGet);
  THorse.Get('/fornecedor/:entidadeid/fone/:id',onGet);

  THorse.Post('/fornecedor',onPost);
  THorse.Post('/fornecedor/email',onPost);
  THorse.Post('/fornecedor/endereco',onPost);
  THorse.Post('/fornecedor/fone',onPost);
  THorse.Put('/fornecedor',onPost);
  THorse.Put('/fornecedor/email',onPost);
  THorse.Put('/fornecedor/endereco',onPost);
  THorse.Put('/fornecedor/fone',onPost);

  THorse.Delete('/fornecedor/:id',onDelete);
  THorse.Delete('/fornecedor/:entidadeid/email/:id',onDelete);
  THorse.Delete('/fornecedor/:entidadeid/endereco/:id',onDelete);
  THorse.Delete('/fornecedor/:entidadeid/fone/:id',onDelete);
end;

end.
