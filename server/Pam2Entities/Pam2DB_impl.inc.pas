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

	setLength( HSGPermissions, 0 );
	setLength( HSUPermissions, 0 );
	setLength( UGBindings, 0 );

	Console.log('Loading PAM2DB');

	Load();

end;

{ Creates a context in which a user can execute a command }
function TPam2DB.createContext( userName: ansiString; password: AnsiString ): TPam2ExecutionContext;
var mdPwd : AnsiString;
	user  : TPam2User;
begin

	result := NIL;

	user := getUserByName( userName );

	if user = NIL then
		raise Exception.Create( 'User "' + userName + '" not found!' );

	if user.enabled = FALSE then
		raise Exception.Create( 'Account "' + userName + '" is disabled, and cannot execute any command on server!' );

	mdPwd := encryptPassword( password );

	if mdPwd <> user.password then
		raise Exception.Create( 'Bad password' );

	result := TPam2ExecutionContext.Create( self, user.admin, user.id );

end;

{ Getter for "allUsers" property }
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

{ Getter for "allHosts" property }
function TPam2DB.getAllHostsList(): TStrArray;
var i: Integer;
    len: Integer;
begin

	len := Length( hosts );
	setLength( result, len );
	
	for i := 0 to len - 1 do
	begin
		result[ i ] := hosts[i].hostName;
	end;

end;

function TPam2DB.getAllGroupsList(): TStrArray;
var i: Integer;
    len: Integer;
begin

	len := Length( groups );
	setLength( result, len );
	
	for i := 0 to len - 1 do
	begin
		result[ i ] := groups[i].groupName;
	end;

end;

function TPam2DB.getAllServicesList(): TStrArray;
var i: Integer;
    len: Integer;
begin

	len := Length( services );
	setLength( result, len );
	
	for i := 0 to len - 1 do
	begin
		result[ i ] := services[i].serviceName;
	end;

end;

function TPam2DB.normalizeEntity( inputStr: AnsiString; entityType: Integer ): AnsiString;
begin
	result := normalize( inputStr, entityType );
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

	// SNAPSHOT HSG PERMISSIONS
	len := Length( HSGPermissions );

	for i := 0 to Len - 1 do
		addSnapshot( 'HSG: ' + IntToStr( HSGPermissions[i].host.id ) + ' ' + IntToStr( HSGPermissions[i].service.id ) + ' ' + IntToStr( HSGPermissions[i].group.id ) + ' ' + IntToStr( Integer( HSGPermissions[i].allow ) ) );

	// SNAPSHOT HSU PERMISSIONS
	len := Length( HSUPermissions );

	for i := 0 to Len - 1 do
		addSnapshot( 'HSU: ' + IntToStr( HSUPermissions[i].host.id ) + ' ' + IntToStr( HSUPermissions[i].service.id ) + ' ' + IntToStr( HSUPermissions[i].user.id ) + ' ' + IntToStr( Integer( HSUPermissions[i].allow ) ) );

	// SNAPSHOT UG BINDINGS
	len := Length( UGBindings );

	for i := 0 to Len - 1 do
		addSnapshot( 'UG: ' + IntToStr( UGBindings[i].user.id ) + ' ' + IntToStr( UGBindings[i].group.id ) );

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

	setLength( sqlStatements, 0 );
	setLength( errors, 0 );

	if Length( snapshot ) > 0 then
	begin

		setLength( snapshot, 0 );
		Console.notice( 'TPam2DB: Snapshot discarded' );

	end

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

	//console.notice( 'TPam2DB:SQL:', statement );

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

			console.error( 'TPAM2DB.SQL.ERROR: ', statement );

			raise;

		end;

	end;

end;

procedure TPam2DB.commitSqlStatements();
var len: Integer;
    i: Integer;
begin
	
	len := Length( sqlStatements );

	if ( len > 0 ) then
		console.notice( 'COMMIT: ' + IntToStr( len ) + ' statements' );

	for i := 0 to len - 1 do
	begin
		doSQLStatement( sqlStatements[ i ] );
	end;

	setLength( sqlStatements, 0 );

end;

procedure TPam2DB.commit();
var len: Integer;
    i: Integer;
begin

	console.notice( 'COMMITING: BEGIN' );

	{ save all users, groups, hosts, and services, if needed }
	len := Length(users);    for i := 0 to Len - 1 do users[i].save();
	len := Length(groups);   for i := 0 to Len - 1 do groups[i].save();
	len := Length(services); for i := 0 to Len - 1 do services[i].save();
	len := Length(hosts);    for i := 0 to Len - 1 do hosts[i].save();

	commitSqlStatements();

	{ update id's of inserted hosts, users, groups, and services }

	len := Length( users );    for i := 0 to Len - 1 do users[i].updateIdAfterInsertion();
	len := Length( groups );   for i := 0 to Len - 1 do groups[i].updateIdAfterInsertion();
	len := Length( services ); for i := 0 to Len - 1 do services[i].updateIdAfterInsertion();
	len := Length( hosts );    for i := 0 to Len - 1 do hosts[i].updateIdAfterInsertion();

	{ remove deleted groups, users, hosts, and services. }
	removeAndDisposeDeletedObjects();

	{
	// TODO: Determine whether the group_users table should be regenerated or not
	addSQLStatement( 'TRUNCATE TABLE group_users' );
	
	len := Length( UGBindings );
	if ( len > 0 ) then
	begin
		addSQLStatement( 'LOCK TABLES group_users WRITE' );
		for i := 0 to len - 1 do
			addSQLStatement( 'INSERT INTO group_users ( group_id, user_id ) VALUES (' + IntToStr( UGBindings[i].group.id ) + ', ' + IntToStr( UGBindings[i].user.id ) + ' )' );
		addSQLStatement( 'UNLOCK TABLES' );
	end;

	// TODO: Determine whether the service_host_groups table should be regenerated or not
	addSQLStatement( 'TRUNCATE TABLE service_host_groups' );
	
	len := Length( HSGPermissions );
	if ( len > 0 ) then
	begin
		addSQLStatement( 'LOCK TABLES service_host_groups WRITE' );
		for i := 0 to len - 1 do
			addSQLStatement( 'INSERT INTO service_host_groups ( host_id, service_id, group_id, allow ) VALUES ( ' + IntToStr( HSGPermissions[i].host.id ) + ', ' + IntToStr( HSGPermissions[i].service.id ) + ', ' + IntToStr( HSGPermissions[i].group.id ) + ', ' + IntToStr( Integer( HSGPermissions[i].allow ) ) + ')' );
		addSQLStatement( 'UNLOCK TABLES' );
	end;

	// TODO: Determine whether the service_host_users table should be regenerated or not
	addSQLStatement( 'TRUNCATE TABLE service_host_users' );
	
	len := Length( HSUPermissions );
	if ( len > 0 ) then
	begin
		addSQLStatement( 'LOCK TABLES service_host_users WRITE' );
		for i := 0 to len - 1 do
			addSQLStatement( 'INSERT INTO service_host_users ( host_id, service_id, user_id, allow ) VALUES ( ' + IntToStr( HSUPermissions[i].host.id ) + ', ' + IntToStr( HSUPermissions[i].service.id ) + ', ' + IntToStr( HSUPermissions[i].user.id ) + ', ' + IntToStr( Integer( HSUPermissions[i].allow ) ) + ')' );
		addSQLStatement( 'UNLOCK TABLES' );
	end;

	}

	{ WE'RE ALMOST DONE ... }
	commitSqlStatements();

	console.notice( 'COMMIT: END' );

end;

procedure TPam2DB.dispatchSnapshotLine( snapshotLine: AnsiString );
var propName: AnsiString;
    propValue: AnsiString;
    dotPos: Integer;
    len: Integer;
begin
	Console.error( 'dispatch :' + snapshotLine );
end;

procedure TPam2DB.rollbackSnapshot();

var i: Integer;
    len: Integer;
    						// 0 - dispatch on self.
    cUser: TPam2User;       // 1
    cGroup: TPam2Group;     // 2
    cHost: TPam2Host;       // 3
    cService: TPam2Service; // 4

    dispatchTo: Byte;

    id: Integer;

begin

	// FREE ALL RESOURCES SILENTLY

	Console.notice( 'TPam2DB: Rollback Begin' );

	// FREE HOSTS, SERVICES, GROUPS, and USERS without saving
	len := Length( hosts );    for i:= 0 to len - 1 do hosts[i].FreeWithoutSaving();    setLength( hosts, 0 );
	len := Length( services ); for i:= 0 to Len - 1 do services[i].FreeWithoutSaving(); setLength( services, 0 );
	len := Length( groups );   for i:= 0 to len - 1 do groups[ i ].FreeWithoutSaving(); setLength( groups, 0 );
	len := Length( users );    for i:= 0 to len - 1 do users[ i ].FreeWithoutSaving();  setLength( users, 0 );

	// CLEAR EXISTING BINDINGS AND PERMISSIONS MAPPINGS
	setLength( UGBindings, 0 );
	setLength( HSGPermissions, 0 );
	setLength( HSUPermissions, 0 );

	// RE-CREATE ENTITIES ( WITHOUT ANY PROPERTIES AT FIRST )
	len := Length( snapshot );

	for i := 0 to len - 1 do
	begin

		if str_starts_with( snapshot[i], 'USER ' ) then
		begin
			id := StrToInt( copy( snapshot[i], 6, 11 ) ); len := Length( users ); setLength( users, len + 1 ); users[ len ] := TPam2User.Create( self, id );
		end else
		if str_starts_with( snapshot[i], 'GROUP ') then
		begin
			id := StrToInt( copy( snapshot[i], 7, 11 ) ); len := Length( groups ); setLength( groups, len + 1 ); groups[ len ] := TPam2Group.Create( self, id );
		end else
		if str_starts_with( snapshot[i], 'SERVICE ' ) then
		begin
			id := StrToInt( copy( snapshot[i], 9, 11 ) ); len := Length( services ); setLength( services, len + 1 ); services[ len ] := TPam2Service.Create( self, id );
		end else
		if str_starts_with( snapshot[i], 'HOST ' ) then
		begin
			id := StrToInt( copy( snapshot[i], 6, 11 ) ); len := Length( hosts ); setLength( hosts, len + 1 ); hosts[ len ] := TPam2Host.Create( self, id );
		end;

	end;

	// ROLLBACK PROPERTIES OF RE-CREATED ENTITIES
	len := Length( snapshot );

	dispatchTo := 0;

	for i := 0 to len - 1 do
	begin

		if str_starts_with( snapshot[i], 'USER ' ) then
		begin

			cUser := getUserById( StrToInt( copy( snapshot[i], 6, 11 ) ) );
			dispatchTo := 1;

		end else
		
		if str_starts_with( snapshot[i], 'GROUP ') then
		begin

			cGroup := getGroupById( StrToInt( copy( snapshot[i], 7, 11 ) ) );
			dispatchTo := 2;

		end else

		if str_starts_with( snapshot[i], 'SERVICE ' ) then
		begin
			
			cService := getServiceById( StrToInt( copy( snapshot[i], 9, 11 ) ) );
			dispatchTo := 4;

		end else

		if str_starts_with( snapshot[i], 'HOST ' ) then
		begin

			cHost := getHostById( StrToInt( copy( snapshot[i], 6, 11 ) ) );
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
				4: cService.rollback( snapshot[i] );
				0: dispatchSnapshotLine( snapshot[i] )
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

{ TODO! GENERATE A REAL RANDOM USER PASSWORD }
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
	
	//console.notice('TPam2DB.SQL.ADD: ', statement );

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
	
	console.error( 'Create user: "' + loginName + '", "' + realName + '"' );

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
					addError('Password is too short (' + IntToStr( length( lPassword ) ) + ' < ' + IntToStr( MINLEN_PAM2_PASSWORD ) + ')' );
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

procedure TPam2DB.removeAndDisposeDeletedObjects();
var Len: Integer;
    I: Integer;
    J: Integer;
begin

	Len := Length( users ); I := Len - 1;

	while ( i >= 0 ) do begin

		if ( users[i].deleted ) then
		begin

			users[i].FreeWithoutSaving();
			users[i] := NIL;

			for j := i + 1 to len - 1 do
			begin
				users[ j - 1 ] := users[ j ];
			end;

			Len := Len - 1;

			setLength( users, Len );

		end;

		i := i - 1;

	end;

	Len := Length( groups ); I := Len - 1;

	while ( i >= 0 ) do begin

		if ( groups[i].deleted ) then
		begin

			groups[i].FreeWithoutSaving();
			groups[i] := NIL;

			for j := i + 1 to len - 1 do
			begin
				groups[ j - 1 ] := groups[ j ];
			end;

			Len := Len - 1;

			setLength( groups, Len );

		end;

		i := i - 1;

	end;

	Len := Length( services ); I := Len - 1;

	while ( i >= 0 ) do begin

		if ( services[i].deleted ) then
		begin

			services[i].FreeWithoutSaving();
			services[i] := NIL;

			for j := i + 1 to len - 1 do
			begin
				services[ j - 1 ] := services[ j ];
			end;

			Len := Len - 1;

			setLength( services, Len );

		end;

		i := i - 1;

	end;

	Len := Length( hosts ); I := Len - 1;

	while ( i >= 0 ) do begin

		if ( hosts[i].deleted ) then
		begin

			hosts[i].FreeWithoutSaving();
			hosts[i] := NIL;

			for j := i + 1 to len - 1 do
			begin
				hosts[ j - 1 ] := hosts[ j ];
			end;

			Len := Len - 1;

			setLength( hosts, Len );

		end;

		i := i - 1;

	end;

end;


// Returns lowercase of md5ed password

function TPam2DB.encryptPassword( password: AnsiString ): AnsiString;
begin
	result := LowerCase( md5Print( md5String( password ) ) );
end;

{$I ./Pam2DB/Load.impl.pas}

destructor TPam2DB.Free();
var i: integer;
    len: integer;
begin

	// FREE HSGPermissions list
	setLength( HSGPermissions, 0 );

	// FREE HSUPermissions list
	setLength( HSUPermissions, 0 );

	// FREE UGBindings
	setLength( UGBindings, 0 );

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

procedure TPam2DB.bindHSG( host: TPam2Host; group: TPam2Group; service: TPam2Service; allow: Boolean; const remove: Boolean = FALSE );
var i: Integer;
	j: Integer;
    len: Integer;
    hsg: TPam2HSGPermission;

begin
	if ( host = NIL ) or ( group = NIL ) or ( service = NIL ) then
		Raise Exception.Create( 'Invalid HSG Binding' );

	Len := Length( HSGPermissions );

	if ( remove = TRUE ) then
	begin
		
		// Remove triplet policy
		
		for i := 0 To Len - 1 do
		begin
			if ( HSGPermissions[i].host.equals( host ) and HSGPermissions[i].service.equals( service ) and ( HSGPermissions[i].group.equals( group ) ) ) then
			begin
				for J := I + 1 To Len - 1 Do HSGPermissions[ j - 1 ] := HSGPermissions[ j ];
				SetLength( HSGPermissions, Len - 1 );
				addSQLStatement( 'DELETE FROM service_host_groups WHERE service_id = ' + IntToStr( service.id ) + ' AND host_id = ' + IntToStr( host.id ) + ' AND group_id = ' + IntToStr( group.id ) + ' LIMIT 1' );
				exit;
			end;
		end;

	end else
	begin
		
		// Set triplet policy

		for i := 0 to Len - 1 do
		begin

			if ( HSGPermissions[i].host.equals( host ) and HSGPermissions[i].service.equals( service ) and ( HSGPermissions[i].group ).equals( group ) ) then
			begin
				if ( HSGPermissions[i].allow <> allow ) then
				begin
					HSGPermissions[i].allow := allow;
					addSQLStatement( 'UPDATE service_host_groups SET allow = ' + IntToStr( Integer( allow ) ) + ' WHERE service_id = ' + IntToStr( service.id ) + ' AND host_id = ' + IntToStr( host.id ) + ' AND group_id = ' + IntToStr( group.id ) + ' LIMIT 1' );
				end;
				exit;
			end;

		end;

		hsg.host := host;
		hsg.service := service;
		hsg.group := group;
		hsg.allow := allow;

		setLength( HSGPermissions, Len + 1 );
		HSGPermissions[ Len ] := hsg;

		addSQLStatement( 'INSERT INTO service_host_groups ( service_id, host_id, group_id, allow ) VALUES (' + IntToStr( service.id ) + ', ' + IntToStr( host.id ) + ', ' + IntToStr( group.id ) + ', ' + IntToStr( Integer( allow ) ) + ')' );

	end;

end;

procedure TPam2DB.bindHSG( hostId: Integer; groupId: Integer; serviceId: Integer; allow: Boolean; const remove: Boolean = FALSE );
begin
	bindHSG( getHostById( hostId ), getGroupById( groupId ), getServiceById( serviceId ), allow, remove );
end;

procedure TPam2DB.bindHSG( hostName: AnsiString; groupName: AnsiString; serviceName: AnsiString; allow: Boolean; const remove: Boolean = FALSE );
begin
	bindHSG( getHostByName( hostName ), getGroupByName( groupName ), getServiceByName( serviceName ), allow, remove );
end;

procedure TPam2DB.unbindHSG ( host: TPam2Host );
var len: Integer;
    i: Integer;
    removed: boolean;
begin
	removed := FALSE;
	len := Length( HSGPermissions );
	for i := Len - 1 downto 0 do begin
		if ( HSGPermissions[i].host.equals( host ) ) then begin
			removed := TRUE;
			Len := array_remove( HSGPermissions, i );
		end;
	end;
	if ( removed = TRUE ) and ( host.id <> 0 ) then begin
		addSQLStatement( 'DELETE FROM service_host_groups WHERE host_id = ' + IntToStr( host.id ) );
	end;
end;

procedure TPam2DB.unbindHSG ( service: TPam2Service );
var len: Integer;
    i: Integer;
    removed: boolean;
begin
	removed := FALSE;
	len := Length( HSGPermissions );
	for i := Len - 1 downto 0 do begin
		if ( HSGPermissions[i].service.equals( service ) ) then begin
			removed := TRUE;
			Len := array_remove( HSGPermissions, i );
		end;
	end;
	if ( removed = TRUE ) and ( service.id <> 0 ) then begin
		addSQLStatement( 'DELETE FROM service_host_groups WHERE service_id = ' + IntToStr( service.id ) );
	end;
end;

procedure TPam2DB.unbindHSG ( group: TPam2Group );
var len: Integer;
    i: Integer;
    removed: boolean;
begin
	removed := FALSE;
	len := Length( HSGPermissions );
	for i := Len - 1 downto 0 do begin
		if ( HSGPermissions[i].group.equals( group ) ) then begin
			removed := TRUE;
			Len := array_remove( HSGPermissions, i );
		end;
	end;
	if ( removed = TRUE ) and ( group.id <> 0 ) then begin
		addSQLStatement( 'DELETE FROM service_host_groups WHERE group_id = ' + IntToStr( group.id ) );
	end;
end;

function  TPam2DB.getHSGPermissions( host: TPam2Host ) : TPam2HSGPermission_List;
var Len: Integer;
    i: Integer;
    RLen: Integer;
begin
	RLen := 0;
	setLength( result, RLen );
	Len := Length( HSGPermissions );
	for i := 0 to Len - 1 do
	begin
		if ( HSGPermissions[i].host.equals( host ) ) then
		begin
			RLen := RLen + 1;
			setLength( result, RLen );
			result[ RLen - 1 ] := HSGPermissions[ i ];
		end;
	end;
end;

function  TPam2DB.getHSGPermissions( service: TPam2Service ) : TPam2HSGPermission_List;
var Len: Integer;
    i: Integer;
    RLen: Integer;
begin
	RLen := 0;
	setLength( result, RLen );
	Len := Length( HSGPermissions );
	for i := 0 to Len - 1 do
	begin
		if ( HSGPermissions[i].service.equals( service ) ) then
		begin
			RLen := RLen + 1;
			setLength( result, RLen );
			result[ RLen - 1 ] := HSGPermissions[ i ];
		end;
	end;
end;

function  TPam2DB.getHSGPermissions( group: TPam2Group ) : TPam2HSGPermission_List;
var Len: Integer;
    i: Integer;
    RLen: Integer;
begin
	RLen := 0;
	setLength( result, RLen );
	Len := Length( HSGPermissions );
	for i := 0 to Len - 1 do
	begin
		if ( HSGPermissions[i].group.equals( group ) ) then
		begin
			RLen := RLen + 1;
			setLength( result, RLen );
			result[ RLen - 1 ] := HSGPermissions[ i ];
		end;
	end;

end;

{ BEGIN: HSU PERMISSIONS  }

procedure TPam2DB.bindHSU( host: TPam2Host; user: TPam2User; service: TPam2Service; allow: Boolean; const remove: Boolean = FALSE );
var i: Integer;
	j: Integer;
    len: Integer;
    hsu: TPam2HSUPermission;

begin
	if ( host = NIL ) or ( user = NIL ) or ( service = NIL ) then
		Raise Exception.Create( 'Invalid HSU Binding' );

	Len := Length( HSUPermissions );

	if ( remove = TRUE ) then
	begin
		
		// Remove triplet policy
		
		for i := 0 To Len - 1 do
		begin
			if ( HSUPermissions[i].host.equals( host ) and HSUPermissions[i].service.equals( service ) and ( HSUPermissions[i].user.equals( user ) ) ) then
			begin
				for J := I + 1 To Len - 1 Do HSUPermissions[ j - 1 ] := HSUPermissions[ j ];
				SetLength( HSUPermissions, Len - 1 );
				addSQLStatement( 'DELETE FROM service_host_users WHERE service_id = ' + IntToStr( service.id ) + ' AND host_id = ' + IntToStr( host.id ) + ' AND user_id = ' + IntToStr( user.id ) + ' LIMIT 1' );
				exit;
			end;
		end;

	end else
	begin
		
		// Set triplet policy

		for i := 0 to Len - 1 do
		begin

			if ( HSUPermissions[i].host.equals( host ) and HSUPermissions[i].service.equals( service ) and ( HSUPermissions[i].user ).equals( user ) ) then
			begin
				if ( HSUPermissions[i].allow <> allow ) then
				begin
					HSUPermissions[i].allow := allow;
					addSQLStatement( 'UPDATE service_host_users SET allow = ' + IntToStr( Integer( allow ) ) + ' WHERE service_id = ' + IntToStr( service.id ) + ' AND host_id = ' + IntToStr( host.id ) + ' AND user_id = ' + IntToStr( user.id ) + ' LIMIT 1' );
				end;
				exit;
			end;

		end;

		hsu.host := host;
		hsu.service := service;
		hsu.user := user;
		hsu.allow := allow;

		setLength( HSUPermissions, Len + 1 );
		HSUPermissions[ Len ] := hsu;

		addSQLStatement( 'INSERT INTO service_host_users ( service_id, host_id, user_id, allow ) VALUES (' + IntToStr( service.id ) + ', ' + IntToStr( host.id ) + ', ' + IntToStr( user.id ) + ', ' + IntToStr( Integer( allow ) ) + ')' );

	end;

end;

procedure TPam2DB.bindHSU( hostId: Integer; userId: Integer; serviceId: Integer; allow: Boolean; const remove: Boolean = FALSE );
begin
	bindHSU( getHostById( hostId ), getUserById( userId ), getServiceById( serviceId ), allow, remove );
end;

procedure TPam2DB.bindHSU( hostName: AnsiString; userName: AnsiString; serviceName: AnsiString; allow: Boolean; const remove: Boolean = FALSE );
begin
	bindHSU( getHostByName( hostName ), getUserByName( userName ), getServiceByName( serviceName ), allow, remove );
end;

procedure TPam2DB.unbindHSU ( host: TPam2Host );
var len: Integer;
    i: Integer;
    removed: boolean;
begin
	removed := FALSE;
	len := Length( HSUPermissions );
	for i := Len - 1 downto 0 do begin
		if ( HSUPermissions[i].host.equals( host ) ) then begin
			removed := TRUE;
			Len := array_remove( HSUPermissions, i );
		end;
	end;
	if ( removed = TRUE ) and ( host.id <> 0 ) then begin
		addSQLStatement( 'DELETE FROM service_host_users WHERE host_id = ' + IntToStr( host.id ) );
	end;
end;

procedure TPam2DB.unbindHSU ( service: TPam2Service );
var len: Integer;
    i: Integer;
    removed: boolean;
begin
	removed := FALSE;
	len := Length( HSUPermissions );
	for i := Len - 1 downto 0 do begin
		if ( HSUPermissions[i].service.equals( service ) ) then begin
			removed := TRUE;
			Len := array_remove( HSUPermissions, i );
		end;
	end;
	if ( removed = TRUE ) and ( service.id <> 0 ) then begin
		addSQLStatement( 'DELETE FROM service_host_users WHERE service_id = ' + IntToStr( service.id ) );
	end;
end;

procedure TPam2DB.unbindHSU ( user: TPam2User );
var len: Integer;
    i: Integer;
    removed: boolean;
begin
	removed := FALSE;
	len := Length( HSUPermissions );
	for i := Len - 1 downto 0 do begin
		if ( HSUPermissions[i].user.equals( user ) ) then begin
			removed := TRUE;
			Len := array_remove( HSUPermissions, i );
		end;
	end;
	if ( removed = TRUE ) and ( user.id <> 0 ) then begin
		addSQLStatement( 'DELETE FROM service_host_users WHERE user_id = ' + IntToStr( user.id ) );
	end;
end;

function  TPam2DB.getHSUPermissions( host: TPam2Host ) : TPam2HSUPermission_List;
var Len: Integer;
    i: Integer;
    RLen: Integer;
begin
	RLen := 0;
	setLength( result, RLen );
	Len := Length( HSUPermissions );
	for i := 0 to Len - 1 do
	begin
		if ( HSUPermissions[i].host.equals( host ) ) then
		begin
			RLen := RLen + 1;
			setLength( result, RLen );
			result[ RLen - 1 ] := HSUPermissions[ i ];
		end;
	end;
end;

function  TPam2DB.getHSUPermissions( service: TPam2Service ) : TPam2HSUPermission_List;
var Len: Integer;
    i: Integer;
    RLen: Integer;
begin
	RLen := 0;
	setLength( result, RLen );
	Len := Length( HSUPermissions );
	for i := 0 to Len - 1 do
	begin
		if ( HSUPermissions[i].service.equals( service ) ) then
		begin
			RLen := RLen + 1;
			setLength( result, RLen );
			result[ RLen - 1 ] := HSUPermissions[ i ];
		end;
	end;
end;

function  TPam2DB.getHSUPermissions( user: TPam2User ) : TPam2HSUPermission_List;
var Len: Integer;
    i: Integer;
    RLen: Integer;
begin
	RLen := 0;
	setLength( result, RLen );
	Len := Length( HSUPermissions );
	for i := 0 to Len - 1 do
	begin
		if ( HSUPermissions[i].user.equals( user ) ) then
		begin
			RLen := RLen + 1;
			setLength( result, RLen );
			result[ RLen - 1 ] := HSUPermissions[ i ];
		end;
	end;

end;

{ END:   HSU PERMISSIONS }

procedure TPam2DB.bindUG ( user: TPam2User; group: TPam2Group );
var i: Integer;
    Len: Integer;
    binding: TPam2UGBinding;
begin
	
	if ( user = NIL ) or ( group = NIL ) then
		exit;

	Len := Length( UGBindings );

	for i := 0 to Len - 1 do
	begin

		if ( UGBindings[i].user.equals( user ) ) and ( UGBindings[i].group.equals( group ) ) then
			exit;

	end;

	binding.user := user;
	binding.group := group;

	//console.notice( 'bindUG( ', user.loginName, ' => ', group.groupName, ' )' );

	setLength( UGBindings, Len + 1 );
	UGBindings[ Len ] := binding;

	addSQLStatement( 'INSERT INTO group_users ( group_id, user_id ) VALUES ( ' + IntToStr( group.id ) + ', ' + IntToStr( user.id ) + ' )' );

end;

procedure TPam2DB.bindUG ( userId: Integer; groupId: Integer );
var user: TPam2User;
    group: TPam2Group;
begin
	user := getUserById( userId );
	
	if ( user = NIL ) then
		raise Exception.Create( 'User with id ' + IntToStr( userId ) + ' not found!' );

	group := getGroupById( groupId );

	if ( group = NIL ) then
		raise Exception.Create( 'Group with id ' + IntToStr( groupId ) + ' not found!' );

	bindUG( user, group );
end;

procedure TPam2DB.bindUG ( userName: AnsiString; groupName: AnsiString );
var user: TPam2User;
    group: TPam2Group;
begin
	user := getUserByName( userName );
	
	if ( user = NIL ) then
		raise Exception.Create( 'User "' + userName + '" not found!' );

	group := getGroupByName( groupName );

	if ( group = NIL ) then
		raise Exception.Create( 'Group "' + groupName + '" not found!' );

	bindUG( user, group );

end;

procedure TPam2DB.unbindUG( user: TPam2User; group: TPam2Group );
var i: Integer;
    Len: Integer;
    Removed: Boolean;
begin
	Removed := FALSE;
	Len := Length( UGBindings );

	for i := Len - 1 downto 0 do
	begin
		if UGBindings[i].user.equals( user ) AND UGBindings[i].group.equals( group ) then
		begin
			Len := array_remove( UGBindings, i );
			Removed := TRUE;
			break;
		end;
	end;

	if ( Removed ) AND ( user.id <> 0 ) and ( group.id <> 0 ) then
		addSQLStatement( 'DELETE FROM group_users WHERE group_id = ' + IntToStr( group.id ) + ' AND user_id = ' + IntToStr( user.id ) + ' LIMIT 1' );
end;

procedure TPam2DB.unbindUG( user: TPam2User   );
var i: Integer;
    Len: Integer;
    Removed: Boolean;
begin
	Removed := FALSE;
	Len := Length( UGBindings );

	for i := Len - 1 downto 0 do
	begin
		if UGBindings[i].user.equals( user ) then
		begin
			Len := array_remove( UGBindings, i );
			Removed := TRUE;
		end;
	end;

	if ( Removed ) AND ( user.id <> 0 ) then
		addSQLStatement( 'DELETE FROM group_users WHERE user_id = ' + IntToStr( user.id ) + ' LIMIT 1' );
end;

procedure TPam2DB.unbindUG( group: TPam2Group );

var i: Integer;
    Len: Integer;
    Removed: Boolean;
begin
	Removed := FALSE;
	Len := Length( UGBindings );

	for i := Len - 1 downto 0 do
	begin
		if UGBindings[i].group.equals( group ) then
		begin
			Len := array_remove( UGBindings, i );
			Removed := TRUE;
		end;
	end;

	if ( Removed ) AND ( group.id <> 0 ) then
		addSQLStatement( 'DELETE FROM group_users WHERE group_id = ' + IntToStr( group.id ) + ' LIMIT 1' );
end;

function  TPam2DB.getUGBindings( user: TPam2User   ): TPam2UGBinding_List;
var RLen: Integer;
    i: Integer;
    Len: Integer;
begin
	Len := Length( UGBindings );
	RLen := 0;
	setLength( result, 0 );
	for i := 0 to Len - 1 do
	begin
		if ( UGBindings[i].user.equals( user ) ) then
		begin
			setLength( result, RLen + 1 );
			result[ RLen ] := UGBindings[ i ];
		end;
	end;
end;

function  TPam2DB.getUGBindings    ( group: TPam2Group ): TPam2UGBinding_List;
var RLen: Integer;
    i: Integer;
    Len: Integer;
begin
	Len := Length( UGBindings );
	RLen := 0;
	setLength( result, 0 );
	for i := 0 to Len - 1 do
	begin
		if ( UGBindings[i].group.equals( group ) ) then
		begin
			setLength( result, RLen + 1 );
			result[ RLen ] := UGBindings[ i ];
		end;
	end;
end;

function TPam2DB.getHasErrors(): Boolean;
begin
	if ( Length( errors ) > 0 )
	then result := TRUE
	else result := FALSE;
end;

procedure TPam2DB.setHasErrors( on: Boolean );
begin
	if ( on = FALSE ) and ( Length( errors ) > 0 )
	then setLength( errors, 0 );
end;