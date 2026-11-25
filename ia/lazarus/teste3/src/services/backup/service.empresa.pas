unit service.empresa;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, DB, Generics.Collections, StrUtils,
  (* Project units *)
  DataSet.Serialize,
  adapter.query.intf, connector.factory, adapter.json,
  service.ServiceProvider, service.commons;

type

  { TEmpresaService }

  TEmpresaService = class(TServiceProvider)
  private
    FSQLSelect: String;
  public
    constructor Create(ConnectionId: String);
    procedure SetResumo;
    function listAll(AParams: TDictionary<String,String>): Boolean; override;
    function insert(AValue: String): Boolean;
    function delete(id, AUser: String): Boolean; override;
    function update(id: String; AValue: String): Boolean; override;
    function setLogo(id: String; AValue: String): Boolean;
    function verifyKey(key: String): Boolean;
  end;

implementation

{ TEmpresaService }

constructor TEmpresaService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM EMPRESA ';
end;

procedure TEmpresaService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, RAZAO, CNPJ, NOMEEXIBICAO FROM EMPRESA ';
end;

function TEmpresaService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere: String;
    pCond: TPair<String,String>;
begin
  try
    sWhere := '';
    for pCond in AParams do
       sWhere := sWhere + IfThen(sWhere.IsEmpty,'',' AND ') + pCond.Key + ' = ''' + pCond.Value + '''';
    if not sWhere.IsEmpty then
      sWhere := 'WHERE '+sWhere;

    Query := TQueryFactory.New
             .Select(FSQLSelect+sWhere)
      	     .Open;
    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TEmpresaService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue,'EMPRESA');
end;

function TEmpresaService.delete(id, AUser: String): Boolean;
var iExc: Integer;
begin
  Result := True;
  iExc := TQueryFactory.New
                       .Exec('UPDATE EMPRESA SET STATUS = ''C'' WHERE ID = '''+id+'''')
                       .RowsAffected;
  if iExc > 0 then
    SetServiceResult('{}')
  else
    SetServiceResult('{"error": "Registro não foi cancelado!"}',THTTPStatus.NotModified);
end;

function TEmpresaService.update(id: String; AValue: String): Boolean;
begin
  Result := inherited update(id, AValue);
end;

function TEmpresaService.setLogo(id: String; AValue: String): Boolean;
begin
  Result := True;
  SetServiceResult('{"error": "Não implementado!"}',THTTPStatus.NotModified);
end;

function TEmpresaService.verifyKey(key: String): Boolean;
begin
  Result := False;
end;

end.
