unit adapter.json;

{$ifdef FPC}
  {$mode Delphi}{$H+}
{$endif}

interface

uses
  {$ifdef FPC}
  Classes, SysUtils, fpjson, Generics.Collections
  {$else}
  System.Classes, System.SysUtils, System.JSON, System.Generics.Collections
  {$endif}
  ;

type
  {$ifdef FPC}
    TJSONValue = fpjson.TJSONData;
    TJSONObject = fpjson.TJSONObject;
    TJSONArray = fpjson.TJSONArray;
    TJSONString = fpjson.TJSONString;
    TJSONNumber = class(fpjson.TJSONNumber)
    private
      function GetAsDouble: Double;
    public
      property AsDouble: Double read GetAsDouble;
    end;
    TJSONFloat = fpjson.TJSONFloat;
    TJSONStringType = fpjson.TJSONStringType;
  {$else}
    TJSONFloat = Double;
    TJSONStringType = String;
    TJSONValue = System.JSON.TJSONValue;
    TJSONObject = System.JSON.TJSONObject;
    TJSONArray = System.JSON.TJSONArray;
    TJSONString = System.JSON.TJSONString;
    TJSONNumber = System.JSON.TJSONNumber;

    TJSONValueHelper = class helper for TJSONValue
    private
      function GetAsJSON: TJSONStringType;
    function GetAsFloat: Double;
    public
      property AsJSON : TJSONStringType read GetAsJSON;
      property AsFloat: Double read GetAsFloat;
    end;

    TJSONObjectHelper = class helper for TJSONObject
    private
      function GetElements(AName: String): TJSONValue;
      function GetItem(Index: Integer): TJSONValue;
      function GetNameOf(Index: Integer): TJSONStringType;
      procedure SetElements(AName: String; const Value: TJSONValue);
      procedure SetItem(Index: Integer; const Value: TJSONValue);
    function GetStrings(AName: String): TJSONStringType;
    procedure SetStrings(AName: String; const Value: TJSONStringType);
    function GetIntegers(AName: String): Integer;
    procedure SetIntegers(AName: String; const Value: Integer);
    public
      function Add(const AName: TJSONStringType; AValue: TJSONValue): Integer; overload;
      function Add(const AName, AValue: TJSONStringType): Integer; overload;
      function Add(const AName: TJSONStringType; AValue: Integer): Integer; overload;
      function Add(const AName: TJSONStringType; AValue: Int64): Integer; overload;
      function Add(const AName: TJSONStringType; AValue: TJSONFloat): Integer; overload;

      procedure Delete(Index: Integer); overload;
      procedure Delete(const AName: String); overload;
      function Find(Const AName: String): TJSONValue; overload;
//      function Find(Const AName: String; AType: TJSONType): TJSONValue; overload;
      function Get(Const AName: String) : Variant; overload;
      function Get(Const AName: String; ADefault: Variant) : Variant; overload;
      property Elements[AName: String]: TJSONValue read GetElements write SetElements; default;
      property Items[Index: Integer]: TJSONValue read GetItem write SetItem;
      property Names[Index: Integer]: TJSONStringType read GetNameOf;
      property Integers[AName : String] : Integer Read GetIntegers Write SetIntegers;
      property Strings[AName : String] : TJSONStringType Read GetStrings Write SetStrings;
    end;

  {$endif}

  function GetJSON(Const JSON: TJSONStringType; Const UseUTF8: Boolean = True): TJSONValue; overload;
  function GetJSON(Const JSON: TStream; Const UseUTF8: Boolean = True): TJSONValue; overload;
  function isJSONNumber(Value: TJSONValue): Boolean;
  function isJSONNull(Value: TJSONValue): Boolean;

implementation

function GetJSON(const JSON: TJSONStringType; const UseUTF8: Boolean): TJSONValue;
begin
  {$ifdef FPC}
    Result := fpjson.GetJSON(JSON,UseUTF8);
  {$else}
    try
      Result := TJSONObject.ParseJSONValue(JSON);
    except
      Result := nil;
    end;
  {$endif}
end;

function GetJSON(const JSON: TStream; const UseUTF8: Boolean): TJSONValue;
{$ifndef FPC}
var
  Buffer: String;
{$endif}
begin
  {$ifdef FPC}
    Result := fpjson.GetJSON(JSON,UseUTF8);
  {$else}
    try
      JSON.WriteData<String>(Buffer);
      Result := TJSONObject.ParseJSONValue(Buffer);
    except
      Result := nil;
    end;
  {$endif}
end;

function isJSONNumber(Value: TJSONValue): Boolean;
begin
  {$ifdef FPC}
    Result := Value.JSONType = jtNumber;
  {$else}
    Result := Value is TJSONNumber;
  {$endif}
end;

function isJSONNull(Value: TJSONValue): Boolean;
begin
  {$ifdef FPC}
    Result := Value.JSONType = jtNull;
  {$else}
    Result := Value is TJSONNull;
  {$endif}
end;

{$ifdef FPC}
{ TJSONNumber }

function TJSONNumber.GetAsDouble: Double;
begin
  Result := AsFloat;
end;
{$else}
{$endif}

{$ifndef FPC}
{ TJSONObjectHelper }

function TJSONObjectHelper.Add(const AName, AValue: TJSONStringType): Integer;
begin
  Result := 0;
  Self.AddPair(AName,AValue);
end;

function TJSONObjectHelper.Add(const AName: TJSONStringType; AValue: Integer): Integer;
begin
  Result := 0;
  Self.AddPair(AName,TJSONNumber.Create(AValue));
end;

function TJSONObjectHelper.Add(const AName: TJSONStringType; AValue: Int64): Integer;
begin
  Result := 0;
  Self.AddPair(AName,TJSONNumber.Create(AValue));
end;

function TJSONObjectHelper.Add(const AName: TJSONStringType; AValue: TJSONFloat): Integer;
begin
  Result := 0;
  Self.AddPair(AName,TJSONNumber.Create(AValue));
end;

procedure TJSONObjectHelper.Delete(const AName: String);
begin
  Self.RemovePair(AName).Free;
end;

procedure TJSONObjectHelper.Delete(Index: Integer);
var AName: String;
begin
  AName := Self.GetNameOf(Index);
  Self.Delete(AName);
end;

function TJSONObjectHelper.Add(const AName: TJSONStringType; AValue: TJSONValue): Integer;
begin
  Result := 0;
  Self.AddPair(AName,AValue);
end;

function TJSONObjectHelper.Find(const AName: String): TJSONValue;
begin
  Result := Self.FindValue(AName);
end;

function TJSONObjectHelper.Get(const AName: String): Variant;
begin
  Result := Self.GetValue(AName).Value;
end;

function TJSONObjectHelper.Get(const AName: String; ADefault: Variant): Variant;
var AValue: TJSONValue;
begin
  AValue := Self.GetValue(AName);
  if AValue <> nil then
    Result := AValue.Value
  else
    Result := ADefault;
end;

function TJSONObjectHelper.GetElements(AName: String): TJSONValue;
begin
  Result := Self.Values[AName];
end;

function TJSONObjectHelper.GetIntegers(AName: String): Integer;
begin
  Result := StrToIntDef(GetElements(AName).Value,0);
end;

function TJSONObjectHelper.GetItem(Index: Integer): TJSONValue;
begin
  Result := Self.Pairs[Index].JsonValue;
end;

function TJSONObjectHelper.GetNameOf(Index: Integer): TJSONStringType;
begin
  Result := Self.Pairs[Index].JsonString.Value;
end;

function TJSONObjectHelper.GetStrings(AName: String): TJSONStringType;
begin
  Result := GetElements(AName).Value;
end;

procedure TJSONObjectHelper.SetElements(AName: String; const Value: TJSONValue);
begin
  Self.Get(AName).JsonValue := Value;
end;

procedure TJSONObjectHelper.SetIntegers(AName: String; const Value: Integer);
begin
  SetElements(AName,TJSONNumber.Create(Value));
end;

procedure TJSONObjectHelper.SetItem(Index: Integer; const Value: TJSONValue);
begin
  Self.Pairs[Index].JsonValue := Value;
end;

procedure TJSONObjectHelper.SetStrings(AName: String; const Value: TJSONStringType);
begin
  SetElements(AName,TJSONString.Create(Value));
end;

{ TJSONValueHelper }

function TJSONValueHelper.GetAsFloat: Double;
begin
  Result := Self.AsType<Double>;
end;

function TJSONValueHelper.GetAsJSON: TJSONStringType;
begin
  Result := Self.ToJSON;
end;

{$endif}

end.

