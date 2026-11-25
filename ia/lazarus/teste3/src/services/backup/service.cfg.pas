unit service.cfg;

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

  { TCfgService }

  TCfgService = class(TServiceProvider)
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

{ TCfgService }

constructor TCfgService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM CFG ';
end;

procedure TCfgService.SetResumo;
begin
  FSQLSelect := 'SELECT VALOR FROM CFG ';
end;

function TCfgService.listAll(AParams: TDictionary<String, String>): Boolean;
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

function TCfgService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue,'CFG');
end;

function TCfgService.update(id: String; AValue: String): Boolean;
begin
  Result := inherited update(id, AValue);
end;

end.
