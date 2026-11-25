unit connector.unidac;

interface

{$I ../db/dbcomponent.inc}

{$ifdef USE_UNIDAC}
uses
   (* System Units *)
   Classes, SysUtils, DB,
   (* Unidac Units *)
   Uni, InterBaseUniProvider,
   (* Project units *)
   adapter.query.intf, adapter.query.impl;

type

  { TUnidacConnection }

  TUnidacConnection = class
    class function NewConnection(AOwner: TComponent; Connection: TComponent): TComponent;
  end;

  { TUnidacQuery }
  TUnidacQuery = class(TAbstractQuery)
  private
    function GetConnectionCharSet: String; override;
  public
    constructor Create(AOwner: TComponent);
    procedure CommitOrApplyUpdates(Dataset: TDataSet = nil); override;
    function Exec: IQuery; overload; override;
    //function Exec(SQL: String): IQuery; overload; override;
    procedure LinkToDataSource(MasterField, LinkedField: String; MasterSource: TDataSource); override;
    function Select(SQL: String): IQuery; override;
    function GetConnection: TComponent; override;
    procedure SetConnection(Connection: TComponent); override;
    function SetParamByName(Param: String; Value: Variant): IQuery; override;
    function ParamValue(Param: String): Variant; override;
    function ParamExists(Name: String): Boolean; override;
  end;
{$endif}

implementation

{$ifdef USE_UNIDAC}

{ TUnidacConnection }

class function TUnidacConnection.NewConnection(AOwner: TComponent; Connection: TComponent): TComponent;
begin
   Result := TUniConnection.Create(AOwner);
   with (Result as TUniConnection) do
   begin
	   ProviderName := (Connection as TUniConnection).ProviderName;
           Server := (Connection as TUniConnection).Server;
           Port := (Connection as TUniConnection).Port;
	   Database := (Connection as TUniConnection).Database;
	   Username := (Connection as TUniConnection).Username;
	   Password := (Connection as TUniConnection).Password;
           SpecificOptions.Values['ClientLibrary'] := (Connection as TUniConnection).SpecificOptions.Values['ClientLibrary'];
      Connected := True;
   end;
end;

procedure TUnidacQuery.CommitOrApplyUpdates(Dataset: TDataSet);
begin
   if Dataset <> nil then
   begin
     with (Dataset as TUniQuery) do
     begin
       ApplyUpdates;
       with (Connection as TUniConnection) do
       begin
         if not AutoCommit then
           Commit;
       end;
     end;
   end else
   begin
     with (FInternalDataSet as TUniQuery) do
     begin
       ApplyUpdates;
       with (Connection as TUniConnection) do
       begin
         if not AutoCommit then
           Commit;
       end;
     end;
   end;
end;

function TUnidacQuery.GetConnectionCharSet: String;
begin
  if ((FInternalDataSet as TUniQuery).Connection as TUniConnection).SpecificOptions.IndexOfName('Charset') > -1 then
    Result := ((FInternalDataSet as TUniQuery).Connection as TUniConnection).SpecificOptions.Values['Charset']
  else
    Result := '';
end;

constructor TUnidacQuery.Create(AOwner: TComponent);
begin
  FInternalDataSet := TUniQuery.Create(AOwner);
end;

function TUnidacQuery.Exec: IQuery;
var sSql, sTable: String;
  isInsert: Boolean;
begin
  if Length(FReturningFields) > 0 then
  begin
//1 - Descobrir a PK e usar no returning
//2 - Fazer um select a partir dos campos do returning filtrando pela PK retornada.

    (FInternalDataSet as TUniQuery).DMLRefresh := True;
    sSql := (FInternalDataSet as TUniQuery).SQL.Text.ToUpper;
    isInsert := sSql.Contains('INSERT INTO');
    if isInsert then
    begin
      sTable := sSql.Substring(sSql.IndexOf('INSERT INTO')+11,sSql.IndexOf('(')-11);
      (FInternalDataSet as TUniQuery).SQLInsert.Text := (FInternalDataSet as TUniQuery).SQL.Text;
    end else
    begin
      sTable := sSql.Substring(sSql.IndexOf('UPDATE')+6,sSql.IndexOf('SET')-6);
      (FInternalDataSet as TUniQuery).SQLUpdate.Text := (FInternalDataSet as TUniQuery).SQL.Text;
    end;
    (FInternalDataSet as TUniQuery).SQL.Text := 'SELECT '+FReturningFields+' FROM '+sTable+' WHERE 0 = 1';
    (FInternalDataSet as TUniQuery).Open;
    if isInsert then
      (FInternalDataSet as TUniQuery).Insert
    else
      (FInternalDataSet as TUniQuery).Edit;
    (FInternalDataSet as TUniQuery).Post;
    FReturnedFields := (FInternalDataSet as TUniQuery).Fields;
  end else
    (FInternalDataSet as TUniQuery).ExecSQL;
  FRowsAffected := (FInternalDataSet as TUniQuery).RowsAffected;
  Result := Self;
end;

//function TUnidacQuery.Exec(SQL: String): IQuery;
//begin
//   FRowsAffected := (FInternalDataSet as TUniQuery).Connection.ExecSQL(SQL);
//   Result := Self;
//end;

//https://www.youtube.com/watch?v=oZB0a6z7jYg
//https://www.youtube.com/watch?v=8IElSvf_yXs
//https://www.youtube.com/watch?v=b9lXp1uWR9E

procedure TUnidacQuery.LinkToDataSource(MasterField, LinkedField: String; MasterSource: TDataSource);
begin
  (FInternalDataSet as TUniQuery).MasterFields := MasterField;
  (FInternalDataSet as TUniQuery).MasterSource := MasterSource;
  (FInternalDataSet as TUniQuery).MasterFields := LinkedField;
end;

function TUnidacQuery.Select(SQL: String): IQuery;
begin
   (FInternalDataSet as TUniQuery).SQL.Text := SQL;
   (FInternalDataSet as TUniQuery).Prepare;
   Result := Self;
end;

function TUnidacQuery.GetConnection: TComponent;
begin
  Result := (FInternalDataSet as TUniQuery).Connection;
end;

procedure TUnidacQuery.SetConnection(Connection: TComponent);
begin
   (FInternalDataSet as TUniQuery).Connection := (Connection as TUniConnection);
end;

function TUnidacQuery.SetParamByName(Param: String; Value: Variant): IQuery;
begin
  if not (FInternalDataSet as TUniQuery).Prepared then (FInternalDataSet as TUniQuery).Prepare;
  (FInternalDataSet as TUniQuery).ParamByName(Param).Value := Value;
   Result := Self;
end;

function TUnidacQuery.ParamValue(Param: String): Variant;
begin
  Result := (FInternalDataSet as TUniQuery).ParamByName(Param).Value;
end;

function TUnidacQuery.ParamExists(Name: String): Boolean;
begin
  Result := (FInternalDataSet as TUniQuery).FindParam(Name) <> nil;
end;
{$endif}

end.

