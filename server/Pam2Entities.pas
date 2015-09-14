unit Pam2Entities;
interface uses
	{$ifdef unix}cthreads, {$endif}
	Logger,
	classes,
	StringsLib,
	sysutils,
	QueryParser,
	JSON,
	{database support}
    sqldb, pqconnection, { IBConnnection, ODBCConn, }
    mysql50conn, mysql55conn   
    {end of database support}
	;

type TPam2DB = class;

type TServiceUserPassword = record

		service_id: integer;
		password: AnsiString;
		encType: byte; // CONSTANT ENCTYPE_*

	end;

type TPam2User = class

		protected

			db: TPam2DB;

			_user_id: integer;
			_login_name: AnsiString;
			_real_name: AnsiString;
			_email: AnsiString;
			_enabled: boolean;

			_admin: boolean;
			_password: AnsiString;

			_groups: Array of Integer;
			_passwords: Array of TServiceUserPassword;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

			procedure setLoginName( value: AnsiString );
			procedure setRealName ( value: AnsiString );
			procedure setEmail    ( value: AnsiString );
			procedure setEnabled  ( value: Boolean );
			procedure setAdmin    ( value: Boolean );
			procedure setPassword ( value: AnsiString );


		public

			property id         : integer    read _user_id;
			property loginName  : AnsiString read _login_name write setLoginName;
			property realName   : AnsiString read _real_name  write setRealName;
			property email      : AnsiString read _email      write setEmail;
			property enabled    : boolean    read _enabled    write setEnabled;
			property admin      : boolean    read _admin      write setAdmin;
			property password   : AnsiString read _password   write setPassword;

			constructor Create( _db: TPam2DB; uid: integer; login_name: AnsiString; real_name: AnsiString; user_email: AnsiString; user_enabled: boolean; is_admin: boolean; pam2_password: AnsiString; isSaved: boolean );
			constructor Create( _db: TPam2DB );

			function    Save(): Boolean;
			
			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure snapshot();
			procedure updateIdAfterInsertion();
			procedure rollback( snapshotLine: AnsiString );

	end;

type TPam2Group = class

		protected

			db: TPam2DB;

			_group_id: integer;
			_group_name: AnsiString;
			_enabled: boolean;

			_users: Array of Integer;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

			procedure setGroupName( value: AnsiString );
			procedure setEnabled  ( value: Boolean );

		public
			

			property id        : integer    read _group_id;
			property groupName : AnsiString read _group_name write setGroupName;
			property enabled   : Boolean    read _enabled    write setEnabled;

			constructor Create( _db: TPam2DB; gid: integer; group_name: AnsiString; _is_enabled: Boolean; isSaved: boolean );
			constructor Create( _db: TPam2DB );

			function    Save(): Boolean;
			
			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure snapshot();
			procedure updateIdAfterInsertion();
			procedure rollback( snapshotLine: AnsiString );

	end;

type TServiceHostGroupBinding = record
		service_id: integer;
		group_id: integer;
		allow: boolean;
	end;

type TServiceHostUserBinding = record
		service_id: integer;
		user_id: integer;
		allow: boolean;
	end;

type TServiceHostOptionsBinding = record
		service_id: integer;
		option_name: AnsiString;
		option_value: AnsiString;
	end;

type TServiceHostUserOptionBinding = record
		service_id: integer;
		user_id: integer;
		option_name: AnsiString;
		option_value: AnsiString;
	end;

type TServiceGroupOptionBinding = record
		service_id: integer;
		group_id: integer;
		option_name: AnsiString;
		option_value: AnsiString;
	end;

type TPam2Service = class; // fw declaration

type TPam2ServiceList = Array of TPam2Service;


type TPam2Host = class

		protected 

			db: TPam2DB;

			_host_id: integer;
		    _host_name: AnsiString;
		    _default_host: Boolean;

		    _services: TPam2ServiceList;

		    // mapping for db table: service_host_groups
		    _group_policies: Array of TServiceHostGroupBinding;

		    // mapping for db table: service_host_users
		    _user_policies: Array of TServiceHostUserBinding;

		    _service_option_bindings: Array of TServiceHostOptionsBinding;

		    _service_useroption_bindings: Array of TServiceHostUserOptionBinding;
		    _service_groupoption_bindgs: Array of TServiceGroupOptionBinding;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

			procedure setHostName( value: AnsiString );
			procedure setDefaultHost( value: Boolean );

			function  getMachineServices(): TStrArray;
			procedure setMachineServices( svcs: TStrArray );

		public

			property id       : Integer read _host_id;
			property hostName : AnsiString read _host_name write setHostName;
			property default  : Boolean read _default_host write setDefaultHost;

			property machineServices: TStrArray read getMachineServices write setMachineServices;

			constructor Create( _db: TPam2DB; hid: integer; hname: AnsiString; defaultHost: boolean; isSaved: boolean );
			constructor Create( _db: TPam2DB );

			function    Save(): Boolean;
			
			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure snapshot();
			procedure updateIdAfterInsertion();
			procedure rollback( snapshotLine: AnsiString );

	end;

type TPam2ServiceOption = class;

type TPam2Service = class

		protected

			db: TPam2DB;

			_service_id: integer;
			_service_name: AnsiString;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

			_options: Array of TPam2ServiceOption;

			procedure setServiceName( value: AnsiString );

		public

			property collection  : TPam2DB    read db;
			property id          : Integer    read _service_id;
			property serviceName : AnsiString read _service_name write setServiceName;

			constructor Create( _db: TPam2DB; sid: integer; sname: AnsiString; isSaved: boolean );
			constructor Create( _db: TPam2DB );

			function    Save(): Boolean;

			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure snapshot();
			procedure updateIdAfterInsertion();
			procedure rollback( snapshotLine: AnsiString );

	end;

type TPam2ServiceOption = class

		protected 
			_service: TPam2Service;
			_name: AnsiString;
			_default_value: AnsiString;
			_value: AnsiString;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

		public
			constructor Create( service: TPam2Service; oName: AnsiString; oDefault: AnsiString; oValue: AnsiString; isSaved: Boolean );
			function    Save(): Boolean;
			destructor  Free();

	end;

type TPam2ExecutionContext = class

		protected
			db: TPam2DB;
			admin: Boolean;
			lockedToUserId: Integer;

			// THE cmd_* functions should return a value allready encoded in JSON format,
			// or raise an exception if an error occurs.

			function cmd_host   ( query: TQueryParser ): AnsiString;
			function cmd_user   ( query: TQueryParser ): AnsiString;
			function cmd_service( query: TQueryParser ): AnsiString;
			function cmd_group  ( query: TQueryParser ): AnsiString;
			function cmd_select ( query: TQueryParser ): AnsiString;

		public 
			constructor Create( _db: TPam2DB; isAdmin: Boolean; lockedUserId: Integer );
			destructor  Free();

			function executeQuery( query: TQueryParser ): AnsiString;

	end;

type TPam2DB = class

		protected

			db: TSqlConnection;

			hosts: Array of TPam2Host;
			services: Array of TPam2Service;
			groups: Array of TPam2Group;
			users: Array of TPam2User;

			sqlStatements: TStrArray;
			explanations : TStrArray;
			errors       : TStrArray;

			snapshot     : TStrArray;

			procedure Load();
			function  getDefaultHost(): TPam2Host;
			function  generateRandomUserPassword(): AnsiString;

			function  getAllUsersList(): TStrArray;
			procedure doSQLStatement( statement: AnsiString );

		public

			constructor Create( _db: TSqlConnection );
			destructor  Free();

			property defaultHost: TPam2Host read getDefaultHost;
			property allUsers: TStrArray read getAllUsersList;

			function getUserById      ( userId: Integer ): TPam2User;
			function getUserByName    ( loginName: AnsiString ): TPam2User;
			function getUserByEmail   ( emailAddress: AnsiString ): TPam2User;

			function getGroupById     ( groupId: Integer ): TPam2Group;
			function getGroupByName   ( groupName: AnsiString ): TPam2Group;

			function getHostById      ( hostId: Integer ): TPam2Host;
			function getHostByName    ( hostName: AnsiString ): TPam2Host;

			function getServiceById   ( serviceId: Integer ): TPam2Service;
			function getServiceByName ( serviceName: AnsiString ): TPam2Service;

			function userExists       ( userName: AnsiString; const ignoreUserId: integer = 0 ): Boolean;
			function userExists       ( userId: Integer; const ignoreUserId: integer = 0 ): Boolean;
			function userExistsByEmail( emailAddress: string; const ignoreUserId: integer = 0 ): Boolean;

			function groupExists      ( groupName: AnsiString; const ignoreGroupId: integer = 0 ): Boolean;
			function groupExists      ( groupId: Integer; const ignoreGroupId: integer = 0 ): Boolean;
			
			function hostExists       ( hostName: AnsiString; const ignoreHostId: integer = 0 ): Boolean;
			function hostExists       ( hostId: Integer; const ignoreHostId: Integer = 0 ): Boolean;
			
			function serviceExists    ( serviceName: AnsiString; const ignoreServiceId: integer = 0 ): Boolean;
			function serviceExists    ( serviceId: Integer; const ignoreServiceId: Integer = 0 ): Boolean;

			function  encryptPassword  ( password: AnsiString ): AnsiString;

			procedure addSQLStatement ( statement: AnsiString );
			procedure addExplanation  ( explanation: AnsiString );
			procedure addError        ( error: AnsiString );
			procedure addSnapshot     ( line: AnsiString );

			// Context execution

			function createContext    ( userName: ansiString; password: AnsiString ): TPam2ExecutionContext;

			// CREATE FUNCTION
			function createUser       ( loginName: AnsiString; 
				                        const realName: AnsiString = ''; 
				                        const emailAddress: AnsiString = ''; 
				                        const enabled: boolean = TRUE; 
				                        const isAdmin: boolean = FALSE; 
				                        const password: AnsiString = ''
				                      ): TPam2User;

			function createGroup      ( groupName: AnsiString;
										const enabled: boolean = TRUE
									  ): TPam2Group;

			function createHost       ( hostName: AnsiString; 
				                        const isDefault: Boolean = false 
				                      ): TPam2Host;

			function createService    ( serviceName: AnsiString ): TPam2Service;

			// SNAPSHOT FUNCTIONALITY

			procedure createSnapshot();
			procedure debugSnapshot();
			procedure rollbackSnapshot();
			procedure discardSnapshot();

			function  fetchSQLStatementResultAsInt( statement: AnsiString ): Integer;

			procedure commit();

	end;

implementation

	uses md5;

	const ENCTYPE_PLAIN    : Byte = 0;
	      ENCTYPE_MD5      : Byte = 1;
	      ENCTYPE_CRYPT    : Byte = 2;
	      ENCTYPE_PASSWORD : Byte = 3;

	      FMT_USER         = '0123456789abcdefghijklmnopqrstuvwxyz_';
	      FMT_USER_BEGIN   = 'abcdefghijklmnopqrstuvwxyz';

	      FMT_GROUP        = FMT_USER;
	      FMT_GROUP_BEGIN  = FMT_USER_BEGIN;

	      FMT_SERVICE      = FMT_USER;
	      FMT_SERVICE_BEGIN= FMT_USER_BEGIN;

	      FMT_HOST         = '0123456789abcdefghijklmnopqrstuvwxyz_-.';
	      FMT_HOST_BEGIN   = '0123456789abcdefghijklmnopqrstuvwxyz';

	      FMT_SERVICEOPTION= FMT_USER;
	      FMT_SERVICEOPTION_BEGIN = FMT_USER_BEGIN + '_';

	      FMT_EMAIL        = '0123456789abcdefghijklmnopqrstuvwxyz_@.';
	      FMT_EMAIL_BEGIN  = 'abcdefghijklmnopqrstuvwxyz_';

	      FMT_REALNAME = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789&. @';

	      MAXLEN_USER      = 16;
	      MAXLEN_GROUP     = 30;
	      MAXLEN_REALNAME  = 64;
	      MAXLEN_EMAIL     = 96;
	      MAXLEN_HOST      = 64;
	      MAXLEN_SERVICE   = 16;
	      MAXLEN_SERVICEOPTION = 45;
	      MINLEN_PAM2_PASSWORD = 6;

	      ENTITY_USER           = 0;
	      ENTITY_HOST           = 1;
	      ENTITY_GROUP          = 2;
	      ENTITY_SERVICE        = 3;
	      ENTITY_SERVICE_OPTION = 4;
	      ENTITY_EMAIL          = 5;
	      ENTITY_REAL_NAME      = 6;


	function is_username( value: AnsiString ): boolean;
	begin
		if ( length( value ) = 0 ) or ( length(value) > MAXLEN_USER ) 
		    or ( not str_match_chars( value, FMT_USER ) )
		    or ( not str_match_chars( value[1], FMT_USER_BEGIN ) )
			then result := FALSE
			else result := TRUE;
	end;

	function is_groupname( value: AnsiString ): boolean;
	begin
		if ( length( value ) = 0 ) or ( length(value) > MAXLEN_GROUP ) 
			or ( not str_match_chars(value, FMT_GROUP ) )
			or ( not str_match_chars(value[1], FMT_GROUP_BEGIN ) )
			then result := FALSE
			else result := TRUE;
	end;

	function is_servicename( value: AnsiString ): boolean;
	begin
		if ( length( value ) = 0 ) or ( length(value) > MAXLEN_SERVICE ) 
			or ( not str_match_chars( value, FMT_SERVICE ) )
			or ( not str_match_chars( value[1], FMT_SERVICE_BEGIN ))
			then result := FALSE
			else result := TRUE;
	end;

	function is_hostname( value: AnsiString ): boolean;
	begin
		if ( length( value ) = 0 ) or ( length(value) > MAXLEN_HOST ) 
			or ( not str_match_chars( value, FMT_HOST ) )
			or ( not str_match_chars( value[1], FMT_HOST_BEGIN ) )
			then result := FALSE
			else result := TRUE;
	end;

	function is_serviceoption( value: AnsiString ): boolean;
	begin
		if ( length( value ) = 0 ) or ( length(value) > MAXLEN_SERVICEOPTION ) 
			or ( not str_match_chars( value, FMT_SERVICEOPTION ) )
			or ( not str_match_chars( value[1], FMT_SERVICEOPTION_BEGIN ) )
			then result := FALSE
			else result := TRUE;
	end;

	function is_realName( value: AnsiString ): Boolean;
	begin
		if ( length( value ) = 0 ) or ( length(value) > MAXLEN_REALNAME )
			or ( not str_match_chars( value, FMT_REALNAME ) )
			then result := FALSE
			else result := TRUE;
	end;

	function is_email( value: AnsiString ): boolean;
	
	var numMonkeys: Integer;
	    minDot: Integer;
	    maxDot: Integer;
	    minMonkeyPos: Integer;
	    i: Integer;
	    len: Integer;

	begin

		numMonkeys := 0;

		minDot := -1;
		maxDot := -1;
		minMonkeyPos := -1;

		len := length(value);

		if ( len < 3 ) or ( len > MAXLEN_EMAIL ) 
			or ( not str_match_chars( value, FMT_EMAIL ) )
			or ( not str_match_chars( value, FMT_EMAIL_BEGIN ) )
			then result := FALSE
			else result := TRUE;

		if ( result = TRUE ) then
		begin

			for i := 0 to len - 1 do
			begin

				case value[i] of
					
					'@': begin
						numMonkeys := numMonkeys + 1;
						if ( minMonkeyPos = -1 ) then
							minMonkeyPos := i;
					end;

					'.': begin
						
						if ( minDot = -1 ) then
							minDot := i;

						if ( maxDot < i ) then
							maxDot := i;

					end;

				end;

			end;

			if ( minMonkeyPos < 1 ) or ( numMonkeys <> 1 ) or ( minDot = minMonkeyPos - 1 ) or
			   ( maxDot = len - 1 ) 
			   then result := FALSE;

		end;

	end;

	function normalize( value: AnsiString; entityType: Byte ): AnsiString;
	begin
		
		if entityType <> ENTITY_REAL_NAME
			then result := LowerCase( trim( value ) )
			else result := trim( value );

		case entityType of
				ENTITY_USER           : if ( not is_username( result ) ) then result := '';
				ENTITY_GROUP          : if ( not is_groupname( result ) ) then result := '';
				ENTITY_SERVICE        : if ( not is_servicename( result ) ) then result := '';
				ENTITY_HOST           : if ( not is_hostname( result ) ) then result := '';
				ENTITY_SERVICE_OPTION : if ( not is_serviceoption( result ) ) then result := '';
				ENTITY_REAL_NAME      : if ( not is_realname( result ) ) then result := ''
			else result := '';
		end;

		if ( ( result = 'to' ) or ( result = 'for' ) or ( result = 'from' ) or ( result = 'on' ) ) 
		     and ( ( entityType = ENTITY_USER ) or ( entityType = ENTITY_GROUP ) )

		then result := '';

	end;


	constructor TPam2DB.Create( _db: TSqlConnection );
	begin

		db := _db;

		setLength( hosts, 0 );
		setLength( services, 0 );
		setLength( groups, 0 );
		setLength( users, 0 );
		
		setLength( sqlStatements, 0 );
		setLength( explanations, 0 );
		setLength( errors, 0 );
		setLength( snapshot, 0 );

		Console.log('Loading PAM2DB');

		Load();

	end;

	function TPam2DB.createContext( userName: ansiString; password: AnsiString ): TPam2ExecutionContext;
	var mdPwd : AnsiString;
		user  : TPam2User;
	begin

		result := NIL;

		user := getUserByName( userName );

		if user = NIL then
			raise Exception.Create( 'User "' + userName + '" not found!' );

		if user.enabled = FALSE then
			raise Exception.Create( 'Account disabled' );

		mdPwd := encryptPassword( password );

		if mdPwd <> user.password then
			raise Exception.Create( 'Bad password' );

		console.log( user.loginName, user.admin );

		result := TPam2ExecutionContext.Create( self, user.admin, user.id );

	end;

	function TPam2DB.getAllUsersList(): TStrArray;
	var i: Integer;
	    len: Integer;
	begin

		len := Length( users );
		setLength( result, len );
		
		for i := 0 to len - 1 do
		begin
			result[ i ] := users[i].loginName;
		end;

	end;

	procedure TPam2DB.createSnapshot();
	
	var i: Integer;
	    len: Integer;

	begin

		Console.notice( 'TPam2DB: Snapshot Begin' );

		if length( snapshot ) > 0 then
			raise Exception.Create( 'Another snapshot is allready made!' );

		len := Length( hosts );

		for i := 0 to len - 1 do
			hosts[i].snapshot();

		len := Length( services );

		for i := 0 to len - 1 do
			services[i].snapshot();

		len := Length( groups );

		for i := 0 to len - 1 do
			groups[i].snapshot();

		len := Length( users );

		for i := 0 to len - 1 do
			users[i].snapshot();

		Console.notice( 'TPam2DB: Snapshot Ended (' + IntToStr( Length( snapshot ) ) + ' lines)' );

	end;

	procedure TPam2DB.debugSnapshot();
	var i: Integer;
	    len: Integer;
	begin
		len := Length(snapshot);

		Console.notice( 'DEBUG SNAPSHOT BEGIN' );
		
		for i:= 0 to Len - 1 do 
			Console.notice( i, snapshot[i] );

		Console.notice( 'DEBUG SNAPSHOT END' );

	end;

	procedure TPam2DB.discardSnapshot();
	begin

		if Length( snapshot ) > 0 then
		begin

			Console.notice( 'TPam2DB: Discarding spanshot' );
			setLength( snapshot, 0 );
			Console.notice( 'TPam2DB: Snapshot discarded' );

		end else
		begin
			Console.notice( 'TPam2DB: Discarding snapshot: nothing to discard' );
		end;

	end;

	function TPam2DB.fetchSQLStatementResultAsInt( statement: AnsiString ): Integer;
	var FTransaction: TSQLTransaction;
	    FQuery: TSqlQuery;
	    I: Integer;
	begin

		result := -1;

		FTransaction := NIL;
		FQuery := NIL;

		try

			if not db.Connected then
				db.Connected := TRUE;

			FTransaction := TSQLTransaction.Create( NIL );
			FTransaction.Database := db;
			FTransaction.StartTransaction;

			FQuery := TSqlQuery.Create( NIL );
			FQuery.Database := db;
			FQuery.Transaction := FTransaction;
			FQuery.ReadOnly := TRUE;

			FQuery.SQL.Clear();
			FQuery.SQL.Add( statement );
			FQuery.Open;

			I := 0;

			while ( not FQuery.EOF ) do
			begin
				
				if ( i = 0 ) then
				begin

					result := FQuery.Fields[ 0 ].AsInteger;

				end;

				i := I + 1;

				FQuery.Next;
			end;



			FTransaction.Free;
			FQuery.Free;

		except

			On E: Exception Do
			Begin


				if FTransaction <> NIL then
					FTransaction.Free;

				if FQuery <> NIL then
					FQuery.Free;

				Console.error( 'Database error: ' + E.Message );

			End;

		end;

	end;

	procedure TPam2DB.doSQLStatement( statement: AnsiString );
	
	var FTransaction: TSQLTransaction;
		FQuery: TSQLQuery;

    begin

    	FTransaction := NIL;
    	FQuery := NIL;

    	try

	    	if not db.Connected then
	    		db.Connected := TRUE;

	    	FTransaction := TSQLTransaction.Create( NIL );
	    	FQuery := TSQLQuery.Create( NIL );

			FTransaction.Database := db;
			FTransaction.StartTransaction;

			FQuery.Database := db;
			FQuery.Transaction := FTransaction;
			FQuery.SQL.Clear;
			FQuery.SQL.Add( statement );
			FQuery.ExecSQL;

			FTransaction.CommitRetaining;

			FTransaction.Free;
			FQuery.Free;

		except

			On E: Exception Do
			begin

				if FTransaction <> NIL then
					FTransaction.Free;

				if FQuery <> NIL then
					FQuery.Free;

				raise;

			end;

		end;

	end;

	procedure TPam2DB.commit();
	var len: Integer;
	    i: Integer;
	begin
		console.warn( 'COMMITING TO DATABASE BEGIN!' );

		len := Length(users);
		for i := 0 to Len - 1 do users[i].save();

		len := Length(groups);
		for i := 0 to Len - 1 do groups[i].save();

		len := Length(hosts);
		for i := 0 to Len - 1 do hosts[i].save();

		len := Length(services);
		for i := 0 to Len - 1 do services[i].save();

		console.log( 'COMMIT: ' + IntToStr( Length( sqlStatements ) ) + ' statements' );

		len := Length( sqlStatements );

		for i := 0 to len - 1 do
		begin
			
			doSQLStatement( sqlStatements[ i ] );

		end;

		setLength( sqlStatements, 0 );

		console.log( 'COMMIT: DONE' );

	end;

	procedure TPam2DB.rollbackSnapshot();
	
	var i: Integer;
	    len: Integer;
	    dLen: Integer;

	    cUser: TPam2User;       // 1
	    cGroup: TPam2Group;     // 2
	    cHost: TPam2Host;       // 3
	    cService: TPam2Service; // 4

	    dispatchTo: Byte;

	begin

		// FREE ALL RESOURCES SILENTLY

		Console.notice( 'TPam2DB: Rollback Begin' );

		// FREE HOSTS

		len := Length( hosts );

		for i:= 0 to len - 1 do
			hosts[i].FreeWithoutSaving();

		setLength( hosts, 0 );

		// FREE SERVICES

		len := Length( services );

		for i:= 0 to Len - 1 do
			services[i].FreeWithoutSaving();

		setLength( services, 0 );

		// FREE GROUPS

		len := Length( groups );

		for i:= 0 to len - 1 do
			groups[ i ].FreeWithoutSaving();

		setLength( groups, 0 );

		// FREE USERS

		len := Length( users );

		for i:= 0 to len - 1 do
			users[ i ].FreeWithoutSaving();

		setLength( users, 0 );

		// ROLLBACK

		len := Length( snapshot );

		dispatchTo := 0;

		for i := 0 to len - 1 do
		begin

			if snapshot[i] = 'USER' then
			begin

				dLen := Length( users );
				setLength( users, dLen + 1 );
				users[ dLen ] := TPam2User.Create( self );
				cUser := users[ dLen ];
				dispatchTo := 1;

			end else
			
			if snapshot[i] = 'GROUP' then
			begin

				dLen := Length( groups );
				setLength( groups, dLen + 1 );
				groups[ dLen ]:= TPam2Group.Create( self );
				cGroup := groups[ dLen ];
				dispatchTo := 2;

			end else

			if snapshot[i] = 'SERVICE' then
			begin

				dLen := Length( services );
				setLength( services, dLen + 1 );
				services[ dLen ] := TPam2Service.Create( self );
				cService := services[ dLen ];
				dispatchTo := 4;

			end else

			if snapshot[i] = 'HOST' then
			begin

				dLen := Length( hosts );
				setLength( hosts, dLen + 1 );
				hosts[ dLen ] := TPam2Host.Create( self );
				cHost := hosts[ dLen ];
				dispatchTo := 3;

			end else

			if snapshot[i] = 'END' then
			begin

				dispatchTo := 0;

			end else
			
			begin

				case dispatchTo of
					1: cUser.rollback( snapshot[i] );
					2: cGroup.rollback( snapshot[i] );
					3: cHost.rollback( snapshot[i] );
					4: cService.rollback( snapshot[i] )
					else raise Exception.Create( 'Bad rollback dispatch state (' + IntToStr( dispatchTo ) + ')' );
				end;

			end;

		end;

		setLength( snapshot, 0 );

		Console.notice( 'TPam2DB: Rollback Ended' );

	end;

	function TPam2DB.getUserById( userId: Integer ): TPam2User;
	var i: Integer; len: Integer;
	begin
		result := NIL;
		len := Length(users);
		for i:=0 to len - 1 do
			begin
				if users[i].id = userId then
				begin
					result := users[i];
					break;
				end;
			end;
	end;

	function TPam2DB.getGroupById( groupId: Integer ): TPam2Group;
	var i: Integer; len: Integer;
	begin
		result := NIL;
		len := Length(groups);
		for i := 0 to len - 1 do
			begin
				if groups[i].id = groupId then
				begin
					result := groups[i];
					break;
				end;
			end;
	end;

	function TPam2DB.getHostById( hostId: Integer ): TPam2Host;
	var i: Integer; len: Integer;
	begin
		result := NIL;
		len := length( hosts );
		for i := 0 to len - 1 do
			begin
				if hosts[i].id = hostId then
				begin
					result := hosts[i];
					break;
				end;
			end;
	end;

	function TPam2DB.getServiceById( serviceId: Integer ): TPam2Service;
	var i: Integer; Len: Integer;
	begin
		result := NIL;
		len := length( services );
		for i := 0 to len - 1 do
			begin
				if services[i].id = serviceId then
				begin
					result := services[i];
					break;
				end;
			end;
	end;

	function TPam2DB.getUserByName( loginName: AnsiString ): TPam2User;
	var uName: AnsiString;
	    i: Integer; Len: Integer;
	begin
		result := NIL;
		uName := normalize( loginName, ENTITY_USER );
		if ( uName <> '' ) then
		begin
			len := length(users);
			for i := 0 to len - 1 do begin
				if users[i].loginName = uName then
				begin
					result := users[i];
					break;
				end;
			end;
		end;
	end;

	function TPam2DB.getGroupByName( groupName: AnsiString ): TPam2Group;
	var gName: AnsiString;
	    i: Integer; Len: Integer;
	begin
		result := NIL;
		gName := normalize( groupName, ENTITY_GROUP );
		if gName <> '' then
		begin
			len := length(groups);
			for i := 0 to len - 1 do begin
				if groups[i].groupName = gName then
				begin
					result := groups[i];
					break;
				end;
			end;
		end;
	end;

	function TPam2DB.getHostByName( hostName: AnsiString ): TPam2Host;
	var hName: AnsiString;
	    i: Integer; Len: Integer;
	begin
		result := NIL;
		hName := normalize( hostName, ENTITY_HOST );
		if ( hName <> '' ) then
		begin
			len := length(hosts);
			for i := 0 to len - 1 do begin
				if hosts[i].hostName = hName then
				begin
					result := hosts[i];
					break;
				end;
			end;
		end;
	end;

	function TPam2DB.getServiceByName( serviceName: AnsiString ): TPam2Service;
	var sName: AnsiString;
		i: Integer; Len: Integer;
	begin
		result := NIL;
		sName := normalize( serviceName, ENTITY_SERVICE );
		if ( sName <> '' ) then
		begin
			len := length( services );
			for i:=0 to len - 1 do begin
				if services[i].serviceName = sName then
				begin
					result := services[i];
					break;
				end;
			end;
		end;
	end;

	function TPam2DB.getUserByEmail( emailAddress: AnsiString ): TPam2User;
	var lEmail: AnsiString;
		i: Integer; Len: Integer;
	begin
		lEmail := normalize( emailAddress, ENTITY_EMAIL );
		if lEmail <> '' then
		begin
			len := length( users );
			for i := 0 to len - 1 do begin
				if users[i].email = lEmail then
					begin
						result := users[i];
						break;
					end;
			end;
		end;
	end;

	function TPam2DB.userExists ( userName: AnsiString; const ignoreUserId: integer = 0 ): Boolean;
	var user: TPam2User;
	begin
		user := getUserByName( userName );
		if user = NIL 
			then result := FALSE
			else begin
				if user.id = ignoreUserId
					then result := FALSE
					else result := TRUE;
			end;
	end;

	function TPam2DB.userExists ( userId: Integer; const ignoreUserId: integer = 0 ): Boolean;
	var user: TPam2User;
	begin
		user := getUserById( userId );
		if user = NIL 
			then result := FALSE
			else begin
				if user.id = ignoreUserId
					then result := FALSE
					else result := TRUE;
			end;
	end;

	function TPam2DB.userExistsByEmail( emailAddress: string; const ignoreUserId: integer = 0 ): Boolean;
	var user: TPam2User;
	begin
		user := getUserByEmail( emailAddress );
		if user = NIL
			then result := FALSE
			else begin
				if user.id = ignoreUserId
					then result := FALSE
					else result := TRUE;
			end;
	end;

	// TODO!
	function TPam2DB.generateRandomUserPassword(): AnsiString;
	begin
		result := '*&*@123&*231';
	end;

	function TPam2DB.groupExists ( groupName: AnsiString; const ignoreGroupId: integer = 0 ): Boolean;
	var group: TPam2Group;
	begin
		group := getGroupByName( groupName );
		if group = NIL
			then result := FALSE
			else begin
				if group.id = ignoreGroupId
					then result := FALSE
					else result := TRUE;
			end;
	end;

	function TPam2DB.groupExists ( groupId: Integer; const ignoreGroupId: integer = 0 ): Boolean;
	var group: TPam2Group;
	begin
		group := getGroupById( groupId );
		if group = NIL
			then result := FALSE
			else begin
				if group.id = ignoreGroupId
					then result := FALSE
					else result := TRUE;
			end;
	end;

	function TPam2DB.hostExists ( hostName: AnsiString; const ignoreHostId: integer = 0 ): Boolean;
	var host: TPam2Host;
	begin
		host := getHostByName( hostName );
		if host = NIL
			then result := FALSE
			else begin
				if host.id = ignoreHostId
					then result := FALSE
					else result := TRUE;
			end;
	end;

	function TPam2DB.hostExists ( hostId: Integer; const ignoreHostId: integer = 0 ): Boolean;
	var host: TPam2Host;
	begin
		host := getHostById( hostId );
		if host = NIL
			then result := FALSE
			else begin
				if host.id = ignoreHostId
					then result := FALSE
					else result := TRUE;
			end;
	end;

	function TPam2DB.serviceExists ( serviceName: AnsiString; const ignoreServiceId: integer = 0 ): Boolean;
	var service: TPam2Service;
	begin
		service := getServiceByName( serviceName );
		if service = NIL
			then result := FALSE
			else begin
				if service.id = ignoreServiceId
					then result := FALSE
					else result := TRUE;
			end;
	end;

	function TPam2DB.serviceExists ( serviceId: Integer; const ignoreServiceId: integer = 0 ): Boolean;
	var service: TPam2Service;
	begin
		service := getServiceById( serviceId );
		if service = NIL
			then result := FALSE
			else begin
				if service.id = ignoreServiceId
					then result := FALSE
					else result := TRUE;
			end;
	end;

	function TPam2DB.getDefaultHost(): TPam2Host;
	var i: Integer; Len: Integer;
	begin
		result := NIL;
		len := Length( hosts );
		for i := 0 to Len - 1 do begin
			if hosts[i].default then
			begin
				result := hosts[i];
				break;
			end;
		end;
	end;

	procedure TPam2DB.addSQLStatement( statement: AnsiString );
	var len: Integer;
	begin
		
		len := Length( sqlStatements );

		setLength( sqlStatements, len + 1 );
		sqlStatements[ len ] := statement;
	end;

	procedure TPam2DB.addExplanation ( explanation: AnsiString );
	var len: Integer;
	begin
		len := Length( explanations );

		setLength( explanations, len + 1 );
		explanations[ len ] := explanation;

	end;

	procedure TPam2DB.addError ( error: AnsiString );
	var len: Integer;
	begin
		len := Length( errors );

		setLength( errors, len + 1 );
		errors[ len ] := error;

	end;

	procedure TPam2DB.addSnapshot( line: AnsiString );
	var len: Integer;
	begin
		len := Length( snapshot );
		setLength( snapshot, len + 1 );
		snapshot[ len ] := line;
	end;

	function TPam2DB.createUser ( 
			loginName: AnsiString; 
			const realName: AnsiString = ''; 
			const emailAddress: AnsiString = ''; 
			const enabled: boolean = TRUE; 
			const isAdmin: boolean = FALSE; 
			const password: AnsiString = ''
		): TPam2User;

	var lName: AnsiString;
	    lEmail: AnsiString;
	    lRName: AnsiString;
	    lPassword: AnsiString;
	    error: Boolean;

	    len: Integer;

	begin
		
		result := NIL;
		error := FALSE;
		
		lName := normalize( loginName, ENTITY_USER );

		if lName = '' then
		begin
			addError('Invalid user name "' + loginName + '"' );
			error := TRUE;
		end else
		if userExists( lName ) then
		begin
			addError('An user with the same login name "' + lName + '" allready exists!' );
			error := TRUE;
		end else
		begin
			
			// check for email duplicate
			lEmail := normalize( emailAddress, ENTITY_EMAIL );

			if ( lEmail <> '' ) and ( emailAddress <> '' ) then
			begin

				addError('Invalid email address provided while attempting to create account "' + lName + '"' );
				error := TRUE;

			end else
			if lEmail <> '' then
			begin

				if userExistsByEmail( lEmail ) then
				begin
					addError( 'Email address is allready used!' );
					error := TRUE;
				end

			end;

			if error = FALSE then
			begin

				if password <> '' then
				begin
					
					// check password
					lPassword := password;

					if length( lPassword ) < MINLEN_PAM2_PASSWORD then
					begin
						addError('Password is too short!');
						error := TRUE;
					end else
					begin
						lPassword := encryptPassword( lPassword );
					end;

				end else
				begin

					lPassword := encryptPassword( generateRandomUserPassword() );

				end;

			end;

			if ( error = FALSE ) AND ( realName <> '' ) then
			begin

				lRName := normalize( realName, ENTITY_REAL_NAME );

				if lRname = '' then begin
					addError( 'Invalid "Real Name" field' );
					error := TRUE;
				end;

			end else
			begin
				lRName := '';
			end;

		end;

		if error = FALSE then
		begin

			len := length( users );
			setLength( users, len + 1 );

			addExplanation( 'Create user "' + loginName + '"' );

			// TPam2User.Create( _db: TPam2DB; uid: integer; login_name: AnsiString; real_name: AnsiString; user_email: AnsiString; user_enabled: boolean; is_admin: boolean; pam2_password: AnsiString; isSaved: boolean );
			users[ len ] := TPam2User.Create( self, 0, lName, lRName, lEmail, enabled, isAdmin, lPassword, FALSE );

			result := users[ len ];

		end;

	end;

	function TPam2DB.createGroup ( 
			groupName: AnsiString;
			const enabled: boolean = TRUE 
		): TPam2Group;

	var lGroupName: AnsiString;
		len: Integer;
	
	begin
		
		result := NIL;

		lGroupName := normalize( groupName, ENTITY_GROUP );

		if lGroupName = '' then
		begin
			addError('Invalid group name "' + groupName + '"' );
		end else
		if groupExists( lGroupName ) then
		begin
			addError( 'A group with the same name ("' + groupName + '") allready exists' );
		end else
		begin
			len := Length( groups );
			
			setLength( groups, len + 1 );

			addExplanation( 'Create group "' + groupName + '"' );

			groups[ len ] := TPam2Group.Create( self, 0, lGroupName, enabled, FALSE );

			result := groups[ len ];

		end;


	end;

	function TPam2DB.createHost ( 
			hostName: AnsiString; 
			const isDefault: Boolean = false 
		): TPam2Host;

	var lHostName: AnsiString;
	    len: Integer;
	    dHost: TPam2Host;

	begin

		result := NIL;

		lHostName := normalize( hostName, ENTITY_HOST );

		if lHostName = '' then
		begin
			addError('Invalid host name: "' + hostName + '"' );
		end else
		if hostExists( lHostName ) = TRUE then
		begin
			addError('A host with the same name ("' + lHostName + '") allready exists!' );
		end else
		begin
			len := Length( hosts );
			setLength( hosts, len + 1 );

			if isDefault then begin

				dHost := defaultHost;

				if dHost <> NIL then
				begin
					dHost.default := FALSE;
				end; 

				addExplanation( 'Create DEFAULT host "' + hostName + '"' );

			end else
			begin
				
				addExplanation( 'Create host "' + hostName + '"' );
			
			end;

			hosts[ len ] := TPam2Host.Create( self, 0, lHostName, isDefault, FALSE );

			result := hosts[ len ];

		end;

	end;

	function TPam2DB.createService ( 
			serviceName: AnsiString 
		): TPam2Service;

	var lServiceName: AnsiString;
		Len: Integer;

	begin

		result := NIL;

		lServiceName := normalize( serviceName, ENTITY_SERVICE );

		if lServiceName = '' then
		begin
			addError( 'Invalid service name "' + serviceName + '"' );
		end else
		if serviceExists( lServiceName ) then
		begin
			addError( 'A service with the same name ("' + lServiceName + '") allready exists!' );
		end else
		begin

			Len := Length( services );

			setLength( services, Len + 1 );

			addExplanation( 'Create a new service called "' + serviceName + '"' );

			services[ len ] := TPam2Service.Create( self, 0, lServiceName, FALSE );

			result := services[ len ];

		end;

	end;


	// Returns lowercase of md5ed password
	function TPam2DB.encryptPassword( password: AnsiString ): AnsiString;
	begin
		result := LowerCase( md5Print( md5String( password ) ) );
	end;

	procedure TPam2DB.Load();

	var FTransaction: TSQLTransaction;
	    FQuery: TSQLQuery;
	    I: Integer;

	begin

		try // Finally try

		try // Catch try


/// LOADING USERS

			FTransaction := TSQLTransaction.Create(NIL);

			with FTransaction do
			begin
				Database := db;
				StartTransaction;
			end;

			FQuery := TSQLQuery.Create(NIL);
			with FQuery do
			begin
				Database := db;
				Transaction := FTransaction;
				ReadOnly := TRUE;
				SQL.Clear;
				SQL.Add('SELECT user_id, login_name, real_name, email, user_enabled, is_admin, password FROM user' );
			end;

			FQuery.Open;

			i := 0;

			While not FQuery.EOF do
			begin
				setLength( users, i + 1 );

				//uid: integer; login_name: AnsiString; real_name: AnsiString; user_email: AnsiString; user_enabled: boolean; is_admin: boolean; pam2_password: AnsiString; isSaved: boolean
				users[ i ] := TPam2User.Create(
					self,
					FQuery.FieldByName( 'user_id' ).asInteger,
					FQuery.FieldByName( 'login_name' ).asString,
					FQuery.FieldByName( 'real_name' ).asString,
					FQuery.FieldByName( 'email' ).asString,
					Boolean( FQuery.FieldByName( 'user_enabled' ).asInteger ),
					Boolean( FQuery.FieldByName( 'is_admin' ).asInteger ),
					LowerCase( FQuery.FieldByName( 'password' ).asString ),
					TRUE
				);

				i := i + 1;

				FQuery.Next;

			end;

			FQuery.Free;
			FTransaction.Free;


/// LOADING GROUPS

			FTransaction := TSQLTransaction.Create(NIL);

			with FTransaction do
			begin
				Database := db;
				StartTransaction;
			end;

			FQuery := TSQLQuery.Create(NIL);
			with FQuery do
			begin
				Database := db;
				Transaction := FTransaction;
				ReadOnly := TRUE;
				SQL.Clear;
				SQL.Add('SELECT group_id, group_name, group_enabled FROM `group`' );
			end;

			FQuery.Open;

			i := 0;

			While not FQuery.EOF do
			begin
				setLength( groups, i + 1 );

				
				// _db: TPam2DB; gid: integer; group_name: AnsiString; isSaved: boolean
				groups[ i ] := TPam2Group.Create(
					self,
					FQuery.FieldByName( 'group_id' ).asInteger,
					FQuery.FieldByName( 'group_name' ).asString,
					Boolean( FQuery.FieldByName('group_enabled').asInteger ),
					TRUE
				);

				i := i + 1;

				FQuery.Next;

			end;

			FQuery.Free;
			FTransaction.Free;

/// LOADING HOSTS

			FTransaction := TSQLTransaction.Create(NIL);

			with FTransaction do
			begin
				Database := db;
				StartTransaction;
			end;

			FQuery := TSQLQuery.Create(NIL);
			with FQuery do
			begin
				Database := db;
				Transaction := FTransaction;
				ReadOnly := TRUE;
				SQL.Clear;
				SQL.Add('SELECT id, name, `default` FROM `host`' );
			end;

			FQuery.Open;

			i := 0;

			While not FQuery.EOF do
			begin
				setLength( hosts, i + 1 );

				
				// _db: TPam2DB; hid: integer; hname: AnsiString; defaultHost: boolean; isSaved: boolean
				hosts[ i ] := TPam2Host.Create(
					self,
					FQuery.FieldByName( 'id' ).asInteger,
					FQuery.FieldByName( 'name' ).asString,
					Boolean(FQuery.FieldByName('default').asInteger),
					TRUE
				);

				i := i + 1;

				FQuery.Next;

			end;

			FQuery.Free;
			FTransaction.Free;

/// LOADING SERVICES

			FTransaction := TSQLTransaction.Create(NIL);

			with FTransaction do
			begin
				Database := db;
				StartTransaction;
			end;

			FQuery := TSQLQuery.Create(NIL);
			with FQuery do
			begin
				Database := db;
				Transaction := FTransaction;
				ReadOnly := TRUE;
				SQL.Clear;
				SQL.Add('SELECT service_id, service_name FROM `service`' );
			end;

			FQuery.Open;

			i := 0;

			While not FQuery.EOF do
			begin

				setLength( services, i + 1 );
				
				// _db: TPam2DB; sid: integer; sname: AnsiString; isSaved: boolean
				services[ i ] := TPam2Service.Create(
					self,
					FQuery.FieldByName( 'service_id' ).asInteger,
					FQuery.FieldByName( 'service_name' ).asString,
					TRUE
				);

				i := i + 1;

				FQuery.Next;

			end;

			FQuery.Free;
			FTransaction.Free;

/// DISPLAY STATS

			Console.log('-', Length(users), 'users' );
			Console.log('-', Length(groups), 'groups' );
			Console.log('-', Length(hosts), 'hosts' );
			Console.log('-', Length(services), 'services' );

		except

			On E: Exception do
			begin
				Console.error( 'General Exception: ', E.Message );
				raise;
			end;

		end;

		finally

		end;


	end;

	destructor TPam2DB.Free();
	var i: integer;
	    len: integer;
	begin

		// FREE ENTITIES

		len := length( hosts );
		
		for i:=0 to len-1 do
			hosts[i].Free();

		setLength( hosts, 0 );

		len := length( services );

		for i:= 0 to len - 1 do
			services[i].Free();

		setLength( services, 0 );

		len := length( groups );

		for i := 0 to len - 1 do
			groups[i].Free();

		setLength( groups, 0 );

		len := length( users );

		for i := 0 to len - 1 do
			users[i].Free();

		setLength( users, 0 );

		setLength( sqlStatements, 0 );
		setLength( explanations, 0 );
		setLength( errors, 0 );

	end;

	constructor TPam2User.Create( _db: TPam2DB; uid: integer; login_name: AnsiString; real_name: AnsiString; user_email: AnsiString; user_enabled: boolean; is_admin: boolean; pam2_password: AnsiString; isSaved: boolean );
	begin
		saved := isSaved;
		needSave := not saved;
		deleted := false;

		db := _db;

		_user_id := uid;
		_login_name := login_name;
		_real_name := real_name;
		_email := user_email;
		_enabled := user_enabled;
		_password := pam2_password;
		_admin := is_admin;

		setLength( _groups, 0 );
		setLength( _passwords, 0 );

	end;

	constructor TPam2User.Create( _db: TPam2DB );
	begin
		saved := TRUE;
		needSave := FALSE;
		deleted := FALSE;
		db := _db;

		_user_id := 0;
		_login_name := '';
		_real_name := '';
		_email := '';
		_enabled := FALSE;
		_password := '';

		setLength( _groups, 0 );
		setLength( _passwords, 0 );
	end;

	function TPam2User.Save(): boolean;
	begin
		result := true;
		needSave := FALSE;
	end;

	destructor TPam2User.Free();
	begin

		if needSave = TRUE then
			Save();

		FreeWithoutSaving();

	end;

	destructor TPam2User.FreeWithoutSaving();
	begin

		setLength( _groups, 0 );
		setLength( _passwords, 0 );

	end;

	procedure TPam2User.snapshot();
	begin

		db.addSnapshot( 'USER' );
		db.addSnapshot( '_user_id: '     + IntToStr( _user_id ) );
		db.addSnapshot( '_login_name: '  + _login_name );
		db.addSnapshot( '_real_name: '   + _real_name );
		db.addSnapshot( '_email: '       + _email );
		db.addSnapshot( '_enabled: '     + IntToStr( Integer( _enabled ) ) );
		db.addSnapshot( '_password: '    + _password );
		db.addSnapshot( '_admin: '       + IntToStr( Integer( _admin ) ) );
		db.addSnapshot( 'saved: '        + IntToStr( Integer( saved ) ) );
		db.addSnapshot( 'needSave: '     + IntToStr( Integer( needSave ) ) );
		db.addSnapshot( 'deleted: '      + IntToStr( Integer( deleted ) ) );
		db.addSnapshot( 'END' );

	end;

	procedure TPam2User.rollback( snapshotLine: AnsiString );
	var propName: AnsiString;
	    propValue: AnsiString;
	    dotPos: Integer;
	    len: Integer;
	begin

		dotPos := Pos( ':', snapshotLine );

		if dotPos = 0 then begin
			raise Exception.Create( 'TPam2User.rollback: Bad snapshot line ("' + snapshotLine + '"). BUG.' );
			exit;
		end;

		len := Length( snapshotLine );

		propName := copy( snapshotLine, 1, dotPos - 1 );
		propValue := copy( snapshotLine, dotPos + 2, len );

		if propName = '_user_id' then
		begin
			_user_id := StrToInt( propValue );
		end else
		if propName = '_login_name' then
		begin
			_login_name := propValue;
		end else
		if propName = '_real_name' then
		begin
			_real_name := propValue;
		end else
		if propName = '_email' then
		begin
			_email := propValue;
		end else
		if propName = '_enabled' then
		begin
			_enabled := Boolean( StrToInt( propValue ) );
		end else
		if propName = '_password' then
		begin
			_password := propValue;
		end else
		if propName = '_admin' then
		begin
			_admin := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'saved' then
		begin
			saved := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'needSave' then
		begin
			needSave := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'deleted' then
		begin
			deleted := Boolean( StrToInt( propValue ) );
		end else
		raise Exception.Create( 'TPam2User.rollback: don''t know how to restore property: "' + propName + '"!' );

	end;

	procedure TPam2User.setLoginName( value: AnsiString );
	var lName: AnsiString;
	begin
		lName := normalize( value, ENTITY_USER );
		
		if lname = '' then
		begin
			db.addError( '"' + value + '" login name is invalid!' );
		end else
		if lname = _login_name then
		begin
			// return
		end else
		if db.userExists( lName, _user_id ) then
		begin
			db.addError( 'Another user allready exists with login name "' + lName + '"' );
		end else
		begin

			saved := FALSE;
			db.addExplanation( 'Modify login name of user "' + _login_name + '" to "' + lName + '"' );
			_login_name := lName;

		end;
	end;

	procedure TPam2User.setRealName( value: AnsiString );
	var rName: AnsiString;
	begin

		rName := normalize( value, ENTITY_REAL_NAME );

		if ( rName = '' ) then
		begin
			db.addError( '"' + value + '" real name is invalid!' );
		end else
		if rName = _real_name then
		begin
			// return
		end else
		begin
			saved := FALSE;
			db.addExplanation( 'Modify real_name for user "' + _login_name + '" from "' + _real_name + '" to "' + rName + '"' );
			_real_name := rName;
		end;

	end;

	procedure TPam2User.setEmail( value: AnsiString );
	var rMail : AnsiString;
	begin

		rMail := normalize( value, ENTITY_EMAIL );

		if email = '' then
		begin
			db.addError( 'The email address "' + value + '" does not seem to be a good one (for user: "' + _login_name + '")' );
		end else
		if rMail = _email then
		begin
			// return
		end else
		begin
			saved := FALSE;
			db.addExplanation( 'Modify email for user "' + _login_name + '" from "' + _email + '" to "' + rMail + '"' );
			_email := rMail;
		end;

	end;

	procedure TPam2User.setEnabled( value: Boolean );
	begin

		if value <> _enabled then
		begin
			if value = TRUE then
				db.addExplanation( 'Disable user account "' + _login_name + '"' )
			else
				db.addExplanation( 'Enable user account "' + _login_name + '"' );

			_enabled := value;
			
			saved := FALSE;

		end;

	end;

	procedure TPam2User.setAdmin( value: Boolean );
	begin

		if value <> _admin then
		begin

			if _admin = TRUE then
				db.addExplanation( 'Revoke the PAM2 management right for user "' + _login_name + '"' )
			else
				db.addExplanation( 'Grant the PAM2 management right for user "' + _login_name + '"' );

			_admin := value;

			saved := FALSE;

		end;

	end;

	procedure TPam2User.setPassword( value: AnsiString );
	var pVal : AnsiString;
	begin

		if length( value ) = 0 then
		begin
			db.addError( 'Cannot set a null PAM2 password (for user "' + _login_name + ')' );
		end else
		if length( value ) < MINLEN_PAM2_PASSWORD then
		begin
			db.addError( 'The PAM2 password is too short. Minimum password length is ' + IntToStr( MINLEN_PAM2_PASSWORD ) + ' (for user "' + _login_name + '")' );
		end else
		begin
			
			pVal := db.encryptPassword( value );
			
			db.addExplanation( 'Update the PAM2 password for user "' + _login_name + '"' );
			_password := pVal;

			saved := FALSE;

		end;

	end;


	constructor TPam2Group.Create( _db: TPam2DB; gid: integer; group_name: AnsiString; _is_enabled: Boolean; isSaved: boolean );
	begin

		db := _db;

		saved := isSaved;
		needSave := not saved;
		deleted := FALSE;

		_group_id := gid;
		_group_name := group_name;
		_enabled := _is_enabled;

		setLength( _users, 0 );
	end;

	constructor TPam2Group.Create( _db: TPam2DB );
	begin

		db := _db;

		saved := TRUE;
		needSave := FALSE;
		deleted := FALSE;

		_group_id := 0;
		_group_name := '';
		_enabled := FALSE;

		setLength( _users, 0 );

	end;

	procedure TPam2Group.snapshot();
	begin
		db.addSnapshot( 'GROUP' );
		db.addSnapshot( '_group_id: ' + IntToStr( _group_id ) );
		db.addSnapshot( '_group_name: ' + _group_name );
		db.addSnapshot( '_enabled: ' + IntToStr( Integer( _enabled ) ) );
		db.addSnapshot( 'saved: ' + IntToStr( Integer( saved ) ) );
		db.addSnapshot( 'needSave: ' + IntToStr( Integer( needSave ) ) );
		db.addSnapshot( 'deleted: ' + IntToStr( Integer( deleted ) ) );
		db.addSnapshot( 'END' );
	end;

	procedure TPam2Group.rollback( snapshotLine: AnsiString );
	var propName: AnsiString;
	    propValue: AnsiString;
	    dotPos: Integer;
	    len: Integer;
	begin

		dotPos := Pos( ':', snapshotLine );

		if dotPos = 0 then begin
			raise Exception.Create( 'TPam2Group.rollback: Bad snapshot line ("' + snapshotLine + '"). BUG.' );
			exit;
		end;

		len := Length( snapshotLine );

		propName := copy( snapshotLine, 1, dotPos - 1 );
		propValue := copy( snapshotLine, dotPos + 2, len );

		if propName = '_group_id' then
		begin
			_group_id := StrToInt( propValue );
		end else
		if propName = '_group_name' then
		begin
			_group_name := propValue;
		end else
		if propName = '_enabled' then
		begin
			_enabled := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'saved' then
		begin
			saved := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'needSave' then
		begin
			needSave := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'deleted' then
		begin
			deleted := Boolean( StrToInt( propValue ) );
		end else
		raise Exception.Create('TPam2Group.rollback: Don''t know how to restore property "' + propName + '"' );

	end;

	function TPam2Group.Save(): boolean;
	begin

		if ( needSave = FALSE ) then
		begin
			result := TRUE;
		end else
		begin

			if not deleted then
			begin

				if ( _group_id = 0 ) then
				begin
					// DO INSERT
					db.addSQLStatement( 'INSERT INTO `group` ( `group_name`, `group_enabled` ) VALUES ( "' + _group_name + '", ' + IntToStr( Integer( _enabled ) ) + ')' );
				end else
				begin
					// DO UPDATE
					db.addSQLStatement( 'UPDATE `group` SET `group_name` = "' + _group_name + '", `group_enabled` = ' + IntToStr( Integer( _enabled ) ) + ' WHERE `group_id` = ' + IntToStr( _group_id ) + ' LIMIT 1' );
				end;

			end else
			begin

				if ( _group_id > 0 ) then
				begin
					// DO DELETION
					db.addSQLStatement( 'DELETE FROM `group` WHERE `group_id` = ' + IntToStr( _group_id ) + ' LIMIT 1' );
				end;

			end;

			result := TRUE;
			needSave := FALSE;
		
		end;

	end;

	destructor TPam2Group.Free();
	begin

		if ( needSave ) then
			Save();

		FreeWithoutSaving();

	end;

	destructor TPam2Group.FreeWithoutSaving();
	begin

		setLength( _users, 0 );

	end;

	procedure TPam2Group.setGroupName( value: AnsiString );
	var gName: AnsiString;
	begin
		gName := normalize( value, ENTITY_GROUP );
		if gName = '' then
		begin
			db.addError('"' + value + '" is not a valid group name!' );
		end else
		if gName = _group_name then
		begin
			//return
		end else
		if db.groupExists( gName, id ) then
		begin
			db.addError( 'A group with the name "' + gName + '" allready exists!' );
		end else
		begin
			db.addExplanation( 'Rename group "' + _group_name + '" to "' + gName + '"' );
			_group_name := gName;
			saved := FALSE;
		end;
	end;

	procedure TPam2Group.setEnabled( value: boolean );
	begin

		if value <> _enabled then
		begin

			if _enabled then
				db.addExplanation( 'Disable group "' + _group_name + '"' )
			else
				db.addExplanation( 'Enable group "' + _group_name + '"' );

			_enabled := value;
			saved := FALSE;

		end;

	end;

	constructor TPam2Host.Create( _db: TPam2DB; hid: integer; hname: AnsiString; defaultHost: boolean; isSaved: boolean );
	begin

		db := _db;

		saved := isSaved;
		needSave := not saved;
		deleted := FALSE;

		_host_id := hid;
		_host_name := hname;
		_default_host := defaultHost;

		setLength( _services, 0 );

		setLength( _group_policies, 0 );
		setLength( _user_policies, 0 );

		setLength( _service_option_bindings, 0 );
		setLength( _service_useroption_bindings, 0 );
		setLength( _service_groupoption_bindgs, 0 );

	end;

	constructor TPam2Host.Create( _db: TPam2DB );
	begin

		db := _db;

		saved := TRUE;
		needSave := FALSE;
		deleted := FALSE;

		_host_id := 0;
		_host_name := '';
		_default_host := FALSE;

		setLength( _services, 0 );
		setLength( _group_policies, 0 );
		setLength( _service_option_bindings, 0 );
		setLength( _service_useroption_bindings, 0 );
		setLength( _service_groupoption_bindgs, 0 );

	end;

	procedure TPam2Host.snapshot();
	begin
		db.addSnapshot( 'HOST' );
		
		db.addSnapshot( '_host_id: ' + IntToStr( _host_id ) );
		db.addSnapshot( '_host_name: ' + _host_name );
		db.addSnapshot( '_default_host: ' + IntToStr( Integer( _default_host ) ) );

		db.addSnapshot( 'saved: ' + IntToStr( Integer( saved ) ) );
		db.addSnapshot( 'needSave: ' + IntToStr( Integer( needSave ) ) );
		db.addSnapshot( 'deleted: ' + IntToStr( Integer( deleted ) ) );
		
		db.addSnapshot( 'END' );
	end;

	procedure TPam2Host.rollback( snapshotLine: AnsiString );
	var propName: AnsiString;
	    propValue: AnsiString;
	    dotPos: Integer;
	    len: Integer;
	begin

		dotPos := Pos( ':', snapshotLine );

		if dotPos = 0 then begin
			raise Exception.Create( 'TPam2Host.rollback: Bad snapshot line ("' + snapshotLine + '". BUG.' );
			exit;
		end;

		len := Length( snapshotLine );

		propName := copy( snapshotLine, 1, dotPos - 1 );
		propValue := copy( snapshotLine, dotPos + 2, len );

		if propName = '_host_id' then
		begin
			_host_id := StrToInt( propValue );
		end else
		if propName = '_host_name' then
		begin
			_host_name := propValue;
		end else
		if propName = '_default_host' then
		begin
			_default_host := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'saved' then
		begin
			saved := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'needSave' then
		begin
			needSave := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'deleted' then
		begin
			deleted := Boolean( StrToInt( propValue ) );
		end else
		raise Exception.Create('TPam2Host.rollback: Don''t know how to restore property "' + propName + '"' );

	end;

	function TPam2Host.Save(): boolean;
	begin
		result := TRUE;
		needSave := FALSE;
	end;

	destructor TPam2Host.Free();
	begin
		
		if needSave then
			Save();

		FreeWithoutSaving();

	end;

	destructor TPam2Host.FreeWithoutSaving();
	begin
		setLength( _services, 0 );

		setLength( _group_policies, 0 );
		setLength( _user_policies, 0 );

		setLength( _service_option_bindings, 0 );
		setLength( _service_useroption_bindings, 0 );
		setLength( _service_groupoption_bindgs, 0 );
	end;

	procedure TPam2Host.setHostName( value: AnsiString );
	var hName : AnsiString;
	begin
		hName := normalize( value, ENTITY_HOST );
		if hName = '' then
		begin
			db.addError('Invalid host name "' + value + '"' );
		end else
		if hName = _host_name then
		begin
			// return
		end else
		if db.hostExists( hName, id ) then
		begin
			db.addError( 'A host with the same name "' + hName + '" allready exists!' );
		end else
		begin
			db.addExplanation( 'Rename host "' + _host_name + '" to "' + hName + '"' );
			_host_name := hName;
			saved := FALSE;
		end;
	end;

	procedure TPam2Host.setDefaultHost( value: Boolean );
	
	var defaultHost: TPam2Host;
	
	begin

		if value <> _default_host then
		begin

			if value = TRUE then
			begin

				defaultHost := db.defaultHost;

				if defaultHost <> NIL then
					defaultHost.default := FALSE;

				_default_host := TRUE;

				db.addExplanation( 'Set default host to "' + _host_name + '"' );

			end else
			begin

				_default_host := FALSE;

				db.addExplanation( 'Remove the "default host" flag from host "' + _host_name + '"' );

			end;

			saved := FALSE;

		end;

	end;

	function  TPam2Host.getMachineServices(): TStrArray;
	var i: Integer;
	    len: Integer;
	begin

		len := Length( _services );

		setLength( result, Len );

		for i := 0 to len - 1 do
			result[ i ] := _services[ i ].serviceName;

	end;

	procedure TPam2Host.setMachineServices( svcs: TStrArray );
	begin

		raise Exception.Create( 'Not implemented' );

	end;


	constructor TPam2Service.Create( _db: TPam2DB; sid: integer; sname: AnsiString; isSaved: boolean );
	begin

		db := _db;

		saved := isSaved;
		needSave := not saved;
		deleted := FALSE;

		_service_id := sid;
		_service_name := sname;

		setLength( _options, 0 );

	end;

	constructor TPam2Service.Create( _db: TPam2DB );
	begin

		db := _db;

		saved := TRUE;
		needSave := FALSE;
		deleted := FALSE;

		_service_id := 0;
		_service_name := '';

		setLength( _options, 0 );

	end;

	procedure TPam2Service.snapshot();
	begin
		db.addSnapshot( 'SERVICE' );

		db.addSnapshot( '_service_id: ' + IntToStr( _service_id ) );
		db.addSnapshot( '_service_name: ' + _service_name );
		
		db.addSnapshot( 'saved: ' + IntToStr( Integer( saved ) ) );
		db.addSnapshot( 'needSave: ' + IntToStr( Integer( needSave ) ) );
		db.addSnapshot( 'deleted: ' + IntToStr( Integer( deleted ) ) );
		
		db.addSnapshot( 'END' );
	end;

	procedure TPam2Service.rollback( snapshotLine: AnsiString );
	var propName: AnsiString;
	    propValue: AnsiString;
	    dotPos: Integer;
	    len: Integer;
	begin

		dotPos := Pos( ':', snapshotLine );

		if dotPos = 0 then begin
			raise Exception.Create( 'TPam2Service.rollback: Bad snapshot line ("' + snapshotLine + '". BUG.' );
			exit;
		end;

		len := Length( snapshotLine );

		propName := copy( snapshotLine, 1, dotPos - 1 );
		propValue := copy( snapshotLine, dotPos + 2, len );

		if propName = '_service_id' then
		begin
			_service_id := StrToInt( propValue );
		end else
		if propName = '_service_name' then
		begin
			_service_name := propValue;
		end else
		if propName = 'saved' then
		begin
			saved := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'needSave' then
		begin
			needSave := Boolean( StrToInt( propValue ) );
		end else
		if propName = 'deleted' then
		begin
			deleted := Boolean( StrToInt( propValue ) );
		end else
		raise Exception.Create( 'TPam2Service.rollback: Don''t know how to restore property "' + propName + '"' );

	end;

	function TPam2Service.Save(): Boolean;
	begin
		result := TRUE;
		needSave := FALSE;
	end;

	destructor TPam2Service.Free();
	begin

		if ( needSave ) then
			Save();
	
		FreeWithoutSaving();

	end;

	destructor TPam2Service.FreeWithoutSaving();
	begin
		setLength( _options, 0 );
	end;

	procedure TPam2Service.setServiceName( value: AnsiString );
	var sName: AnsiString;
	begin

		sName := normalize( value, ENTITY_SERVICE );

		if sName = '' then
		begin
			db.addError( 'Invalid service name "' + value + '"' );
		end else
		if sName = _service_name then
		begin
			// return
		end else
		if db.serviceExists( sName, id ) then
		begin
			db.addError( 'Another service with the name "' + sName + '" allready exists!' );
		end else
		begin
			db.addExplanation( 'Rename service "' + _service_name + '" to "' + sName + '"' );
			_service_name := sName;
			saved := FALSE;
		end;

	end;

	constructor TPam2ServiceOption.Create(service: TPam2Service; oName: AnsiString; oDefault: AnsiString; oValue: AnsiString; isSaved: Boolean);
	begin
		saved := isSaved;
		needSave := not saved;
		deleted := FALSE;

		_service := service;
		_name := oName;
		_default_value := oDefault;
		_value := oValue;

	end;

	function TPam2ServiceOption.Save(): Boolean;
	begin
		result := TRUE;
		needSave := FALSE;
	end;

	destructor TPam2ServiceOption.Free();
	begin
		if ( needSave ) then
			Save();
	end;

	constructor TPam2ExecutionContext.Create( _db: TPam2DB; isAdmin: Boolean; lockedUserId: Integer );
	begin

		db := _db;
		admin := isAdmin;

		if ( isAdmin ) then
			Console.log( 'Create context with administrative privs' )
		else
			Console.log( 'Create context with limited privs' );

		lockedToUserId := lockedUserId;

	end;

	destructor  TPam2ExecutionContext.Free();
	begin
		db := NIL;
	end;

	function TPam2ExecutionContext.executeQuery( query: TQueryParser ): AnsiString;
	
	var arg: AnsiString;

	begin

		try 

			arg := LowerCase( query.nextArg() );

			if arg = 'service' then
			begin
				result := cmd_service( query );
			end else
			if arg = 'user' then
			begin
				result := cmd_user( query );
			end else
			if arg = 'host' then
			begin
				result := cmd_host( query );
			end else
			if arg = 'group' then
			begin
				result := cmd_group( query );
			end else
			if arg = 'select' then
			begin
				result := cmd_select( query );
			end else
				raise Exception.Create( 'Invalid command: "' + arg + '" ( argument index: 0 )' );

		except

			On E: Exception Do
			begin

				raise;
			end;
		end;
	end;

	const OP_ADD    = 1;
	      OP_REMOVE = 0;

	function TPam2ExecutionContext.cmd_host   ( query: TQueryParser ): AnsiString;
	begin
		raise Exception.Create( 'host command is not implemented' );
	end;

	function TPam2ExecutionContext.cmd_user   ( query: TQueryParser ): AnsiString;
	begin
		raise Exception.Create( 'user command is not implemented' );
	end;

	function TPam2ExecutionContext.cmd_service( query: TQueryParser ): AnsiString;
	begin
		raise Exception.Create( 'service command is not implemented' );
	end;

	function TPam2ExecutionContext.cmd_group  ( query: TQueryParser ): AnsiString;
	
	var operation: byte;
	    arg: AnsiString;

	    groupName: AnsiString; // group name, unnormalized
	    gName: AnsiString;     // normalized group name

	    tokWho: AnsiString;

	    subjects: TStrArray;
	    len: Integer;

	    uArg: AnsiString;

	    isWildCard: Boolean;

	begin
		
		arg := LowerCase( query.nextArg() );

		setLength( subjects, 0 );

		if arg = '' then raise Exception.Create( 'Missing token ( expected "add" or "remove" ), at index 1' );

		if arg = 'add' then
			operation := OP_ADD
		else
		if arg = 'remove' then
			operation := OP_REMOVE
		else
			raise Exception.Create( 'Wrong predicate ( expected "add" or "remove" but got "' + arg + '" ), at index 1' );

		groupName := query.nextArg();
		gName := normalize( groupName, ENTITY_GROUP );

		if groupName = '' then
			raise Exception.Create( 'Missing token ( expected a <group_name> ), at index 2' );

		if gName = '' then
			raise Exception.Create( 'Illegal group name "' + groupName + '", at index 2' );


		arg := LowerCase( query.nextArg() );

		if arg <> '' then
		begin

			if ( arg <> 'to' ) and ( arg <> 'for' ) and ( arg <> 'from' ) then
				raise Exception.Create( 'Illegal token ( expected "to", "for", or "from" ), at index 3 [0]' );

			tokWho := arg;

			arg := LowerCase( query.nextArg() );

			if ( arg = 'user' ) or ( arg = 'users' ) then
			begin

				if ( tokWho <> 'to' ) and ( tokWho <> 'for' ) then
					raise Exception.Create( 'Illegal token "' + tokWho + '" ( expected "to" or "for" ), at index 3 [1]' );

				len := 0;
				isWildCard := FALSE;

				// read subjects ( users )

				repeat

					arg := LowerCase( query.nextArg() );

					uArg := trim( arg );

					if ( uArg = '' ) then 
					begin
						break;
					end else
					if ( uArg = '*' ) then begin
						// Add or remove group to all users.
						if len > 0 then begin
							raise Exception.Create( 'A wildcard ("*") cannot be used in conjunction with other user names!' );
						end else
						begin
							subjects := db.allUsers;
							len := Length( subjects );
							isWildCard := TRUE;
						end;
					end else
					begin

						uArg := normalize( arg, ENTITY_USER );

						if uArg <> '' then
						begin

							if isWildCard then
							begin
								raise Exception.Create( 'A wildcard ("*") cannot be used in conjunction with other user names!' );
							end else
							begin

								console.error( 'ADD: ', uArg );

								len := len + 1;
								setLength( subjects, len );
								subjects[ len - 1 ] := uArg;
							end;

						end else
						begin
							raise Exception.Create('Illegal user name "' + arg + '"' );
						end;

					end;

				until false;

				if ( not isWildCard ) and ( len = 0 ) then
					raise Exception.Create( 'Expected a user list separated by space' );

				if admin = FALSE then
					raise Exception.Create( 'Access denied ( command works only in administrative context )!');

				// Good. We've got the subjects

				if ( operation = OP_ADD ) then
				begin

					if ( isWildCard ) then
					begin

						result := '{"explain": ' + json_encode( 'Make all users (' + IntToStr( len ) + ') members of group "' + gName + '"' ) + '}';

					end else
					begin

						if ( len = 1 ) then
							result := '{"explain": ' + json_encode( 'Make user "' + str_join( subjects, '", "' ) + '" member of group "' + gName + '"' ) + '}'
						else
							result := '{"explain": ' + json_encode( 'Make users "' + str_join( subjects, '", "' ) + '" members of group "' + gName + '"' ) + '}';

					end;

				end else
				begin

					if ( isWildCard ) then
					begin

						result := '{"explain": ' + json_encode( 'Remove all users (' + IntToStr( len ) + ') from group "' + gName + '"' ) + '}';

					end else
					begin

						if ( len = 1 ) then
							result := '{"explain": ' + json_encode( 'Remove user "' + str_join( subjects, '", "' ) + '" from group "' + gName + '"' ) + '}'
						else
							result := '{"explain": ' + json_encode( 'Remove users "' + str_join( subjects, '", "' ) + '" from group "' + gName + '"' ) + '}';

					end;

				end;


			end else
			if ( arg = 'service' ) or ( arg = 'services' ) then
			begin



			end;

		end else
		begin

			if admin = FALSE then
				raise Exception.Create( 'Access denied ( command works only in administrative context )!');

			// ADD GROUP gName to system.
			if ( operation = OP_ADD ) then
			begin

				if db.groupExists( gName ) then
					raise Exception.Create( 'A group with the same name allready exist!' );

				db.createSnapshot();

				try

					db.createGroup( gName );

					db.commit();

					db.discardSnapshot();

					result := '{"explain": ' + json_encode( 'Create group "' + gName + '"' ) + '}';

				except
					On E: Exception do
					begin
						db.rollbackSnapshot();
						raise;
					end
				end;
				

			end else
			begin

				if not db.groupExists( gName ) then
					raise Exception.Create('Group "' + gName + '" does not exist!' );

				result := '{"explain": ' + json_encode( 'Remove group "' + gName + '"' ) + '}';

			end;

		end;



	end;

	function TPam2ExecutionContext.cmd_select ( query: TQueryParser ): AnsiString;
	begin
		raise Exception.Create( 'select command is not implemented' );
	end;

	procedure TPam2User.updateIdAfterInsertion();
	var i: Integer;
	begin
		
		if (not deleted) and (_user_id = 0) then
		begin
			i := db.fetchSQLStatementResultAsInt('SELECT user_id FROM user WHERE login_name = "' + _login_name + '" LIMIT 1' );

			if i > 0 then
			begin
				_user_id := i;
				Console.log('Updated id of user ' + _login_name + ' to ' + IntToStr( _user_id ) );
			end else
			begin
				Console.error('Failed to update id of user ' + _login_name );
			end;
		end;

	end;

	procedure TPam2Service.updateIdAfterInsertion();
	var i: Integer;
	begin
		
		if (not deleted) and (_service_id = 0) then
		begin
			i := db.fetchSQLStatementResultAsInt('SELECT service_id FROM service WHERE service_name = "' + _service_name + '" LIMIT 1' );

			if i > 0 then
			begin
				_service_id := i;
				Console.log('Updated id of service ' + _service_name + ' to ' + IntToStr( _service_id ) );
			end else
			begin
				Console.error('Failed to update id of service ' + _service_name );
			end;
		end;
	end;

	procedure TPam2Group.updateIdAfterInsertion();
	var i: Integer;
	begin
	
		if (not deleted) and (_group_id = 0) then
		begin
			i := db.fetchSQLStatementResultAsInt('SELECT group_id FROM `group` WHERE group_name = "' + _group_name + '" LIMIT 1' );

			if i > 0 then
			begin
				_group_id := i;
				Console.log('Updated id of group ' + _group_name + ' to ' + IntToStr( _group_id ) );
			end else
			begin
				Console.error('Failed to update id of group ' + _group_name );
			end;
		end;
	end;

	procedure TPam2Host.updateIdAfterInsertion();
	var i: Integer;
	begin
	
		if (not deleted) and (_host_id = 0) then
		begin
			i := db.fetchSQLStatementResultAsInt('SELECT id FROM `host` WHERE name = "' + _host_name + '" LIMIT 1' );

			if i > 0 then
			begin
				_host_id := i;
				Console.log('Updated id of host ' + _host_name + ' to ' + IntToStr( _host_id ) );
			end else
			begin
				Console.error('Failed to update id of host ' + _host_name );
			end;
		end;
	end;


initialization
	
	// do some small tests
	if ( normalize(' FOO ', ENTITY_USER ) = '' ) then
	begin
		raise Exception.Create('Assert: normalize(" FOO ", ENTITY_USER) returns empty');
	end;

	if ( normalize(' FOO ', ENTITY_GROUP ) = '' ) then
	begin
		raise Exception.Create('Assert: normalize(" FOO ", ENTITY_GROUP ) returns empty');
	end;

	if ( normalize(' FOO ', ENTITY_SERVICE ) = '' ) then
	begin
		raise Exception.Create('Assert: normalize(" FOO ", ENTITY_SERVICE ) returns empty');
	end;

	if ( normalize( ' test.DOT@foo.bar ', ENTITY_EMAIL ) = '' ) then
	begin
		raise Exception.Create('Assert: normalize(" test.dot@foo.bar ", ENTITY_EMAIL ) returns empty' );
	end;


end.