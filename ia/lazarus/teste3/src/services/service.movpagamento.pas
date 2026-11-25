unit service.movpagamento;

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

  { TMovPagamentoService }

  TMovPagamentoService = class(TServiceProviderCadastros)
    private
      FSQLSelect: String;
    public
      constructor Create(ConnectionId: String);
      procedure SetFull;
      procedure SetResumo;
      function listAll(AParams: TDictionary<String,String>): Boolean; override;
      function delete(AFilters: TDictionary<String, String>): Boolean; override;
      function insert(AValue: String): Boolean; override;
      function update(AValue: String): Boolean; override;
  end;

implementation

const SQL_MOD_NOME = '(SELECT DESCRICAO FROM MODALIDADE WHERE ID = MOVPAGAMENTO.MODALIDADEID) AS MODALIDADENOME ';

const SQL_ITEM = 'SELECT ID, ITEM, PARCELA, MODALIDADEID, '+SQL_MOD_NOME+', BAIXA, '+
                 'VENCIMENTO, VALOR, DESCONTO, ACRESCIMO, RECEBIDO, STATUS '+
                 'FROM MOVPAGAMENTO ';


{ TMovPagamentoService }

constructor TMovPagamentoService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM MOVPAGAMENTO ';
end;

procedure TMovPagamentoService.SetFull;
begin
  FSQLSelect := SQL_ITEM;
end;

procedure TMovPagamentoService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, ITEM, PARCELA, MODALIDADEID, '+SQL_MOD_NOME+', '+
  'VALOR, STATUS FROM MOVPAGAMENTO ';
end;

function TMovPagamentoService.listAll(AParams: TDictionary<String, String>): Boolean;
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

function TMovPagamentoService.delete(AFilters: TDictionary<String, String>): Boolean;
begin
  Result := inherited delete('MOVPAGAMENTO',AFilters);
end;

function TMovPagamentoService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue,'MOVPAGAMENTO');
end;

function TMovPagamentoService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, 'MOVPAGAMENTO');
end;

end.
