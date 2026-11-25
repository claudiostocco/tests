unit service.ServiceProviderCadastros;

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
  , Generics.Collections
  , adapter.json
  , connection, adapter.query.intf, connector.factory
  , service.ServiceProvider, service.commons;

type
  { TServiceProviderCadastros }

  TServiceProviderCadastros = class(TServiceProvider)
  public
    function insert(AValue, ATableName: String): Boolean; overload; override;
    //function update(AValue, ATableName: String): Boolean; overload; override;
  end;

implementation

{ TServiceProviderCadastros }

function TServiceProviderCadastros.insert(AValue, ATableName: String): Boolean;
var jsonValue: TJSONObject;
    sID: String;
begin
  try
    try
      jsonValue := GetJSON(AValue) as TJSONObject;
      sID := jsonValue.Strings['id'];
      if sID.IsEmpty then
        raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Identificador não informado!');
    finally
      jsonValue.Free;
    end;
  except on E: Exception do
    raise EHttpException.New.Status(THTTPStatus.BadRequest).Error('Erro ao processar corpo da requisição: '+E.Message);
  end;

  try
    ReturningFields := '*';
    Result := inherited insert(AValue, ATableName);
  except
    with TQueryFactory.New
                      .Select('SELECT ID, '+StatusFieldName+' FROM '+ATableName+' WHERE ID = '''+sID+'''')
                      .Open do
    begin
      if (not AsDataSet.IsEmpty) and (AsDataSet.FieldByName('ID').AsString = sID) then
      begin
        if AsDataSet.FieldByName(StatusFieldName).AsString = 'C' then
          TServiceResponse.Error(THTTPStatus.BadRequest,TServiceResponseStatus.CanceledError)
        else
          TServiceResponse.Error(THTTPStatus.BadRequest,TServiceResponseStatus.PrimaryKeyError);
      end else
        raise;
    end;
  end;
end;

//function TServiceProviderCadastros.update(AValue, ATableName: String): Boolean;
//var jsonValue: TJSONObject;
//begin
//  try
//    jsonValue := GetJSON(AValue) as TJSONObject;
//    if (jsonValue.Find('uinseriu') <> nil) then
//      jsonValue.Delete('uinseriu');
//    if not User.IsEmpty then
//      jsonValue.Strings['ualterou'] := User;
//    AValue := jsonValue.AsJSON;
//  finally
//    jsonValue.Free;
//  end;
//  Result := inherited update(AValue, ATableName);
//end;

end.

