unit utils.sqlvalues;

{$ifdef FPC}
  {$mode Delphi}{$H+}
{$ifend}

interface

uses
  Classes, SysUtils, StrUtils, Generics.Collections;

type
  { TSQLValues }

  TSQLValues = record
    Table: String;
    Fields: String;
    Join: String;
    Where: String;
    OrderBy: String;
    GroupBy: String;
    function Select(Full: Boolean = False): String;
    function Group: String;
    function Order: String;
  end;

  function MakeWhere(AParams: TDictionary<String, String>): String;

implementation

function MakeWhere(AParams: TDictionary<String, String>): String;
var pCond: TPair<String,String>;
    sTmp: String;
begin
  Result := '';
  for pCond in AParams do
  begin
    sTmp := pCond.Key + ' = ''' + pCond.Value + '''';
    Result := Result + IfThen(Result.IsEmpty,'',' AND ') + sTmp;
  end;
  if not Result.IsEmpty then
    Result := 'WHERE '+Result;
end;

function TSQLValues.Select(Full: Boolean = False): String;
begin
  Result := 'SELECT '+Fields+' FROM '+Table+' ';
  if Full then
    Result := Result+' '+Join+' '+Where+' '+Group+' '+Order;
end;

function TSQLValues.Group: String;
begin
  if GroupBy.IsEmpty then
    Result := ''
  else
    Result := ' GROUP BY '+GroupBy;
end;

function TSQLValues.Order: String;
begin
  if OrderBy.IsEmpty then
    Result := ''
  else
    Result := ' ORDER BY '+OrderBy;
end;

end.

