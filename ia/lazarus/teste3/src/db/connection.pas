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
  {$ifdef USE_UNIDAC}
  , Uni, InterBaseUniProvider
  {$endif}
  {$ifdef USE_ZEOS}
  , ZConnection
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
  {$endif}
  {$ifdef USE_UNIDAC}
    UConnection: TUniConnection;
  {$endif}
  {$ifdef USE_ZEOS}
    ZConnection: TZConnection;
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
      {$ifdef windows}
        ZConnection.ClientCodepage := TConfiguration.ConnectionCharSet;
      {$endif}
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
    {$if defined(USE_UNIDAC) and defined(DEFAULT_UNIDAC)}
      UConnection.Connected := False;
      if TConfiguration.ConnectionProtocol.ToLower.Equals('firebird') then
        UConnection.ProviderName := 'InterBase'
      else
        UConnection.ProviderName := TConfiguration.ConnectionProtocol;

      UConnection.Server := TConfiguration.ConnectionHostName;
      UConnection.Port := TConfiguration.ConnectionPort;
      UConnection.Database := sStrConn;
      UConnection.Username := TConfiguration.ConnectionUser;
      UConnection.Password := TConfiguration.ConnectionPassword;
      UConnection.SpecificOptions.Values['ClientLibrary'] := TConfiguration.ConnectionLibraryLocation;
      if TConfiguration.ConnectionCharSet.IsEmpty then
        UConnection.SpecificOptions.Values['Charset'] := ''
      else
        UConnection.SpecificOptions.Values['Charset'] := TConfiguration.ConnectionCharSet;
      UConnection.Connected := True;
      dbConnection := UConnection;
    {$endif}
    {$ifdef USE_FIREDAC}
      if TConfiguration.ConnectionProtocol.ToLower.Equals('firebird') then
        FDConnection.DriverName := 'FB'
      else
        FDConnection.DriverName := TConfiguration.ConnectionProtocol;
      if TConfiguration.ConnectionHostName <> '' then
      begin
        FDConnection.Params.Values['Server'] := TConfiguration.ConnectionHostName;
        if TConfiguration.ConnectionPort > 0 then
          FDConnection.Params.Values['Port'] := TConfiguration.ConnectionPort.ToString;
      end;
      FDConnection.Params.Database := sStrConn;
      FDConnection.Params.UserName := TConfiguration.ConnectionUser;
      FDConnection.Params.Password := TConfiguration.ConnectionPassword;
      PgDriverLink.VendorLib := TConfiguration.ConnectionLibraryLocation;
      FDConnection.Params.Values['CharacterSet'] := TConfiguration.ConnectionCharSet;
      FDConnection.Connected := True;
      dbConnection := FDConnection;
    {$endif}

    (* Instancia a connection factory, passando o connection da tecnologia utilizada *)
    //TConnectionFactory.Create(Self, TConnectionFactory.New(Self,dbConnection));
    //TConnectionFactory.Create(Self, dbConnection);
  except on e: Exception do
    Writeln(ErrOutput, 'Error connecting to database: ' + e.Message);
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
