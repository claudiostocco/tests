unit service.cfop;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, DB, Generics.Collections, StrUtils,
  (* Project units *)
  DataSet.Serialize,
  service.ServiceProvider, service.ServiceProviderCadastros, adapter.query.intf, connector.factory, adapter.json;

type

  { TCfopService }

  TCfopService = class(TServiceProviderCadastros)
    private
      FSQLSelect: String;
    public
      constructor Create(ConnectionId: String);
      procedure SetResumo;
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function delete(id: String): Boolean; overload; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
  end;

implementation

{ TCfopService }

constructor TCfopService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM CFOP ';
end;

procedure TCfopService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, DESCRICAO FROM CFOP ';
end;

function TCfopService.listAll(AParams: TDictionary<String, String>): Boolean;
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

    Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
             .Select(FSQLSelect+sWhere)
      	     .Open;
    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TCfopService.delete(id: String): Boolean;
begin
  Result := inherited delete(id,'CFOP');
end;

function TCfopService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue, 'CFOP');
end;

function TCfopService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, 'CFOP');
end;

end.
