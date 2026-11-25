unit connector.zeos;

{$I ../db/dbcomponent.inc}

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

{$ifdef USE_ZEOS}
uses
   (* System Units *)
   Classes, SysUtils, DB,
   (* Zeos Units *)
   ZAbstractConnection, ZConnection, ZDataSet,
   (* Project units *)
   adapter.query.intf, adapter.query.impl;

type

  { TZeosConnection }

  TZeosConnection = class
    class function NewConnection(AOwner: TComponent; Connection: TComponent): TComponent;
  end;

  { TZeosQuery }
  TZeosQuery = class(TAbstractQuery)
  private
    function GetConnectionCharSet: String; override;
  public
    constructor Create(AOwner: TComponent); {$ifdef windows} override; {$endif}
    procedure CommitOrApplyUpdates(Dataset: TDataSet = nil); override;
    function Exec: IQuery; overload; override;
    function Exec(SQL: String): IQuery; overload; override;
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

{$ifdef USE_ZEOS}
{ TZeosConnection }

class function TZeosConnection.NewConnection(AOwner: TComponent; Connection: TComponent): TComponent;
begin
   Result := TZConnection.Create(AOwner);
   with (Result as TZConnection) do
   begin
      Protocol := (Connection as TZConnection).Protocol;
      HostName := (Connection as TZConnection).HostName;
      Port := (Connection as TZConnection).Port;
      Database := (Connection as TZConnection).Database;
      User := (Connection as TZConnection).User;
      Password := (Connection as TZConnection).Password;
      LibraryLocation := (Connection as TZConnection).LibraryLocation;
      Connected := True;
   end;
end;

function TZeosQuery.GetConnectionCharSet: String;
begin
  Result := ((FInternalDataSet as TZQuery).Connection as TZConnection).ClientCodepage;
end;

constructor TZeosQuery.Create(AOwner: TComponent);
begin
  {$ifdef windows}
  inherited Create(AOwner);
  {$endif}
  FInternalDataSet := TZQuery.Create(AOwner);
end;

procedure TZeosQuery.CommitOrApplyUpdates(Dataset: TDataSet);
begin
   if Dataset <> nil then
   begin
     with (Dataset as TZQuery) do
     begin
       ApplyUpdates;
       with (Connection as TZAbstractConnection) do
       begin
         if not AutoCommit then
           Commit;
       end;
     end;
   end else
   begin
     with (FInternalDataSet as TZQuery) do
     begin
       ApplyUpdates;
       with (Connection as TZAbstractConnection) do
       begin
         if not AutoCommit then
           Commit;
       end;
     end;
   end;
end;

function TZeosQuery.Exec: IQuery;
begin
   if Length(FReturningFields) > 0 then
   begin
     (FInternalDataSet as TZQuery).Open;
     FReturnedFields := (FInternalDataSet as TZQuery).Fields;
   end else
     (FInternalDataSet as TZQuery).ExecSQL;
   FRowsAffected := (FInternalDataSet as TZQuery).RowsAffected;
   Result := Self;
end;

function TZeosQuery.Exec(SQL: String): IQuery;
var iRowsAffected: Integer;
begin
   (FInternalDataSet as TZQuery).Connection.ExecuteDirect(SQL,iRowsAffected);
   FRowsAffected := iRowsAffected;
   Result := Self;
end;

procedure TZeosQuery.LinkToDataSource(MasterField, LinkedField: String; MasterSource: TDataSource);
begin
  (FInternalDataSet as TZQuery).MasterFields := MasterField;
  (FInternalDataSet as TZQuery).MasterSource := MasterSource;
  (FInternalDataSet as TZQuery).LinkedFields := LinkedField;
end;

function TZeosQuery.Select(SQL: String): IQuery;
begin
   (FInternalDataSet as TZQuery).SQL.Text := SQL;
   (FInternalDataSet as TZQuery).Prepare;
   Result := Self;
end;

function TZeosQuery.GetConnection: TComponent;
begin
  Result := (FInternalDataSet as TZQuery).Connection;
end;

procedure TZeosQuery.SetConnection(Connection: TComponent);
begin
   (FInternalDataSet as TZQuery).Connection := (Connection as TZAbstractConnection);
end;

function TZeosQuery.SetParamByName(Param: String; Value: Variant): IQuery;
begin
   (FInternalDataSet as TZQuery).ParamByName(Param).Value := Value;
   Result := Self;
end;

function TZeosQuery.ParamValue(Param: String): Variant;
begin
  Result := (FInternalDataSet as TZQuery).ParamByName(Param).Value;
end;

function TZeosQuery.ParamExists(Name: String): Boolean;
begin
  Result := (FInternalDataSet as TZQuery).Params.FindParam(Name) <> nil;
end;

{$endif}

end.

