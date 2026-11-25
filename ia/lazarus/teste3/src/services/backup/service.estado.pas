unit service.estado;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, DB, Generics.Collections, StrUtils,
  (* Project units *)
  DataSet.Serialize,
  service.ServiceProvider, adapter.query.intf, connector.factory, adapter.json;

type

  { TEstadoService }

  TEstadoService = class(TServiceProvider)
    private
      FSQLSelect: String;
    public
      constructor Create(ConnectionId: String);
      procedure SetResumo;
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function insert(AValue: String): Boolean;
      function update(id: String; AValue: String): Boolean; override;
  end;

implementation

{ TEstadoService }

constructor TEstadoService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM ESTADO ';
end;

procedure TEstadoService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, UF, NOME FROM ESTADO ';
end;

function TEstadoService.listAll(AParams: TDictionary<String, String>): Boolean;
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

function TEstadoService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue,'ESTADO');
end;

function TEstadoService.update(id: String; AValue: String): Boolean;
begin
  Result := inherited update(id, AValue);
end;

end.
