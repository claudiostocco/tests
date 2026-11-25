unit utils;

{$ifdef FPC}
  {$mode Delphi}{$H+}
{$ifend}

interface

uses
  Classes, SysUtils, utils.parsejsontosql, adapter.json;

function BodyIsJsonObject(Value: String): Boolean;
function BodyIsJsonArray(Value: String): Boolean;
function ProcessJsonFields(Value: TJSONArray): String;
function ProcessJsonFilters(Value: TJSONArray): String;
function SqlStr(s: String): String;

implementation

function BodyIsJsonObject(Value: String): Boolean;
begin
  Result := (Value.Trim.IndexOf('{') = 0) and (Value.Trim.Chars[Value.Trim.Length-1] = '}')
end;

function BodyIsJsonArray(Value: String): Boolean;
begin
  Result := (Value.Trim.IndexOf('[') = 0) and (Value.Trim.Chars[Value.Trim.Length-1] = ']')
end;

function ProcessJsonFields(Value: TJSONArray): String;
begin
  Result := TParseJsonToSql.ProcessJsonFields(Value);
end;

function ProcessJsonFilters(Value: TJSONArray): String;
begin
  Result := TParseJsonToSql.ProcessJsonFilters(Value);
end;

function SqlStr(s: String): String;
begin
  Result := ''''+s.Replace('''', '''''', [rfReplaceAll])+'''';
end;

end.

