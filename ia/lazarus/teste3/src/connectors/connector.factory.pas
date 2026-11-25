unit connector.factory;

{$I ../db/dbcomponent.inc}

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
    (* System Units *)
    Classes, SysUtils,
    (* Project units *)
    adapter.query.intf
    {$if defined(USE_ZEOS) and defined(DEFAULT_ZEOS)}
    , connector.zeos
    {$endif}
    {$if defined(USE_SQLDB) and defined(DEFAULT_SQLDB)}
    , connector.sqldb
    {$endif}
    {$if defined(USE_UNIDAC) and defined(DEFAULT_UNIDAC)}
    , connector.unidac
    {$endif}
    {$ifdef USE_FIREDAC}
    , connector.firedac
    {$endif}
    ;

type

  { TConnectionFactory }

  TConnectionFactory = class
  private
     class var FInstance: TConnectionFactory;
     FConnection: TComponent;
     FAOwner: TComponent;
  public
     constructor Create(AOwner: TComponent; Connection: TComponent);
     class function GetInstance: TConnectionFactory;
     class function GetOwnner: TComponent;
     class function Get: TComponent;
     class function New: TComponent; overload;
     class function New(AOwner: TComponent; Connection: TComponent): TComponent; overload;
  end;

  { TQueryFactory }
  TQueryFactory = class
  private
  public
     class function New(AOwner: TComponent; Connection: TComponent): IQuery; overload;
     class function New(AOwner: TComponent): IQuery; overload;
     class function New: IQuery; overload;
  end;


implementation

{ TConnectionFactory }

constructor TConnectionFactory.Create(AOwner: TComponent; Connection: TComponent);
begin
   FConnection := Connection;
   FInstance := Self;
   FAOwner := AOwner;
end;

class function TConnectionFactory.GetInstance: TConnectionFactory;
begin
   if not Assigned(FInstance) then
      raise ENoConstructException.Create('Not exists instance of the TConnectionFactory class!');
   Result := FInstance;
end;

class function TConnectionFactory.GetOwnner: TComponent;
begin
  Result := GetInstance.FAOwner;
end;

class function TConnectionFactory.Get: TComponent;
begin
   Result := GetInstance.FConnection;
end;

class function TConnectionFactory.New: TComponent;
begin
   if not Assigned(FInstance) then
      raise ENoConstructException.Create('Not exists instance of the TConnectionFactory class!');
   Result := New(FAOwner,FInstance.FConnection);
end;

class function TConnectionFactory.New(AOwner: TComponent; Connection: TComponent): TComponent;
begin
   {$if defined(USE_ZEOS) and defined(DEFAULT_ZEOS)}
      Result := TZeosConnection.NewConnection(AOwner,Connection);
   {$endif}
   {$if defined(USE_UNIDAC) and defined(DEFAULT_UNIDAC)}
     Result := TUnidacConnection.NewConnection(AOwner,Connection);
   {$endif}
   {$ifdef USE_FIREDAC}
      Result := TFiredacConnection.NewConnection(AOwner,Connection);
   {$endif}
end;

{ TQueryFactory }
class function TQueryFactory.New(AOwner: TComponent; Connection: TComponent): IQuery;
begin
   {$if defined(USE_ZEOS) and defined(DEFAULT_ZEOS)}
      Result := TZeosQuery.Create(AOwner);
   {$endif}
   {$if defined(USE_SQLDB) and defined(DEFAULT_SQLDB)}
      Result := TSQLdbQuery.Create(AOwner);
   {$endif}
   {$if defined(USE_UNIDAC) and defined(DEFAULT_UNIDAC)}
     Result := TUnidacQuery.Create(AOwner);
   {$endif}
   {$ifdef USE_FIREDAC}
      Result := TFiredacQuery.Create(AOwner);
   {$endif}
   Result.SetConnection(Connection);
end;

class function TQueryFactory.New(AOwner: TComponent): IQuery;
begin
   Result := TQueryFactory.New(AOwner, TConnectionFactory.Get);
end;

class function TQueryFactory.New: IQuery;
begin
   Result := TQueryFactory.New(TConnectionFactory.GetOwnner, TConnectionFactory.Get);
end;

end.
