unit adapter.query.impl;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
    (* System Units *)
    Classes, SysUtils, StrUtils, Variants, DateUtils, DB, Generics.Collections,
    (* Project units *)
    adapter.query.intf, adapter.json, Utils;

type

  { TChildQuery }

  TChildQuery = Class(TInterfacedObject, IChildQuery)
    private
      FMasterField: String;
      FLinkedField: String;
      FQuery: IQuery;
      function GetLinkedField: String;
      function GetMasterField: String;
      function GetQuery: IQuery;
      constructor Create(AMasterField, ALinkedField: String; AQuery: IQuery);
    public
      class function New(MasterField, LinkedField: String; Query: IQuery): IChildQuery;
      property MasterField: String read FMasterField;
      property LinkedField: String read FLinkedField;
      property Query: IQuery read FQuery;
  end;

  { TAbstractQuery }
  TAbstractQuery = class(TInterfacedObject, IQuery)
  protected
    FDctUtf8Win1252: TDictionary<Integer,Char>;
    FInternalDataSet: TDataSet;
    FInsertedRecords: Int64;
    FRowsAffected: Int64;
    FDataSource: TDataSource;
    FReturningFields: String;
    FReturnedFields: TFields;
    function GetConnectionCharSet: String; virtual; abstract;
  private
    function GetDataSource: TDataSource;
    function GetInsertedRecords: Int64;
    function GetReturnedFields: TFields;
    function GetRowsAffected: Int64;
    function GetIsEmpty: Boolean;
    function GetEOF: Boolean;
    {$ifdef windows}
    procedure FillCharSetDictionary;
    function Utf8ToWin1252(const Source: String): String;
    {$endif}
    function InternalInsertJSON(TableName: String; Value: TJSONValue; AddFieldsChild: TList<String>; upsert: Boolean): Integer;
  public
    {$ifdef windows}
    constructor Create(AOwner: TComponent); virtual;
    {$endif}
    function AsDataSet: TDataSet;
    procedure CommitOrApplyUpdates(Dataset: TDataSet = nil); virtual; abstract;
    function Exec(SQL: String): IQuery; overload; virtual;
    function Exec: IQuery; overload; virtual; abstract;
    function Insert(SQL: String; UpSert: Boolean=False): IQuery;
    function InsertJSON(const Value: String; upsert: Boolean = False): IQuery; overload;
    function InsertJSON(const Value: String; TableName: String = ''; upsert: Boolean = False): IQuery; overload;
    function InsertJSON(const Value: String; AddFieldsChild: TList<String>; TableName: String = ''; upsert: Boolean = False): IQuery; overload;
    procedure LinkToDataSource(MasterField, LinkedField: String; MasterSource: TDataSource); virtual; abstract;
    function Open: IQuery; overload;
    function Open(SQL: String): IQuery; overload;
    function Select(SQL: String): IQuery; virtual; abstract;
    function SetChildQuery(MasterField, LinkedField: String; ChildQuery: IQuery): IQuery;
    function GetConnection: TComponent; virtual; abstract;
    procedure SetConnection(Connection: TComponent); virtual; abstract;
    function SetFieldMask(Field: String; Mask: String; TypeMask: TTypeFieldMaskSet): IQuery;
    function SetParamByName(Param: String; Value: Variant): IQuery; virtual; abstract;
    function SetParamsOfDict(Params: TDictionary<String, Variant>): IQuery; overload;
    function SetParamsOfDict(Params: TDictionary<String, String>): IQuery; overload;
    function ParamExists(Name: String): Boolean; virtual; abstract;
    function ParamValue(Param: String): Variant; virtual; abstract;
    function SetQueryName(Name: String): IQuery;
    function SetReturningFields(const Fields: Array of String): IQuery;
    function Update(SQL: String): IQuery;
    function FieldByName(Name: String): TField;
    function SetFieldByName(Name: String; Value: Variant): IQuery;
    function Append: IQuery;
    function Edit: IQuery;
    function Cancel: IQuery;
    function Post: IQuery;
    function GenerateID(Generator: String): Integer;
    function GetCFG(Category, Name, Default: String): String; overload;
    function ResultSql(SQL: String; Default: Variant): Variant; overload;
    function ResultSql(SQL: String): Variant; overload;
    procedure Log(EventId, OriginId: Integer; OriginTable, Message: String);
  published
    property ConnectionCharSet: String read GetConnectionCharSet;
    property DataSource: TDataSource read GetDataSource;
    property InsertedRecords: Int64 read GetInsertedRecords;
    property RowsAffected: Int64 read GetRowsAffected;
    property ReturnedFields: TFields read GetReturnedFields;
    property IsEmpty: Boolean read GetIsEmpty;
    property EOF: Boolean read GetEOF;
  end;

implementation

uses connector.factory;

{ TChildQuery }

constructor TChildQuery.Create(AMasterField, ALinkedField: String; AQuery: IQuery);
begin
  FMasterField := AMasterField;
  FLinkedField := ALinkedField;
  FQuery := AQuery;
end;

function TChildQuery.GetLinkedField: String;
begin
  Result := FLinkedField;
end;

function TChildQuery.GetMasterField: String;
begin
  Result := FMasterField;
end;

function TChildQuery.GetQuery: IQuery;
begin
  Result := FQuery;
end;

class function TChildQuery.New(MasterField, LinkedField: String; Query: IQuery): IChildQuery;
begin
  Result := Create(MasterField, LinkedField, Query);
end;

{ TAbstractQuery }

function TAbstractQuery.AsDataSet: TDataSet;
begin
   Result := FInternalDataSet;
end;

function TAbstractQuery.Exec(SQL: String): IQuery;
begin
   Result := Update(SQL).Exec;
end;

function TAbstractQuery.Insert(SQL: String; UpSert: Boolean): IQuery;
VAR sReturningFields: String;
begin
  if Length(FReturningFields) > 0 then
    sReturningFields := ' RETURNING '+FReturningFields
  else
    sReturningFields := '';

  if UpSert then SQL := 'UPDATE OR '+SQL;
  Result := Select(SQL+sReturningFields);
end;

function TAbstractQuery.InsertJSON(const Value: String; upsert: Boolean): IQuery;
begin
  Result := InsertJSON(Value,nil,'',upsert);
end;

function TAbstractQuery.InsertJSON(const Value: String; TableName: String; upsert: Boolean): IQuery;
begin
   Result := InsertJSON(Value,nil,TableName,upsert);
end;

function TAbstractQuery.InsertJSON(const Value: String; AddFieldsChild: TList<String>; TableName: String; upsert: Boolean): IQuery;
var jV, jContentTable, jValue: TJSONValue;
    sTableName: String;
    i: Integer;
    //bTransactionStarted: Boolean;
begin
  try
    Result := Self;
    FInsertedRecords := 0;

    //if Transaction = nil then
    //begin
    //  StartTransaction;
    //  bTransactionStarted := True;
    //end else
    //  bTransactionStarted := False;

    jValue := GetJSON(Value);
    if jValue <> nil then
    begin
      sTableName := '';
      if TableName.IsEmpty then
      begin
        if (jValue is TJSONObject) and ((jValue as TJSONObject).Items[0] <> nil) then
          sTableName := (jValue as TJSONObject).Names[0]
        else
          raise Exception.Create('Conteúdo do JSON não é um par "tabela": {valores} válido!');
        jContentTable := (jValue as TJSONObject).Items[0];
      end else
      begin
        sTableName := TableName;
        jContentTable := jValue;
      end;
      if (jContentTable <> nil) and (not sTableName.IsEmpty) then
      begin
        if jContentTable is TJSONArray then
        begin
          for i := 0 to (jContentTable as TJSONArray).Count-1 do
          begin
            jV := (jContentTable as TJSONArray).Items[i];
            FInsertedRecords := FInsertedRecords+InternalInsertJSON(sTableName,jV,AddFieldsChild,upsert);
          end;
        end else
          FInsertedRecords := InternalInsertJSON(sTableName,jContentTable,AddFieldsChild,upsert);
      end;
    end else
      raise Exception.Create('Conteúdo do JSON inválido!');

    //if bTransactionStarted and (Transaction <> nil) then
    //  CommitTransaction;
    //Ver como implementar RollBack em caso de erro.

  finally
    FreeAndNil(jValue);
  end;
end;

function TAbstractQuery.Open: IQuery;
begin
   FInternalDataSet.Open;
   Result := Self;
end;

function TAbstractQuery.Open(SQL: String): IQuery;
begin
   Result := Select(SQL).Open;
end;

function TAbstractQuery.SetChildQuery(MasterField, LinkedField: String; ChildQuery: IQuery): IQuery;
begin
  ChildQuery.LinkToDataSource(MasterField,LinkedField,Self.DataSource);
  Result := Self;
end;

function TAbstractQuery.SetFieldMask(Field: String; Mask: String;
  TypeMask: TTypeFieldMaskSet): IQuery;
begin
   if tmEditMask in TypeMask then
      FInternalDataSet.FieldByName(Field).EditMask := Mask;
   (* Somente para campos numéricos *)
   if tmDisplayFormat in TypeMask then
      (FInternalDataSet.FieldByName(Field) as TNumericField).DisplayFormat := Mask;
   if tmEditFormat in TypeMask then
      (FInternalDataSet.FieldByName(Field) as TNumericField).EditFormat := Mask;

   Result := Self;
end;

function TAbstractQuery.SetParamsOfDict(Params: TDictionary<String, Variant>): IQuery;
var pCond: TPair<String, Variant>;
begin
  for pCond in Params do
    if ParamExists(pCond.Key) then
      SetParamByName(pCond.Key,pCond.Value);
  Result := Self;
end;

function TAbstractQuery.SetParamsOfDict(Params: TDictionary<String, String>): IQuery;
var pCond: TPair<String, String>;
begin
  for pCond in Params do
    if ParamExists(pCond.Key) then
      SetParamByName(pCond.Key,pCond.Value);
  Result := Self;
end;

function TAbstractQuery.SetQueryName(Name: String): IQuery;
begin
  FInternalDataSet.Name := Name;
  Result := Self;
end;

function TAbstractQuery.SetReturningFields(const Fields: array of String): IQuery;
begin
  FReturningFields := ''.Join(',',Fields);
  Result := Self;
end;

function TAbstractQuery.Update(SQL: String): IQuery;
begin
   Result := Select(SQL);
end;

function TAbstractQuery.GetDataSource: TDataSource;
begin
  if not Assigned(FDataSource) then
  begin
    FDataSource := TDataSource.Create(Self.AsDataSet.Owner);
    FDataSource.DataSet := Self.AsDataSet;
  end;
  Result := FDataSource;
end;

function TAbstractQuery.GetInsertedRecords: Int64;
begin
  Result := FInsertedRecords;
end;

function TAbstractQuery.GetReturnedFields: TFields;
begin
  Result := FReturnedFields;
end;

function TAbstractQuery.GetRowsAffected: Int64;
begin
  Result := FRowsAffected;
end;

function TAbstractQuery.GetIsEmpty: Boolean;
begin
  Result := AsDataSet.IsEmpty;
end;

function TAbstractQuery.GetEOF: Boolean;
begin
  Result := AsDataSet.EOF;
end;

function TAbstractQuery.FieldByName(Name: String): TField;
begin
  Result := AsDataSet.FieldByName(Name);
end;

function TAbstractQuery.SetFieldByName(Name: String; Value: Variant): IQuery;
var a: String;
begin
  if not (AsDataSet.State in dsEditModes) then
  begin
    if IsEmpty
    then Append
    else Edit;
  end;

  FieldByName(Name).Value := Value;
  Result := Self;
end;

function TAbstractQuery.Edit: IQuery;
begin
  AsDataSet.Edit;
  Result := Self;
end;

function TAbstractQuery.Append: IQuery;
begin
  AsDataSet.Append;
  Result := Self;
end;

function TAbstractQuery.Cancel: IQuery;
begin
  AsDataSet.Cancel;
  Result := Self;
end;

function TAbstractQuery.Post: IQuery;
begin
  AsDataSet.Post;
  Result := Self;
end;

function TAbstractQuery.GenerateID(Generator: String): Integer;
var Query: IQuery;
begin
  Result := StrToInt(VarToStr(ResultSql('SELECT GEN_ID('+Generator+', 1) AS ID FROM RDB$DATABASE')));
end;

function TAbstractQuery.GetCFG(Category, Name, Default: String): String;
begin
  Result := ResultSql('SELECT VALOR FROM CFG WHERE TIPO = '+SqlStr(Category)+' AND NOME = '+SqlStr(Name), Default);
end;

function TAbstractQuery.ResultSql(SQL: String): Variant;
begin
  {$IFDEF FPC}
    Result := ResultSql(SQL, nil);
  {$ELSE}
    Result := ResultSql(SQL, '');
  {$ENDIF}
end;

function TAbstractQuery.ResultSql(SQL: String; Default: Variant): Variant;
var Query: IQuery;
begin
  Query := TQueryFactory.New(AsDataSet.Owner, GetConnection)
           .Select(SQL)
           .Open;

  with Query.AsDataSet.Fields[0] do
  begin
    if IsNull then Result := Default
    else Result := Value;
  end;
end;

procedure TAbstractQuery.Log(EventId, OriginId: Integer; OriginTable, Message: String);
begin
  try
    TQueryFactory.New(AsDataSet.Owner, GetConnection)
    .Select(
      'UPDATE OR INSERT INTO LOGEVENTO (ID, IDEVENTO, IDORIGEM, TABELA, DATA, MSG) ' +
      'VALUES (0, '+IntToStr(EventId)+', '+IntToStr(OriginId)+', '+SqlStr(OriginTable)+', CURRENT_TIMESTAMP, '+SqlStr(Message)+')'
    )
    .Exec;
  except
  end;
end;

{$ifdef windows}
procedure TAbstractQuery.FillCharSetDictionary;
begin
  FDctUtf8Win1252 := TDictionary<Integer,Char>.Create;
  FDctUtf8Win1252.Add(128,#192); // À
  FDctUtf8Win1252.Add(129,#193); // Á
  FDctUtf8Win1252.Add(130,#194); // Â
  FDctUtf8Win1252.Add(131,#195); // Ã
  FDctUtf8Win1252.Add(132,#196); // Ä
  FDctUtf8Win1252.Add(134,#199); // Ç
  FDctUtf8Win1252.Add(136,#200); // È
  FDctUtf8Win1252.Add(137,#201); // É
  FDctUtf8Win1252.Add(138,#202); // Ê
  FDctUtf8Win1252.Add(139,#203); // Ë
  FDctUtf8Win1252.Add(140,#204); // Ì
  FDctUtf8Win1252.Add(141,#205); // Í
  FDctUtf8Win1252.Add(142,#206); // Î
  FDctUtf8Win1252.Add(143,#207); // Ï
  FDctUtf8Win1252.Add(146,#210); // Ò
  FDctUtf8Win1252.Add(147,#211); // Ó
  FDctUtf8Win1252.Add(148,#212); // Ô
  FDctUtf8Win1252.Add(149,#213); // Õ
  FDctUtf8Win1252.Add(150,#214); // Ö
  FDctUtf8Win1252.Add(153,#217); // Ù
  FDctUtf8Win1252.Add(154,#218); // Ú
  FDctUtf8Win1252.Add(155,#219); // Û
  FDctUtf8Win1252.Add(156,#220); // Ü
  FDctUtf8Win1252.Add(160,#224); // à
  FDctUtf8Win1252.Add(161,#225); // á
  FDctUtf8Win1252.Add(162,#226); // â
  FDctUtf8Win1252.Add(163,#227); // ã
  FDctUtf8Win1252.Add(164,#228); // ä
  FDctUtf8Win1252.Add(167,#231); // ç
  FDctUtf8Win1252.Add(168,#232); // è
  FDctUtf8Win1252.Add(169,#233); // é
  FDctUtf8Win1252.Add(170,#234); // ê
  FDctUtf8Win1252.Add(171,#235); // ë
  FDctUtf8Win1252.Add(172,#236); // ì
  FDctUtf8Win1252.Add(173,#237); // í
  FDctUtf8Win1252.Add(174,#238); // î
  FDctUtf8Win1252.Add(175,#239); // ï
  FDctUtf8Win1252.Add(176,#240); // ð
  FDctUtf8Win1252.Add(177,#241); // ñ
  FDctUtf8Win1252.Add(178,#242); // ò
  FDctUtf8Win1252.Add(179,#243); // ó
  FDctUtf8Win1252.Add(180,#244); // ô
  FDctUtf8Win1252.Add(181,#245); // õ
  FDctUtf8Win1252.Add(182,#246); // ö
  FDctUtf8Win1252.Add(184,#248); // ø
  FDctUtf8Win1252.Add(185,#249); // ù
  FDctUtf8Win1252.Add(186,#250); // ú
  FDctUtf8Win1252.Add(187,#251); // û
  FDctUtf8Win1252.Add(188,#252); // ü
end;

function TAbstractQuery.Utf8ToWin1252(const Source: String): String;
var
   i, iCharBase, iChar, iPosChar: Integer;
   cChar: Char;
begin
   Result := '';
   i := 1;
   while i <= Source.Length do
   begin
     iCharBase := Ord(Source[i]);
     if iCharBase > 193 then
     begin
       iChar := Ord(Source[i+1]);
       if (iCharBase = 195) and (iChar > 127) and FDctUtf8Win1252.ContainsKey(iChar) then
       begin
         cChar := FDctUtf8Win1252.Items[iChar];
         Result := Result + cChar;
       end;
       Inc(i);
     end else
       Result := Result + Source[i];
     Inc(i);
   end;
end;
{$endif}

function TAbstractQuery.InternalInsertJSON(TableName: String; Value: TJSONValue; AddFieldsChild: TList<String>; upsert: Boolean): Integer;
var jFieldValue: TJSONValue;
    jV, jVi: TJSONValue;
    sFields, sValues, sFormatedDate, sTmp: String;
    {$ifdef windows} sTempValue: String; {$endif}
    i, x,z: Integer;
    dtValue: TDateTime;
    Params: TDictionary<String, Variant>;
    Query: IQuery;
begin
  Params := TDictionary<String, Variant>.Create;
  try
    sFields := '';
    sValues := '';
    Result := 0;
    for i := 0 to (Value as TJSONObject).Count-1 do
    begin
      jFieldValue := (Value as TJSONObject).Items[i];
      if jFieldValue is TJSONArray then
      begin
        sTmp := (Value as TJSONObject).Names[i];
        jVi := (Value as TJSONObject).Elements[sTmp].Clone as TJSONValue;
        try
          if (AddFieldsChild <> nil) and Assigned(AddFieldsChild) and (AddFieldsChild.Count > 0) then
          begin
            for x := 0 to (jFieldValue as TJSONArray).Count-1 do
              for z := 0 to AddFieldsChild.Count - 1 do
              begin
                 jV := (Value as TJSONObject).Elements[AddFieldsChild.Items[z]].Clone as TJSONValue;
                 ((jFieldValue as TJSONArray).Items[x] as TJSONObject).Add(AddFieldsChild.Items[z],jV);
              end;
          end;
          InsertJSON(jVi.AsJSON,sTmp,upsert);
        finally
          jVi.Free;
        end;
      end else
      begin
        sFields := sFields+IfThen(sFields.IsEmpty,'',',')+(Value as TJSONObject).Names[i];
        sValues := sValues+IfThen(sValues.IsEmpty,'',',') + ':' + (Value as TJSONObject).Names[i];
        
        if isJSONNull(jFieldValue) then
          Params.Add((Value as TJSONObject).Names[i], Null)
        else if isJSONNumber(jFieldValue) then
        begin
          if jFieldValue is TJSONNumber then
            Params.Add((Value as TJSONObject).Names[i], (jFieldValue as TJSONNumber).AsFloat)
          else
          begin
            try
               Params.Add((Value as TJSONObject).Names[i], StrToFloat(jFieldValue.Value));
            except
               Params.Add((Value as TJSONObject).Names[i], 0);
            end;
          end;
        end else
        begin
          if TryISO8601ToDate(jFieldValue.Value,dtValue) then
          begin
             Params.Add((Value as TJSONObject).Names[i], dtValue);
          end else
          begin
            {$ifdef windows}
              if ConnectionCharSet.ToUpper.Equals('WIN1252') then
                sTempValue := Utf8ToWin1252(jFieldValue.Value)
              else
                sTempValue := jFieldValue.Value;
              Params.Add((Value as TJSONObject).Names[i], sTempValue);
            {$else}
              Params.Add((Value as TJSONObject).Names[i], jFieldValue.Value);
            {$endif}
          end;
        end;
      end;
    end;
    
    if Params.Count > 0 then
    begin
      Query := Insert('INSERT INTO '+TableName+' ('+sFields+') VALUES ('+sValues+')',upsert);
      Query.SetParamsOfDict(Params);
      Query.Exec;
    end;
    Result := 1;
  finally
    Params.Free;
  end;
end;

{$ifdef windows}
constructor TAbstractQuery.Create(AOwner: TComponent);
begin
  FillCharSetDictionary;
end;
{$endif}

end.
