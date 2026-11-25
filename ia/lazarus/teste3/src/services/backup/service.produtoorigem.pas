unit service.produtoorigem;

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

  { TProdutoOrigemService }

  TProdutoOrigemService = class(TServiceProviderCadastros)
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

{ TProdutoOrigemService }

constructor TProdutoOrigemService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM PRODUTOORIGEM ';
end;

procedure TProdutoOrigemService.SetResumo;
begin
  FSQLSelect := 'SELECT CURRENT_CONNECTION, ID, DESCRICAO FROM PRODUTOORIGEM ';
end;

function TProdutoOrigemService.listAll(AParams: TDictionary<String, String>): Boolean;
var Query: IQuery;
    sWhere: String;
    pCond: TPair<String,String>;
begin
  try
    sWhere := '';
    for pCond in AParams do
    begin
      sWhere := IfThen(sWhere.IsEmpty,'',sWhere+' AND ');
      if pCond.Key = 'descricao' then
        sWhere := sWhere + 'UPPER(' + pCond.Key + ') CONTAINING ''' + pCond.Value.toUpper + ''' '
      else
        sWhere := sWhere + pCond.Key + ' = ''' + pCond.Value + ''' ';
    end;
    sWhere := IfThen(sWhere.IsEmpty,'','WHERE ');
    //sWhere := sWhere + IfThen(CanceledOnly,'STATUS = ''C'' ', 'STATUS <> ''C'' ');

    Query := TQueryFactory.New
             .Select(FSQLSelect+sWhere)
      	     .Open;
    SetServiceResult(Query.AsDataSet.ToJSONArrayString);
    Result := True;
  finally
  end;
end;

function TProdutoOrigemService.delete(id: String): Boolean;
begin
  Result := inherited delete(id,'PRODUTOORIGEM');
end;

function TProdutoOrigemService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue,'PRODUTOORIGEM');
end;

function TProdutoOrigemService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, 'PRODUTOORIGEM');
end;

end.
