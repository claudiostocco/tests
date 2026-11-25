unit service.commons;

{$ifdef FPC}
  {$mode delphi}{$H+}
{$endif}

{$Warnings OFF}

interface

uses
  {$ifdef FPC}
  Classes, SysUtils
  {$else}
  System.Classes, System.SysUtils
  {$endif}
  , Horse, Horse.Commons;

type
  THTTPStatus = Horse.THTTPStatus;
  EHttpException = Horse.EHorseException;

  TServiceResponseStatus = (
    Undefined = 0,
    OK = 1,
    PrimaryKeyError = 10,
    CanceledError = 11,
    ProductUniqueKeyError = 12,
    IdNotDefined = 13
  );

  const aInformationStatus: Array of TServiceResponseStatus = [PrimaryKeyError, CanceledError, ProductUniqueKeyError];

type
  { TServiceResponse }
  TServiceResponse = class
  private
    class procedure RaiseHttpError(Status: THTTPStatus; Code: TServiceResponseStatus; Message: String; MessageType: TMessageType = TMessageType.Error);
    class function Msg(Value: String; DefValue: String): String;
    class function isInformationStatus(Code: TServiceResponseStatus): Boolean;
  public
    class procedure Error(Status: THTTPStatus; Message: UTF8String); overload;
    class procedure Error(Status: THTTPStatus; Code: TServiceResponseStatus; Message: UTF8String = ''); overload;
  end;

implementation

{ TServiceResponse }

class procedure TServiceResponse.Error(Status: THTTPStatus; Code: TServiceResponseStatus; Message: UTF8String = '');
var sMessage: UTF8String;
    MsgType: TMessageType;
begin
  if isInformationStatus(Code) then
    MsgType := TMessageType.Information
  else
    MsgType := TMessageType.Error;

  case Code of
     OK: sMessage := '';
     PrimaryKeyError: sMessage := 'Registro já cadastrado!';
     CanceledError: sMessage := 'Registro está cancelado!';
     ProductUniqueKeyError: sMessage := 'Já existe produto com descrição identica';
     IdNotDefined: sMessage := 'Identificador do registro não informado!';
     else
       sMessage := 'Erro desconhecido';
  end;
  if sMessage <> '' then
    RaiseHttpError(Status,Code,Msg(Message,sMessage),MsgType);
end;

class procedure TServiceResponse.RaiseHttpError(Status: THTTPStatus; Code: TServiceResponseStatus; Message: String; MessageType: TMessageType);
begin
  raise EHttpException.New
                      .Status(Status)
                      .&Type(MessageType)
                      .Code(Integer(Code))
                      .Error(Message);
end;

class function TServiceResponse.Msg(Value: String; DefValue: String): String;
begin
  if Value.IsEmpty then
    Result := DefValue
  else
    Result := Value;
end;

class function TServiceResponse.isInformationStatus(Code: TServiceResponseStatus): Boolean;
var
  i: Integer;
begin
  for i := Low(aInformationStatus) to High(aInformationStatus) do
  begin
    Result := aInformationStatus[i] = Code;
    if Result then Break;
  end;
end;

class procedure TServiceResponse.Error(Status: THTTPStatus; Message: UTF8String);
begin
  Error(Status, TServiceResponseStatus.Undefined, Message);
end;

end.
