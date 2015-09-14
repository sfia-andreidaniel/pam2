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

	// Commit objects

	len := Length( users );
	for i := 0 to Len - 1 do users[i].updateIdAfterInsertion();

	len := Length( services );
	for i := 0 to Len - 1 do services[i].updateIdAfterInsertion();

	len := Length( hosts );
	for i := 0 to Len - 1 do hosts[i].updateIdAfterInsertion();

	len := Length( groups );
	for i := 0 to Len - 1 do groups[i].updateIdAfterInsertion();

	// Remove deleted objects
	// Owww, how much I miss the Array.splice from javascript here ... :)
	removeAndDisposeDeletedObjects();


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

