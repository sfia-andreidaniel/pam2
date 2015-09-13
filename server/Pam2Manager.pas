{$mode objfpc}
{$H+}
unit Pam2Manager;

interface uses 
    {$ifdef unix}cthreads, {$endif}
    IniFiles,
    sysutils,
    Logger,
    StringsLib,
    AppUtils,
    JSON
    {database support},
    sqldb, pqconnection, { IBConnnection, ODBCConn, }
    mysql50conn, mysql55conn ,   
    {end of database support}
    Pam2Entities;

type 
    
    TPam2ManagerException = class( Exception )
        code: LongInt;
        constructor Create( exceptionCode: LongInt; msg: AnsiString );
    end;
    
    TPam2Manager = class
        
        private
            
            ini: TIniFile;

            CS: TRTLCriticalSection;
            CanCS: Boolean;
            
            _origins: TStrArray;
            
            SQLConn: TSqlConnection;
            PAM: TPam2DB;
            
            function getServerPort(): Word;
            function getServerName(): AnsiString;
            function getServerProtocolName(): AnsiString;
            function getServerListenInterface(): AnsiString;
            function getOriginsList(): TStrArray;
            function getLoggingLevel: AnsiString;
            function getLogFileName: AnsiString;
        
            procedure InitDatabase;
            
            procedure IN_CS();
            procedure OUT_CS();
        
        public
        
            constructor Create;
        
            { INI BINDINGS }
            
            { [daemon].port }
            property ServerPort: Word read getServerPort;
            { [daemon].name }
            property ServerName: AnsiString read getServerName;
            { [daemon].interface }
            property ServerListenInterface: AnsiString read getServerListenInterface;
            { [daemon].protocol }
            property ServerProtocolName: AnsiString read getServerProtocolName;
 
            { [origins].* }
            property AllowedOriginsList: TStrArray read getOriginsList;
            { [daemon].loglevel }
            property LoggingLevel: AnsiString read getLoggingLevel;
            { [daemon].logfile }
            property LogFileName: AnsiString read getLogFileName;
            
            
            { API METHODS }
            
            { Returns the initialization configuration file path }
            function getIniFilePath(): AnsiString;
            
            destructor Free();
    end;

    
    var { Flag telling us weather the config has been loaded successfully or not }
        IPam2ManagerLoaded: Boolean;
        
        { Instance to Server Manager }
        IPam2Manager: TPam2Manager;

implementation uses classes, md5, dos, strutils;

procedure TPam2Manager.IN_CS();
begin
    if ( CanCS ) then
        EnterCriticalSection( CS );
end;

procedure TPam2Manager.OUT_CS();
begin
    
    if ( CanCS ) then
        LeaveCriticalSection( CS );
    
end;

constructor TPam2Manager.Create;

var OriginsList: TStringList;
    i: LongInt;
    n: LongInt;
    logPath: AnsiString;
    NumOrigins: LongInt;
    IniFile: AnsiString;
    
begin

    CanCS := TRUE;
    
    IniFile := getIniFilePath;

    Console.Log('IniFile: ', IniFile );
    
    ini := TIniFile.Create( IniFile );
    
    InitCriticalSection( CS );

    logPath := logFileName;

    if ( logPath <> 'console' ) then 
    begin
        Console.Log('Initialize logger to: ', logPath );
        init_logger( logPath );
    end;
    
    Console.setLoggingLevel( LoggingLevel );
    
    Console.Notice( 'Config file loaded from "' + Console.Color( IniFile, FG_WARNING_COLOR ) + '"' );
    
    InitDatabase;
    
    { Load the origins. }
    
    OriginsList := TStringList.Create();
    
    ini.ReadSectionValues( 'origins', OriginsList );
    
    n := OriginsList.Count;
    
    setLength( _Origins, 0 );
    
    NumOrigins := 0;
    
    for i := 0 to n - 1 do
    begin
        
        if ( ini.ReadString( 'origins', OriginsList.ValueFromIndex[ i ], '' ) <> '' ) then
        begin
        
            NumOrigins := NumOrigins + 1;
        
            setLength( _origins, NumOrigins );
    
            _origins[ NumOrigins - 1 ] := OriginsList.ValueFromIndex[i];
        
        end;
        
    end;
    
    OriginsList.Destroy;
end;

destructor TPam2Manager.Free();
begin

    ini.Destroy();
    setLength( _origins, 0 );
    
    DoneCriticalSection( CS );

    PAM.Free;

    SQLConn.Free;

end;

function TPam2Manager.getOriginsList(): TStrArray;
begin
    
    if Length( _origins ) = 0 then
    begin
        setLength( result, 1 );
        result[0] := '*';
        exit;
    end;
    
    result := _origins;
    
end;

function TPam2Manager.getServerPort(): Word;
begin
    
    result := ini.ReadInteger( 'daemon', 'port', 42763 );
    
end;

function TPam2Manager.getServerProtocolName(): AnsiString;
begin

    result := ini.ReadString( 'daemon', 'protocol', 'pam2' );

end;

function TPam2Manager.getServerName(): AnsiString;
begin
    
    result := ini.readString( 'daemon', 'name', 'PAM2 authentication server' );
    
end;

function TPam2Manager.getLoggingLevel(): AnsiString;
begin
    
    result := ini.readString( 'daemon', 'loglevel', '0' );
    
    if ( result <> '0' ) and ( result <> '1' ) and ( result <> '2' ) and ( result <> '3' ) and ( result <> '4' ) then
        result := '0';
    
end;

function TPam2Manager.getLogFileName(): AnsiString;
begin
    
    result := ini.readString( 'daemon', 'logfile', 'stdout' );
    
end;

function TPam2Manager.getServerListenInterface(): AnsiString;
begin
    
    result := ini.readString( 'daemon', 'listen', '0.0.0.0' );
    
end;

function TPam2Manager.getIniFilePath(): AnsiString;
var udir : AnsiString; // user home directory
begin
    
    // search of the config file is done in the following order
    //
    // 1) {APPDIR}/pam2d.ini                                || windows | unix
    // 2) {USERDIR}/pam2d.ini                               || windows | unix
    // 3) /etc/pam2d.ini                                    ||         | unix
    
    {$ifdef unix}
        
        udir := GetUserHomeDir;

        if fileExists( getApplicationDir() + PATH_SEPARATOR + 'pam2d.ini' ) then
        begin
            
            result := getApplicationDir() + PATH_SEPARATOR + 'pam2d.ini';
            
        end else
        if fileExists( udir + 'pam2d.ini' ) then
        begin
        
            result := udir + 'pam2d.ini';
        
        end else
        if fileExists( '/etc/pam2d.ini' ) then
        begin
        
            result := '/etc/pam2d.ini';
        
        end else
        begin
        
            Console.Error( 'Failed to locate the application config file! Searched in "%AppDir%/pam2d.ini", "%UserDir%/pam2d.ini" and "/etc/pam2d.ini".' );
            
            result := '';
            
            raise Exception.Create( 'Failed to locate the application config file! Searched in "%AppDir%/pam2d.ini", "%UserDir%/pam2d.ini" and "/etc/pam2d.ini".' );
            
        end;
        
    {$else}
    
        // On Windows, we check @ this point only in the %APPDIR%/pam2d.ini
        
        if fileExists( getApplicationDir() + PATH_SEPARATOR + 'pam2d.ini' ) then
        begin
            
            result := getApplicationDir() + PATH_SEPARATOR + 'pam2d.ini';
        
        end else
        begin
        
            Console.Error( 'Failed to locate the application config file! Searched in "%AppDir%/pam2d.ini".' );
            
            result := '';
            
            raise Exception.Create( 'Failed to locate the application config file! Searched in "%AppDir%/pam2d.ini".' );
        
        end;
    
    {$endif}

end;

procedure TPam2Manager.InitDatabase;
var
    sHost: String;
    sUser: String;
    sPass: String;
    sName: String;
begin

    sHost := Ini.ReadString( 'database', 'hostname', 'localhost' );
    sUser := Ini.ReadString( 'database', 'user', 'pam2' );
    sPass := Ini.ReadString( 'database', 'password', 'password' );
    sName := Ini.ReadString( 'database', 'database', 'pam' );
    
    // Connect to database
    Console.Log( 'Database:', Console.Color( 'mysql://' + sUser + '@' + sHost + '/' + sName, FG_LOG_COLOR ) );
    
    SQLConn := TMySQL55Connection.Create(nil);
    
    with SQLConn do
    begin
        hostname := sHost;
        databasename := sName;
        username := sUser;
        password := sPass;
        open;
    end;

    PAM := TPam2DB.Create( SQLConn );

end;

constructor TPam2ManagerException.Create( exceptionCode: LongInt; msg: AnsiString );
begin
    code := exceptionCode;
    inherited Create( msg );
end;

initialization

    IPam2ManagerLoaded := FALSE;

    //Console.log( 'Loading configuration file...' );

    try

        IPam2Manager := TPam2Manager.Create;
        IPam2ManagerLoaded := TRUE;
        
    except
        
        On E: Exception Do
        begin
            IPam2ManagerLoaded := FALSE;
            
            Console.error( 'Error loading config:', E.Message );
        end;
        
    end;

finalization

    if IPam2ManagerLoaded then
    begin
        IPam2Manager.Free;
    end;

end.