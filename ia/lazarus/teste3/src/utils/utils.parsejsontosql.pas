unit utils.parsejsontosql;

{$ifdef FPC}
  {$mode ObjFPC}{$H+}
{$endif}

interface

uses
  Classes, SysUtils, DateUtils, adapter.json, logfile.logger;

type
  TOperatorType = record
    OperatorType: String;
    Sql: String;
  end;

  const AOperatorList: Array of TOperatorType = (
    (OperatorType: '$gt'; Sql: '>'),
    (OperatorType: '$gte'; Sql: '>='),
    (OperatorType: '$lt'; Sql: '<'),
    (OperatorType: '$lte'; Sql: '<='),
    (OperatorType: '$not'; Sql: 'not'),
    (OperatorType: '$or'; Sql: 'or')
  );

type
  { TParseJsonToSql }
  TParseJsonToSql = class
  private
    class function ProcessValue(AValue: TJSONValue): String;
    class function OperatorToSql(AOperator: String): String;
    class function ProcessSpecialOperator(AField: String; AOp: TJSONObject): String;
  protected
  public
    class function ProcessJsonFields(Value: TJSONArray): String;
    class function ProcessJsonFilters(Value: TJSONArray): String;
  end;

implementation

{ TParseJsonToSql }

class function TParseJsonToSql.ProcessValue(AValue: TJSONValue): String;
begin
  if AValue is TJSONNumber then
    Result := AValue.AsString
  else
    Result := ''''+AValue.AsString+'''';
end;

class function TParseJsonToSql.OperatorToSql(AOperator: String): String;
var
  i: Integer;
begin
  Result := '';
  for i := Low(AOperatorList) to High(AOperatorList) do
  begin
    if AOperatorList[i].OperatorType = AOperator then
    begin
      Result := AOperatorList[i].Sql;
      Exit;
    end;
  end;
end;

class function TParseJsonToSql.ProcessSpecialOperator(AField: String; AOp: TJSONObject): String;
var
  i: Integer;
  sOp, sValue, sSQLFilter: String;
  dtValue: TDateTime;
begin
  Result := '';
  for i := 0 to AOp.Count -1 do
  begin
    sOp := AOp.Names[i];
    if AOp.Items[i] is TJSONObject then
      sValue := ProcessSpecialOperator(AField,AOp.Items[i] as TJSONObject)
    else
      sValue := AOp.Items[i].AsString;

    if sOp.Equals('$not') then
      sSQLFilter := Format('%s %s %s %s',[OperatorToSql(sOp),AField,'=',sValue])
    else
    begin
      if TryISO8601ToDate(sValue,dtValue) then
      begin
        try
          sValue := FormatDateTime('dd.mm.yyyy hh:nn:ss',dtValue);
          if sValue.EndsWith('00:00:00') then
            sValue := sValue.Substring(0,10);
        except
        end;
      end;
      sSQLFilter := Format('%s %s ''%s''',[AField,OperatorToSql(sOp),sValue]);
    end;

    if not Result.IsEmpty then
      Result := Result+' AND '+sSQLFilter
    else
      Result := sSQLFilter;
  end;
end;

class function TParseJsonToSql.ProcessJsonFields(Value: TJSONArray): String;
var i: Integer;
begin
  if Value.Count > 0 then
  begin
    Result := '';
    for i := 0 to Value.Count - 1 do
    begin
      if not Result.IsEmpty then
        Result := Result+', '+Value.Items[i].AsString
      else
        Result := Value.Items[i].AsString;
    end;
  end else
    Result := '';
end;

class function TParseJsonToSql.ProcessJsonFilters(Value: TJSONArray): String;
var jsonObj: TJSONObject;
    i: Integer;
    sSQLFilter, sField, sTmp: String;
begin
  if Value.Count > 0 then
  begin
    Result := '';
    for i := 0 to Value.Count - 1 do
    begin
      jsonObj := Value.Items[i] as TJSONObject;
      sField := jsonObj.Names[0];
      if jsonObj.Items[0] is TJSONObject then
        sSQLFilter := ProcessSpecialOperator(sField,jsonObj.Items[0] as TJSONObject)
      else if jsonObj.Items[0] is TJSONArray then
      begin
        sTmp := (jsonObj.Items[0] as TJSONArray).AsJSON;
        sSQLFilter := sField+' IN '+sTmp.Replace('[','(')
                                                  .Replace(']',')')
                                                  .Replace('"','''',[rfReplaceAll]);
      end
      else
        sSQLFilter := sField+' = '+ProcessValue(jsonObj.Items[0]);

      if not Result.IsEmpty then
        Result := Result+' AND '+sSQLFilter
      else
        Result := sSQLFilter;
    end;
  end else
    Result := '';
end;

end.

