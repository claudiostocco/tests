unit service.naturezaop;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  (* System Units *)
  Classes, SysUtils, Generics.Collections, StrUtils,
  (* Project units *)
  DataSet.Serialize,
  service.ServiceProvider, service.ServiceProviderCadastros, adapter.query.intf, connector.factory;

type

  { TNaturezaOpService }

  TNaturezaOpService = class(TServiceProviderCadastros)
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

{ TNaturezaOpService }

constructor TNaturezaOpService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM NATUREZAOP ';
end;

procedure TNaturezaOpService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, DESCRICAO, CFOPID,CFOPSTID, CFOPSERVID, CFOPCOMBID FROM NATUREZAOP ';
end;

function TNaturezaOpService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere: String;
    pCond: TPair<String,String>;
begin
  try
    sWhere := 'WHERE ';
    for pCond in AParams do
    begin
      if pCond.Key = 'descricao' then
        sWhere := sWhere + 'UPPER(' + pCond.Key + ') CONTAINING ''' + pCond.Value.toUpper + ''' AND '
      else
        sWhere := sWhere + pCond.Key + ' = ''' + pCond.Value + ''' AND ';
    end;
    sWhere := sWhere + IfThen(CanceledOnly,'STATUS = ''C'' ', 'STATUS <> ''C'' ');

    Query := TQueryFactory.New(dmConn,dmConn.dbConnection)
             .Select(FSQLSelect+sWhere)
      	     .Open;
    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TNaturezaOpService.delete(id: String): Boolean;
begin
  Result := inherited delete(id,'NATUREZAOP');
end;

function TNaturezaOpService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue,'NATUREZAOP');
end;

function TNaturezaOpService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, 'NATUREZAOP');
end;

end.
