unit service.cpgto;

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

  { TCPgtoService }

  TCPgtoService = class(TServiceProviderCadastros)
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

const SQL_MOD_NOME = '(SELECT DESCRICAO FROM MODALIDADE WHERE ID = CPGTO.MODALIDADEID) AS MODALIDADEDESCRICAO ';

{ TCPgtoService }

constructor TCPgtoService.Create(ConnectionId: String);
begin
  inherited Create(ConnectionId);
  FSQLSelect := 'SELECT * FROM CPGTO ';
end;

procedure TCPgtoService.SetResumo;
begin
  FSQLSelect := 'SELECT ID, DESCRICAO, MODALIDADEID, '+SQL_MOD_NOME+', APRAZO, PARCELAS, DESTAQUE, NATUREZAOPID FROM CPGTO ';
end;

function TCPgtoService.listAll(AParams: TDictionary<String, String>): Boolean;
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

function TCPgtoService.delete(id: String): Boolean;
begin
  Result := inherited delete(id,'CPGTO');
end;

function TCPgtoService.insert(AValue: String): Boolean;
begin
  Result := inherited insert(AValue,'CPGTO');
end;

function TCPgtoService.update(AValue: String): Boolean;
begin
  Result := inherited update(AValue, 'CPGTO');
end;

end.
