unit adapter.query.intf;

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  Classes, SysUtils, DB, Generics.Collections;

type
  TTypeFieldMask = (tmEditMask, tmDisplayFormat, tmEditFormat);
  TTypeFieldMaskSet = set of TTypeFieldMask;

  { IQuery }

  IQuery = Interface
    function AsDataSet: TDataSet;
    procedure CommitOrApplyUpdates(Dataset: TDataSet = nil);
    function Exec: IQuery; overload;
    function Exec(SQL: String): IQuery; overload;
    function GetReturnedFields: TFields;
    function Insert(SQL: String; UpSert: Boolean = False): IQuery;
    function InsertJSON(const Value: String; upsert: Boolean = False): IQuery; overload;
    function InsertJSON(const Value: String; TableName: String = ''; upsert: Boolean = False): IQuery; overload;
    function InsertJSON(const Value: String; AddFieldsChild: TList<String>; TableName: String = ''; upsert: Boolean = False): IQuery; overload;
    procedure LinkToDataSource(MasterField, LinkedField: String; MasterSource: TDataSource);
    function Open: IQuery; overload;
    function Open(SQL: String): IQuery; overload;
    function Select(SQL: String): IQuery;
    function SetChildQuery(MasterField, LinkedField: String; ChildQuery: IQuery): IQuery;
    function GetConnection: TComponent;
    procedure SetConnection(Connection: TComponent);
    function SetFieldMask(Field: String; Mask: String; TypeMask: TTypeFieldMaskSet): IQuery;
    function SetParamByName(Param: String; Value: Variant): IQuery;
    function SetParamsOfDict(Params: TDictionary<String, Variant>): IQuery; overload;
    function SetParamsOfDict(Params: TDictionary<String, String>): IQuery; overload;
    function ParamValue(Param: String): Variant;
    function ParamExists(Name: String): Boolean;
    function SetQueryName(Name: String): IQuery;
    function SetReturningFields(const Fields: Array of String): IQuery;
    function Update(SQL: String): IQuery;
    function GetConnectionCharSet: String;
    function GetDataSource: TDataSource;
    function GetRowsAffected: Int64;
    function GetInsertedRecords: Int64;
    function GetIsEmpty: Boolean;
    function GetEOF: Boolean;
    property ConnectionCharSet: String read GetConnectionCharSet;
    property DataSource: TDataSource read GetDataSource;
    property InsertedRecords: Int64 read GetInsertedRecords;
    property ReturnedFields: TFields read GetReturnedFields;
    property RowsAffected: Int64 read GetRowsAffected;
    property IsEmpty: Boolean read GetIsEmpty;
    property EOF: Boolean read GetEOF;
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
    procedure Log(EventId, OriginId: Integer; OriginTable, Message: String); overload;
  end;

  IChildQuery = Interface
    function GetMasterField: String;
    function GetLinkedField: String;
    function GetQuery: IQuery;
    property MasterField: String read GetMasterField;
    property LinkedField: String read GetLinkedField;
    property Query: IQuery read GetQuery;
  end;

implementation

end.

