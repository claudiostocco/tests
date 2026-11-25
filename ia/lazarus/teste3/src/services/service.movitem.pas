unit service.movitem;

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

  { TMovItemService }

  TMovItemService = class(TServiceProviderCadastros)
    private
      FSQLSelect: String;
    public
      constructor Create(ConnectionId: String);
      procedure SetFull;
      procedure SetResumo;
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      //function delete(id: String; AFilters: Array of String): Boolean; overload; override;
      function delete(AFilters: TDictionary<String, String>): Boolean; overload; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
  end;

implementation

const SQL_MOD_NOME = '(SELECT DESCRICAO FROM PRODUTO WHERE ID = MOVITEM.PRODUTOID) AS PRODUTONOME ';

const SQL_ITEM = 'SELECT ID, ITEM, PRODUTOID, CUSTO, QUANTIDADE, UNITARIO, SUBTOTAL, '+
                 'DESCONTO, ACRESCIMO, TOTAL, CFOPID, CSTID, TXICMS, BCICMS, VLICMS, '+
                 'STATUS, '+SQL_MOD_NOME+' FROM MOVITEM ';

{ TMovItemService }

constructor TMovItemService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM MOVITEM ';
end;

procedure TMovItemService.SetFull;
begin
  FSQLSelect := SQL_ITEM;
end;

procedure TMovItemService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, ITEM, PRODUTOID, QUANTIDADE, UNITARIO, SUBTOTAL, '+
                 'TOTAL, STATUS FROM MOVITEM ';
end;

function TMovItemService.listAll(AParams: TDictionary<String, String>): Boolean;
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

function TMovItemService.delete(AFilters: TDictionary<String, String>): Boolean;
begin
  Result := inherited delete('MOVITEM',AFilters);
end;

function TMovItemService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue,'MOVITEM');
end;

function TMovItemService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, 'MOVITEM');
end;

end.
