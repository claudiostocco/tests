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
      FSQLOrder: String;
    public
      constructor Create(ConnectionId: String);
      procedure SetResumo;
      procedure SetColecao;
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
  FSQLOrder := '';
end;

procedure TCfgService.SetResumo;
begin
  FSQLSelect := 'SELECT VALOR FROM CFG ';
  FSQLOrder := ' ORDER BY TMCODIGO DESC';
end;

procedure TCfgService.SetColecao;
begin
  FSQLSelect := 'SELECT TMCODIGO, TIPO, NOME, VALOR FROM CFG ';
  FSQLOrder := ' ORDER BY TMCODIGO DESC';
end;

function TCfgService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere, sTmp: String;
    pCond: TPair<String,String>;
begin
  try
    sWhere := '';
    for pCond in AParams do
    begin
      if pCond.Key.Equals('proprietario') or pCond.Key.Equals('tmcodigo') then
        sTmp := '(' + pCond.Key + ' = 0 OR ' + pCond.Key + ' = ' + pCond.Value + ')'
      else
        sTmp := pCond.Key + ' = ''' + pCond.Value + '''';
      sWhere := sWhere + IfThen(sWhere.IsEmpty,'',' AND ') + sTmp;
    end;
    if not sWhere.IsEmpty then
      sWhere := 'WHERE '+sWhere;

    Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
             .Select(FSQLSelect+sWhere+FSQLOrder)
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
