unit connection;

{$I dbcomponent.inc}

{$ifdef FPC}
   {$mode Delphi}
{$endif}

interface

uses
  Classes, SysUtils, Dialogs, DB
  {$ifdef USE_FIREDAC}
  , FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Comp.Client, FireDAC.Comp.UI,
  FireDAC.Phys.PGDef, FireDAC.Phys.PG
  {$endif}
  {$ifdef USE_SQLDB}
  , IBConnection, PQConnection, SQLDB
  {$endif}
  {$ifdef USE_ZEOS}
  , ZConnection, ZDataset, ZSqlUpdate
  {$endif}
  , connector.configuration;

type

  { TdmConn }

  TdmConn = class(TDataModule)
  {$ifdef USE_FIREDAC}
    Cursor: TFDGUIxWaitCursor;
    FDConnection: TFDConnection;
    PgDriverLink: TFDPhysPgDriverLink;
  {$endif}
  {$ifdef USE_SQLDB}
    IBConnection: TIBConnection;
    PQConnection: TPQConnection;
    SQLQuery1: TSQLQuery;
  {$endif}
  {$ifdef USE_ZEOS}
    ZConnection: TZConnection;
    ZQuery1: TZQuery;
    ZQuery1id: TStringField;
    ZQuery1senha: TStringField;
    ZQuery1supervisor: TStringField;
    ZQuery1ucliente: TStringField;
    ZUpdateSQL1: TZUpdateSQL;
  {$endif}
    procedure DataModuleCreate(Sender: TObject);
  private
    FConnectionId: String;
    FdbConnection: TComponent;
    procedure SetdbConnection(AValue: TComponent);
  public
    constructor CreateConnection(ConnectionId: String);
    property dbConnection: TComponent read FdbConnection write SetdbConnection;
  end;

implementation

uses connector.factory;

{$ifdef FPC}
  {$R *.lfm}
{$else}
  {$R *.dfm}
{$endif}

{ TdmConn }

procedure TdmConn.DataModuleCreate(Sender: TObject);
var sStrConn: String;
begin
  try
    sStrConn := TConfiguration.ConnectionDatabase+FConnectionId;
    {$if defined(USE_ZEOS) and defined(DEFAULT_ZEOS)}
      ZConnection.Connected := False;
      ZConnection.Protocol := TConfiguration.ConnectionProtocol;
      ZConnection.HostName := TConfiguration.ConnectionHostName;
      ZConnection.Port := TConfiguration.ConnectionPort;
      ZConnection.Database := sStrConn;
      ZConnection.User := TConfiguration.ConnectionUser;
      ZConnection.Password := TConfiguration.ConnectionPassword;
      ZConnection.LibraryLocation := TConfiguration.ConnectionLibraryLocation;
      ZConnection.Connected := True;
      dbConnection := ZConnection;
    {$endif}
    {$if defined(USE_SQLDB) and defined(DEFAULT_SQLDB)}
      if Ini.ReadString('database','driver','') = 'firebird' then
      begin
        IBConnection.DatabaseName := Ini.ReadString('database','dbfile','');
        IBConnection.UserName := Ini.ReadString('database','user','');
        IBConnection.Password := Ini.ReadString('database','password','');
        //IBConnection.LibraryLocation := Ini.ReadString('database','libraryClient','');
        IBConnection.Connected := True;
        dbConnection := IBConnection;
      end else if Ini.ReadString('database','driver','') = 'postgresql' then
      begin
        PQConnection.DatabaseName := Ini.ReadString('database','dbfile','');
        PQConnection.UserName := Ini.ReadString('database','user','');
        PQConnection.Password := Ini.ReadString('database','password','');
        //PQConnection.LibraryLocation := Ini.ReadString('database','libraryClient','');
        PQConnection.Connected := True;
        dbConnection := PQConnection;
      end;
    {$endif}
    {$ifdef USE_FIREDAC}
      if TConfiguration.ConnectionProtocol.ToLower.Equals('firebird') then
        FDConnection.DriverName := 'FB'
      else
        FDConnection.DriverName := TConfiguration.ConnectionProtocol;
      FDConnection.Params.Database := sStrConn;
      if FDConnection.Params.IndexOfName('Server') > -1 then
      FDConnection.Params.Values['Server'] := TConfiguration.ConnectionHostName;
      FDConnection.Params.UserName := TConfiguration.ConnectionUser;
      FDConnection.Params.Password := TConfiguration.ConnectionPassword;
      PgDriverLink.VendorLib := TConfiguration.ConnectionLibraryLocation;
      FDConnection.Connected := True;
      dbConnection := FDConnection;
    {$endif}

    (* Instancia a connection factory, passando o connection da tecnologia utilizada *)
    //TConnectionFactory.Create(Self, TConnectionFactory.New(Self,dbConnection));
    TConnectionFactory.Create(Self, dbConnection);
  except on e: Exception do
    //ShowMessage(e.Message);
  end;
end;

procedure TdmConn.SetdbConnection(AValue: TComponent);
begin
  if FdbConnection = AValue then Exit;
  FdbConnection := AValue;
end;

constructor TdmConn.CreateConnection(ConnectionId: String);
begin
  inherited Create(nil);
  FConnectionId := ConnectionId;
end;

end.
