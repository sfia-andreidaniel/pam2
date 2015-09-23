constructor TPam2ExecutionContext.Create( _db: TPam2DB; isAdmin: Boolean; lockedUserId: Integer );
begin

	db := _db;
	admin := isAdmin;
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
		if arg = 'dump' then
		begin
			result := cmd_dump( query );
		end else 
		if arg = 'help' then
		begin
			result := cmd_help( query );
		end else
			raise Exception.Create( 'Invalid command: "' + arg + '" ( argument index: 0 )' );

	except

		On E: Exception Do
		begin

			raise;
		end;
	end;
end;

function TPam2ExecutionContext.cmd_host( query: TQueryParser ): AnsiString;
begin
	raise Exception.Create( 'host command is not implemented' );
end;

function TPam2ExecutionContext.cmd_dump( query: TQueryParser ): AnsiString;
var arg: AnsiString;
	dump: AnsiString;
begin
	
	arg := trim( lowerCase( query.nextArg() ) );

	if ( arg = '' ) then
		raise Exception.Create( 'Unexpected end of query. Expected token "STATE".')
	else
	if ( arg = 'state' ) then
	begin

		if ( not admin ) then
			raise Exception.Create( 'Access denied. This operation requires administrative privileges' );

		db.createSnapshot();

		dump := db.binaryDump;

		db.discardSnapshot();

		result := '{"explain": "Show binary dump", "data": ' + json_encode( dump ) + '}';

	end else
		raise Exception.Create( 'Unexpected token "' + arg + '". Expected token "STATE".' );

end;

function TPam2ExecutionContext.cmd_service( query: TQueryParser ): AnsiString;
var arg: AnsiString;
    op: Integer;
    serviceName: AnsiString;
    optionName: AnsiString;
    optionValue: AnsiString;
    
    subjects: TStrArray;
    subjects1 : TStrArray;

    Len: Integer;
    Len1: Integer;
    I: Integer;
    J: Integer;
    isWildCard: Boolean;
    isWildCard1: Boolean;

    explain: AnsiString;

    END_OF_QUERY: TStrArray;
    END_OF_QUERY_ON: TStrArray;

    service: TPam2Service;
    host: TPam2Host;

    passwordType: AnsiString;

begin
	
	setLength( END_OF_QUERY, 0 );
	setLength( END_OF_QUERY_ON, 1 ); END_OF_QUERY_ON[0] := 'on';

	passwordType := '';

	explain := '';

	arg := trim( lowercase( query.nextArg() ) );

	if ( arg = 'add' ) then
	begin
		op := OP_ADD;
	end else
	if ( arg = 'remove' ) then
	begin
		op := OP_REMOVE;
	end else
	if ( arg = '' ) then
	begin
		raise Exception.Create('Expected token ADD or REMOVE' );
	end else
	begin
		raise Exception.Create('Invalid token "' + arg + '" @ pos ' + IntToStr( query.currentArgumentIndex ) );
	end;

	arg := trim( lowercase( query.nextArg ) );

	if ( op = OP_ADD ) then
	begin

		if ( arg = 'with' ) then
		begin

			arg := trim( lowercase( query.nextArg ) );

			if ( arg = '' ) then
				raise Exception.Create('Unexpected end of query. Expected token "PASSWORD_TYPE"' )
			else
			if ( arg = 'password_type' ) then
			begin

				arg := trim( lowercase( query.nextArg ) );

				if ( arg = '' ) then
					raise Exception.Create('Unexpected end of query. Expected PASSWORD_TYPE_VALUE.' );

				if ( arg <> 'plain' ) and ( arg <> 'md5' ) and ( arg <> 'password' ) and ( arg <> 'crypt' ) and ( arg <> 'bin' ) then
					raise Exception.Create('Unknown service password type "' + arg + '". Expected PLAIN | MD5 | PASSWORD | CRYPT | BIN' );

				passwordType := arg;

				arg := query.nextArg;

			end else
			begin
				raise Exception.Create('Unexpected token "' + arg + '". Expected token "PASSWORD_TYPE".');
			end;

		end;

	end;

	if ( arg = 'option' ) then
	begin

		if ( passwordType <> '' ) then
			raise Exception.Create('Unexpected token "' + arg + '". Expected {SERVICE_NAME}!' );

		arg := trim( lowerCase( query.nextArg() ) );

		if ( arg = '' ) then
			raise Exception.Create('Unexpected end of query. Expected {OPTION_NAME}');

		if ( op = OP_ADD ) then
			explain := 'Add an option called "'
		else
			explain := 'Remove the option called "';

		optionName := db.normalizeEntity( arg, ENTITY_SERVICE_OPTION );

		if ( optionName = '' ) then
			raise Exception.Create('Invalid option name "' + arg + '"' );

		explain := explain + optionName + '" ';

		optionValue := '';

		arg := trim( query.nextArg );

		if ( lowerCase(arg) = 'value' ) then
		begin

			arg := trim( query.nextArg );

			optionValue := arg;

			explain := explain + 'with value "' + optionValue + '" ';

			arg := trim( query.nextArg );

		end;

		if ( lowerCase(arg) = 'for' ) then
		begin

			arg := trim( lowerCase( query.nextArg ) );

			if ( arg = '' ) then
				raise Exception.Create('Unexpected end of query. Expected "SERVICE" or "SERVICES", at pos ' + IntToStr( query.currentArgumentIndex ) );

			if ( arg <> 'service' ) and ( arg <> 'services' ) then
				raise Exception.Create('Unexpected token "' + arg + '". Expected "SERVICE" or "SERVICES", at pos ' + IntToStr( query.currentArgumentIndex ) );

			subjects := query.readEntities( ENTITY_SERVICE, TRUE, db, END_OF_QUERY_ON, isWildCard );

			if ( not isWildCard ) and ( length(subjects) = 0 ) then
				raise Exception.Create('Expected a {SERVICE_NAME} or a {SERVICE_LIST}, at pos ' + IntToStr(query.currentArgumentIndex) );

			if ( isWildCard ) then
				explain := explain + 'for ALL (' + IntToStr( Length(subjects) ) + ') services'
			else
				explain := explain + 'for services "' + str_join( subjects, '", "' ) + '"';

			arg := trim( lowerCase( query.nextArg() ) );

			if ( arg = '' ) then
			begin

				// ADD OR REMOVE SERVICE OPTIONS FOR A SERVICE LIST

				if admin = FALSE then
					raise Exception.Create('Access denied. This operation requires administrative context!' );

				// test if all services exist.
				len := Length( subjects );

				for i := 0 to Len - 1 do
				begin
					if ( not db.serviceExists( subjects[i] ) ) then
						raise Exception.Create( 'Service "' + subjects[i] + '" does not exist!' );
				end;

				// DO THE SHIT

				db.createSnapshot();

				try

					for i := 0 to Len - 1 do
					begin
						service := db.getServiceByName( subjects[i] );
						
						if ( op = OP_ADD ) then
						begin

							db.bindSO( service, optionName, optionValue );

						end else
						if ( op = OP_REMOVE ) then
						begin

							db.unbindSO( service, optionName );

						end;

					end;

					db.commit();

					result := '{"explain": ' + json_encode( explain ) + '}';

					db.discardSnapshot();

				except
					On E: Exception do
					begin
						db.rollbackSnapshot();
						raise;
					end
				end;

			end else
			if ( arg = 'on' ) then
			begin
				// ADD OR REMOVE SERVICE OPTIONS FOR A SERVICE LIST TO A HOST LIST

				subjects1 := query.readEntities( ENTITY_HOST, TRUE, db, END_OF_QUERY, isWildCard1 );

				if ( not isWildCard1 ) and ( Length( subjects1 ) = 0 ) then
				begin
					raise Exception.Create('Expected a {HOST_LIST} enumeration, at arg ' + IntToStr( query.currentArgumentIndex ) );
				end;

				if ( isWildCard1 ) then
					explain := explain + ' on ALL (' + IntToStr( Length( subjects1 ) ) + ') hosts'
				else
					explain := explain + ' on hosts "' + str_join( subjects1, '", "' ) + '"';

				if admin = FALSE then
					raise Exception.Create('Access denied. This operation requires administrative context!' );

				// test if all services exists.

				Len := Length( subjects );

				for i := 0 to Len - 1 do
				begin
					service := db.getServiceByName( subjects[i] );

					if ( service = NIL ) then
						raise Exception.Create( 'No such service "' + subjects[i] + '"' );

				end;

				// test if all hosts exists

				Len := Length( subjects1 );

				for i := 0 to Len - 1 do
				begin
					if ( not db.hostExists( subjects1[i] ) ) then
						raise Exception.Create('No such host "' + subjects1[i] + '"' );
				end;

				// DO THE SHIT
				Len := Length( subjects );
				Len1 := Length( subjects1 );

				if ( Len > 0 ) and ( Len1 > 0 ) then
				begin

					db.createSnapshot();

					try

						for i := 0 to Len - 1 do
						begin

							service := db.getServiceByName( subjects[i] );
							
							if ( service = NIL ) then
								raise Exception.Create('No such service "' + subjects[i] );

							if ( not service.hasOption( optionName ) ) and ( op = OP_ADD ) then
								db.bindSO( service, optionName, optionValue );

							for j := 0 to Len1 - 1 do
							begin

								host := db.getHostByName( subjects1[j] );

								if ( host = NIL ) then
									raise Exception.Create('No such host "' + subjects1[j] );

								if ( op = OP_ADD ) then
								begin

									db.bindSHO( service, host, optionName, optionValue );

								end else
								if ( op = OP_REMOVE ) then
								begin

									db.unbindSHO( service, host, optionName );

								end;

							end;

						end;

						db.commit();

						result := '{"explain": ' + json_encode( explain ) + '}';

						db.discardSnapshot();

					except
						On E: Exception do
						begin
							db.rollbackSnapshot();
							raise;
						end
					end;

				end;


			end else
				raise Exception.Create('Unexpected token "' + arg + '"' );

		end else
		begin
			raise Exception.Create('Unexpected token "' + arg + '". Expected "FOR" at pos ' + IntToStr( query.currentArgumentIndex ) );
		end;


	end else
	begin

		if ( arg = '' ) then
			raise Exception.Create('Unexpected end of query: Expected {SERVICE_NAME} or OPTION' );

		serviceName := db.normalizeEntity( arg, ENTITY_SERVICE );

		if ( serviceName = '' ) then
			raise Exception.Create('Invalid service name: "' + arg + '"' );

		arg := query.nextArg;

		if ( arg <> '' ) then
			raise Exception.Create('Expected end of query but found token "' + arg + '"' );

		// ADD OR REMOVE A SERVICE
		if ( op = OP_ADD ) then begin
			explain := 'Create a new service with name "' + serviceName + '"';
			
			if ( passwordType = '' ) then begin
				explain := explain + ' with password type MD5 (default)';
				passwordType := 'md5';
			end else
				explain := explain + ' with password type ' + LOWERCASE( passwordType );

		end else
		if ( op = OP_REMOVE ) then
			explain := 'Remove the service called "' + serviceName + '"'
		else
			raise Exception.Create( 'Unexpected OP!' );

		if ( admin = FALSE ) then
			raise Exception.Create('Access denied. This operation requires administrative context!' );

		if ( op = OP_ADD ) and ( db.serviceExists( serviceName ) ) then
			raise Exception.Create('Another service with that name "' + serviceName + '" allready exists!' )
		else
		if ( op = OP_REMOVE ) and ( not db.serviceExists( serviceName ) ) then
			raise Exception.Create('No such service "' + serviceName + '"' );

		db.createSnapshot();

		try

			if ( op = OP_ADD ) then
			begin

				service := db.createService( serviceName );
				service.passwordType := passwordType;

			end else
			begin

				service := db.getServiceByName( serviceName );

				if ( service <> NIL ) then
					service.remove();

			end;

			db.commit();

			db.discardSnapshot();

			result := '{"explain": ' + json_encode( explain ) + '}';

		except
			On E: Exception do
			begin
				db.rollbackSnapshot();
				raise;
			end
		end;


	end;


end;

function TPam2ExecutionContext.cmd_group  ( query: TQueryParser ): AnsiString;

var operation: byte;
    arg: AnsiString;

    groupName: AnsiString; // group name, unnormalized
    gName: AnsiString;     // normalized group name

    tokWho: AnsiString;

    subjects: TStrArray;
    subjects1: TStrArray;

    len: Integer;
    len1: Integer;

    isWildCard: Boolean;
    isWildCard1: Boolean;

    i: Integer;
    j: Integer;

    group: TPam2Group;
    user: TPam2User;
    host: TPam2Host;
    service: TPam2Service;

    END_OF_QUERY: TStrArray;
    STOPWORD_ON: TStrArray;

    explain: AnsiString;

begin
	
	setLength( END_OF_QUERY, 0 );
	setLength( STOPWORD_ON, 1 ); STOPWORD_ON[0] := 'on';

	arg := LowerCase( query.nextArg() );

	setLength( subjects, 0 );

	if arg = '' then raise Exception.Create( 'Missing token ( expected ADD | REMOVE | UNSET | ENABLE | DISABLE ), at index 1' );

	if arg = 'add' then
		operation := OP_ADD
	else
	if arg = 'remove' then
		operation := OP_REMOVE
	else
	if arg = 'unset' then
		operation := OP_UNSET
	else
	if arg = 'enable' then
		operation := OP_ENABLE
	else
	if arg = 'disable' then
		operation := OP_DISABLE
	else
		raise Exception.Create( 'Wrong predicate ( expected "add" or "remove" but got "' + arg + '" ), at index 1' );

	if ( operation <> OP_ENABLE ) and ( operation <> OP_DISABLE ) then
	begin

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

				if operation = OP_UNSET then
					raise Exception.Create( 'Illegal token "unset" at argument 2' );

				if ( tokWho <> 'to' ) and ( tokWho <> 'for' ) then
					raise Exception.Create( 'Illegal token "' + tokWho + '" ( expected "to" or "for" ), at index 3 [1]' );

				len := 0;

				// read subjects ( users )
				subjects := query.readEntities( ENTITY_USER, TRUE, db, END_OF_QUERY, isWildCard );

				Len := Length( subjects );

				if ( not isWildCard ) and ( Len = 0 ) then
					raise Exception.Create( 'Expected a user list separated by space' );

				arg := query.nextArg();

				if arg <> '' then
				begin
					raise Exception.Create( 'Unexpected token "' + arg + '"' );
				end;

				if admin = FALSE then
					raise Exception.Create( 'Access denied ( command works only in administrative context )!');

				Len := Length( subjects );

				// Test if the group exist

				if not db.groupExists( gName ) then
					raise Exception.Create( 'Group "' + groupName + '" does not exist!' );

				// Test if all users from the subject exists

				for i := 0 to Len - 1 do begin
					if not db.userExists( subjects[i] ) then
						raise Exception.Create( 'User "' + subjects[i] + '" does not exist!' );
				end;

				// Good. We've got the subjects
				if ( operation = OP_ADD ) then
				begin

					db.createSnapshot();

					try

						group := db.getGroupByName( gName );

						for i := 0 to Len - 1 do
						begin
							user := db.getUserByName( subjects[i] );
							db.bindUG( user, group );
						end;

						db.commit();

						db.discardSnapshot();

					except
						On E: Exception do
						begin
							db.rollbackSnapshot();
							raise;
						end
					end;


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

					db.createSnapshot();

					try

						group := db.getGroupByName( gName );

						for i := 0 to Len - 1 do
						begin
							user := db.getUserByName( subjects[i] );
							db.unbindUG( user, group );
						end;

						db.commit();

						db.discardSnapshot();

					except
						On E: Exception do
						begin
							db.rollbackSnapshot();
							raise;
						end
					end;


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

				if ( tokWho <> 'to' ) and ( tokWho <> 'from' ) then
					raise Exception.Create( 'Illegal token "' + tokWho + '" ( expected "to" or "from" ), at index 3 [1]' );

				len := 0;

				// read subjects ( services )
				subjects := query.readEntities( ENTITY_SERVICE, TRUE, db, STOPWORD_ON, isWildCard );

				if ( isWildCard = FALSE ) and ( Length( subjects ) = 0 ) then
				begin
					raise Exception.Create( 'A list of one or more services is expected!' );
				end;

				arg := LowerCase( query.nextArg() );

				if ( arg <> '' ) then
				begin

					if arg <> 'on' then
					begin

						raise Exception.Create( 'Unexpected token "' + arg + '"' );

					end else
					begin

						// read subjects ( hosts )
						subjects1 := query.readEntities( ENTITY_HOST, TRUE, db, END_OF_QUERY, isWildCard1 );

						if ( isWildCard1 = FALSE ) and ( Length( subjects1 ) = 0 ) then
							raise Exception.Create( 'A list of one or more hosts is expected!' );
						

						if ( operation = OP_ADD ) then 
						begin
							explain := 'ALLOW group "' + gName + '" ';
							
							if ( isWildCard ) 
								then explain := explain + 'to use ALL SERVICES (' + IntToStr( Length(subjects) ) + ') '
								else explain := explain + 'to use SERVICE: "' + str_join( subjects, '", "' ) + '" ';

						end else
						if ( operation = OP_REMOVE ) then
						begin
							explain := 'PROHIBIT group "' + gName + '" ';

							if ( isWildCard )
								then explain := explain + ' from using ALL SERVICES (' + IntToStr( Length( subjects ) ) + ') '
								else explain := explain + ' from using SERVICE: "' + str_join(subjects, '", "' ) + '" ';

						end else
						begin

							explain := 'UNSET group "' + gName + '" ';

							if ( isWildCard )
								then explain := explain + ' from ALL SERVICES (' + IntToStr( Length( subjects ) ) + ') '
								else explain := explain + ' from SERVICE: "' + str_join(subjects, '", "' ) + '" ';
						end;

						if ( isWildCard1 )
							then explain := explain + 'ON ALL HOSTS (' + IntToStr( Length( subjects1 ) ) + ')'
							else explain := explain + 'ON HOST: "' + str_join(subjects1, '", "' ) + '"';

						if ( admin = FALSE ) then
							raise Exception.Create( 'Acces denied ( command works only in administrative context )!' );

						// commmit
						group := db.getGroupByName( gName );

						if ( group = NIL ) then
							raise Exception.Create( 'Group "' + groupName + '" does not exist!' );

						// test if all services exist
						Len := Length( subjects );

						for i := 0 to Len - 1 do
						begin
							if not db.serviceExists( subjects[i] ) then
							begin
								raise Exception.Create( 'Service "' + subjects[i] + '" does not exist!' );
							end;
						end;

						// test if all hosts exists
						Len := Length( subjects1 );

						for i := 0 to Len - 1 do
						begin
							if not db.hostExists( subjects1[i] ) then
							begin
								raise Exception.Create( 'Host "' + subjects1[i] + '" does not exist!' );
							end;
						end;

						// do changes
						db.createSnapshot();

						try

							Len := Length( subjects );
							Len1 := Length( subjects1 );

							for i := 0 to Len - 1 Do
							begin

								service := db.getServiceByName( subjects[i] );

								for j := 0 to Len1 - 1 Do
									begin

										host := db.getHostByName( subjects1[j] );

										if ( operation = OP_UNSET ) then
										begin
											db.bindHSG( host, group, service, FALSE, TRUE );
										end else
										if ( operation = OP_ADD ) then
										begin
											db.bindHSG( host, group, service, TRUE, FALSE );
										end else
										if ( operation = OP_REMOVE ) then
										begin
											db.bindHSG( host, group, service, FALSE, FALSE );
										end;

									end;

							end;

							db.commit();
							db.discardSnapshot();

							result := '{"explain": ' + json_encode( explain ) + '}';

							exit;

						except
							On E: Exception Do
							begin
								db.rollbackSnapshot();
								raise;
							end;
						end;
						

					end;

				end else
				begin

					raise Exception.Create( 'Unexpected end of query ( expected token ''on'' at argument ' + IntToStr( query.currentArgumentIndex ) + ' )' );

				end;

			end else
			begin

				raise Exception.Create( 'Unexpected token "' + arg + '" at argument ' + IntToStr( query.currentArgumentIndex ) + ': Expected "user" or "users" or "service" or "services"!' );

			end;

		end else
		begin

			if ( operation = OP_UNSET ) then
				raise Exception.Create( 'Illegal token unset ( at argument 2 )' );

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

				db.createSnapshot();

				try
					db.getGroupByName( gName ).remove();

					db.commit();

					db.discardSnapshot();

					result := '{"explain": ' + json_encode( 'Remove group "' + gName + '"' ) + '}';
				
				except

					On E: Exception do
					begin
						db.rollbackSnapshot();
						raise;
					end;
				end;

			end;

		end;

	end else
	begin
		// OPERATION IS OP_ENABLE, or OP_DISABLE

		isWildCard := FALSE;

		subjects :=  query.readEntities( ENTITY_GROUP, TRUE, db, END_OF_QUERY, isWildCard );

		arg := LowerCase( query.nextArg() );

		if ( arg <> '' ) then
			raise Exception.Create( 'Invalid token "' + arg + '" at index ' + IntToStr( Query.currentArgumentIndex ) );

		Len := Length( subjects );

		if ( not isWildCard ) and ( Len = 0 ) then
			raise Exception.Create( 'Expected at least one group, at index 3' );

		// check admin privileges
		if admin = FALSE then
			raise Exception.Create( 'Access denied' );

		// check if all groups exist
		if ( not isWildCard ) then
		begin

			for i := 0 to Len - 1 do
			begin
				if not db.groupExists(subjects[i]) then
					raise Exception.Create( 'Group "' + subjects[i] + '" does not exist!' );
			end;

		end;

		if ( isWildCard ) then
		begin

			if ( operation = OP_ENABLE ) then
				explain := 'Enable ALL groups (' + IntToStr(len) + ')'
			else
				explain := 'Disable ALL groups (' + IntToStr(len) + ')'

		end else
		begin

			if ( operation = OP_ENABLE ) 
			then explain := 'Enable '
			else explain := 'Disable ';
			if len = 1 then explain := explain + 'group ' else explain := explain + 'groups ';

			explain := explain + '"' + str_join( subjects, '", "' ) + '"';

		end;

		db.createSnapshot();
		db.hasErrors := FALSE;

		try

			for i := 0 to Len - 1 do
			begin
				group := db.getGroupByName( subjects[i] );
				
				if ( group <> NIL ) then
				begin

					if ( operation = OP_ENABLE ) then
					begin
						group.enabled := TRUE;
					end else
					begin
						group.enabled := FALSE;
					end;

					if ( db.hasErrors ) then
					begin
						raise Exception.Create( str_join( db.errorMessages, ', ' ) );
					end;

				end else
				begin
					raise Exception.Create('Group "' + subjects[i] + '" was not found' );
				end;

			end;
	
			db.commit();

			db.discardSnapshot();

			result := '{"explain": ' + json_encode( explain ) + '}';

		except

			On E: Exception do
			begin
				db.rollbackSnapshot();
				raise;
			end;
		end;


	end;
end;

function TPam2ExecutionContext.cmd_user  ( query: TQueryParser ): AnsiString;

var operation: byte;
    arg: AnsiString;

    userName: AnsiString;  // user name, unnormalized
    uName: AnsiString;     // normalized user name

    tokWho: AnsiString;

    subjects: TStrArray;
    subjects1: TStrArray;

    len: Integer;
    len1: Integer;

    isWildCard: Boolean;
    isWildCard1: Boolean;

    i: Integer;
    j: Integer;

    group: TPam2Group;
    user: TPam2User;
    host: TPam2Host;
    service: TPam2Service;

    END_OF_QUERY: TStrArray;
    STOPWORD_ON: TStrArray;

    explain: AnsiString;

    // FOR THE USER ADD ... SET ...
    set_email: Boolean;
    set_real_name: Boolean;
    set_enabled: Boolean;
    set_admin: Boolean;
    set_password: Boolean;

    set_flag: Boolean;

    val_email: AnsiString;
    val_real_name: AnsiString;
    val_enabled: Boolean;
    val_admin: Boolean;
    val_password: AnsiString;

begin
	
	setLength( END_OF_QUERY, 0 );
	setLength( STOPWORD_ON, 1 ); STOPWORD_ON[0] := 'on';

	arg := LowerCase( query.nextArg() );

	setLength( subjects, 0 );

	if arg = '' then raise Exception.Create( 'Missing token ( expected ADD | REMOVE | UNSET | ENABLE | DISABLE ), at index 1' );

	if arg = 'add' then
		operation := OP_ADD
	else
	if arg = 'remove' then
		operation := OP_REMOVE
	else
	if arg = 'unset' then
		operation := OP_UNSET
	else
	if arg = 'enable' then
		operation := OP_ENABLE
	else
	if arg = 'disable' then
		operation := OP_DISABLE
	else
		raise Exception.Create( 'Wrong predicate ( expected "add" or "remove" but got "' + arg + '" ), at index 1' );

	if ( operation <> OP_ENABLE ) and ( operation <> OP_DISABLE ) then
	begin

		userName := query.nextArg();
		uName := normalize( userName, ENTITY_USER );

		if userName = '' then
			raise Exception.Create( 'Missing token ( expected a <user_name> ), at index 2' );

		if uName = '' then
			raise Exception.Create( 'Illegal user name "' + userName + '", at index 2' );


		arg := LowerCase( query.nextArg() );

		if ( arg <> '' ) and ( arg <> 'set' ) then
		begin

			if ( arg <> 'to' ) and ( arg <> 'for' ) and ( arg <> 'from' ) then
				raise Exception.Create( 'Illegal token ( expected "to", "for", or "from" ), at index 3 [0]' );

			tokWho := arg;

			arg := LowerCase( query.nextArg() );

			if ( arg = 'group' ) or ( arg = 'groups' ) then
			begin

				if operation = OP_UNSET then
					raise Exception.Create( 'Illegal token "unset" at argument 2' );

				if ( tokWho <> 'to' ) and ( tokWho <> 'from' ) then
					raise Exception.Create( 'Illegal token "' + tokWho + '" ( expected "to" or "from" ), at index 3 [1]' );

				len := 0;

				// read subjects ( users )
				subjects := query.readEntities( ENTITY_GROUP, TRUE, db, END_OF_QUERY, isWildCard );

				Len := Length( subjects );

				if ( not isWildCard ) and ( Len = 0 ) then
					raise Exception.Create( 'Expected a groups list separated by space' );

				arg := query.nextArg();

				if arg <> '' then
				begin
					raise Exception.Create( 'Unexpected token "' + arg + '"' );
				end;

				if admin = FALSE then
					raise Exception.Create( 'Access denied ( command works only in administrative context )!');

				Len := Length( subjects );

				// Test if the user exist

				if not db.userExists( uName ) then
					raise Exception.Create( 'User "' + userName + '" does not exist!' );

				// Test if all groups from the subject exists

				for i := 0 to Len - 1 do begin
					if not db.groupExists( subjects[i] ) then
						raise Exception.Create( 'Group "' + subjects[i] + '" does not exist!' );
				end;

				// Good. We've got the subjects
				if ( operation = OP_ADD ) then
				begin

					db.createSnapshot();

					try

						user := db.getUserByName( uName );

						for i := 0 to Len - 1 do
						begin
							group := db.getGroupByName( subjects[i] );
							db.bindUG( user, group );
						end;

						db.commit();

						db.discardSnapshot();

					except
						On E: Exception do
						begin
							db.rollbackSnapshot();
							raise;
						end
					end;


					if ( isWildCard ) then
					begin

						result := '{"explain": ' + json_encode( 'Make user "' + uName + '" member of all groups (' + IntToStr( len ) + ')' ) + '}';

					end else
					begin

						if ( len = 1 ) then
							result := '{"explain": ' + json_encode( 'Make user "' + uName + '" member of group "' + str_join( subjects, '", "' ) + '"' ) + '}'
						else
							result := '{"explain": ' + json_encode( 'Make user "' + uName + '" member of groups "' + str_join( subjects, '", "' ) + '"' ) + '}';

					end;

				end else
				begin

					db.createSnapshot();

					try

						user := db.getUserByName( uName );

						for i := 0 to Len - 1 do
						begin
							group := db.getGroupByName( subjects[i] );
							db.unbindUG( user, group );
						end;

						db.commit();

						db.discardSnapshot();

					except
						On E: Exception do
						begin
							db.rollbackSnapshot();
							raise;
						end
					end;


					if ( isWildCard ) then
					begin

						result := '{"explain": ' + json_encode( 'Remove user "' + uName + '" from all groups (' + IntToStr(len) + ')' ) + '}';

					end else
					begin

						if ( len = 1 ) then
							result := '{"explain": ' + json_encode( 'Remove user "' + uName + '" from group "' + str_join( subjects, '", "' ) + '"' ) + '}'
						else
							result := '{"explain": ' + json_encode( 'Remove user "' + uName + '" from groups "' + str_join( subjects, '", "' ) + '"') + '}';

					end;

				end;


			end else
			if ( arg = 'service' ) or ( arg = 'services' ) then
			begin

				if ( tokWho <> 'to' ) and ( tokWho <> 'from' ) then
					raise Exception.Create( 'Illegal token "' + tokWho + '" ( expected "to" or "from" ), at index 3 [1]' );

				len := 0;

				// read subjects ( services )
				subjects := query.readEntities( ENTITY_SERVICE, TRUE, db, STOPWORD_ON, isWildCard );

				if ( isWildCard = FALSE ) and ( Length( subjects ) = 0 ) then
				begin
					raise Exception.Create( 'A list of one or more services is expected!' );
				end;

				arg := LowerCase( query.nextArg() );

				if ( arg <> '' ) then
				begin

					if arg <> 'on' then
					begin

						raise Exception.Create( 'Unexpected token "' + arg + '"' );

					end else
					begin

						// read subjects ( hosts )
						subjects1 := query.readEntities( ENTITY_HOST, TRUE, db, END_OF_QUERY, isWildCard1 );

						if ( isWildCard1 = FALSE ) and ( Length( subjects1 ) = 0 ) then
							raise Exception.Create( 'A list of one or more hosts is expected!' );
						

						if ( operation = OP_ADD ) then 
						begin
							explain := 'ALLOW user "' + uName + '" ';
							
							if ( isWildCard ) 
								then explain := explain + 'to use ALL SERVICES (' + IntToStr( Length(subjects) ) + ') '
								else explain := explain + 'to use SERVICE: "' + str_join( subjects, '", "' ) + '" ';

						end else
						if ( operation = OP_REMOVE ) then
						begin
							explain := 'PROHIBIT user "' + uName + '" ';

							if ( isWildCard )
								then explain := explain + ' from using ALL SERVICES (' + IntToStr( Length( subjects ) ) + ') '
								else explain := explain + ' from using SERVICE: "' + str_join(subjects, '", "' ) + '" ';

						end else
						begin

							explain := 'UNSET user "' + uName + '" ';

							if ( isWildCard )
								then explain := explain + ' from ALL SERVICES (' + IntToStr( Length( subjects ) ) + ') '
								else explain := explain + ' from SERVICE: "' + str_join(subjects, '", "' ) + '" ';
						end;

						if ( isWildCard1 )
							then explain := explain + 'ON ALL HOSTS (' + IntToStr( Length( subjects1 ) ) + ')'
							else explain := explain + 'ON HOST: "' + str_join(subjects1, '", "' ) + '"';

						if ( admin = FALSE ) then
							raise Exception.Create( 'Acces denied ( command works only in administrative context )!' );

						// commmit
						user := db.getUserByName( uName );

						if ( user = NIL ) then
							raise Exception.Create( 'User "' + userName + '" does not exist!' );

						// test if all services exist
						Len := Length( subjects );

						for i := 0 to Len - 1 do
						begin
							if not db.serviceExists( subjects[i] ) then
							begin
								raise Exception.Create( 'Service "' + subjects[i] + '" does not exist!' );
							end;
						end;

						// test if all hosts exists
						Len := Length( subjects1 );

						for i := 0 to Len - 1 do
						begin
							if not db.hostExists( subjects1[i] ) then
							begin
								raise Exception.Create( 'Host "' + subjects1[i] + '" does not exist!' );
							end;
						end;

						// do changes
						db.createSnapshot();

						try

							Len := Length( subjects );
							Len1 := Length( subjects1 );

							for i := 0 to Len - 1 Do
							begin

								service := db.getServiceByName( subjects[i] );

								for j := 0 to Len1 - 1 Do
									begin

										host := db.getHostByName( subjects1[j] );

										if ( operation = OP_UNSET ) then
										begin
											db.bindHSU( host, user, service, FALSE, TRUE );
										end else
										if ( operation = OP_ADD ) then
										begin
											db.bindHSU( host, user, service, TRUE, FALSE );
										end else
										if ( operation = OP_REMOVE ) then
										begin
											db.bindHSU( host, user, service, FALSE, FALSE );
										end;

									end;

							end;

							db.commit();
							db.discardSnapshot();

							result := '{"explain": ' + json_encode( explain ) + '}';

							exit;

						except
							On E: Exception Do
							begin
								db.rollbackSnapshot();
								raise;
							end;
						end;
						

					end;

				end else
				begin

					raise Exception.Create( 'Unexpected end of query ( expected token ''on'' at argument ' + IntToStr( query.currentArgumentIndex ) + ' )' );

				end;

			end else
			begin

				raise Exception.Create( 'Unexpected token "' + arg + '" at argument ' + IntToStr( query.currentArgumentIndex ) + ': Expected "group" or "groups" or "service" or "services"!' );

			end;

		end else
		begin

			if ( operation = OP_UNSET ) then
				raise Exception.Create( 'Illegal token unset ( at argument 2 )' );

			if admin = FALSE then
				raise Exception.Create( 'Access denied ( command works only in administrative context )!');

			// ADD GROUP gName to system.
			if ( operation = OP_ADD ) then
			begin

				set_flag := FALSE;

				// HANDLE THE "SET ... ARGUMENTS"
				if ( arg = 'set' ) then
				begin

					set_password := FALSE;
					set_admin    := FALSE;
					set_enabled  := FALSE;
					set_email    := FALSE;
					set_real_name:= FALSE;

					repeat

						arg := LowerCase( query.nextArg() );

						if ( arg <> '' ) then
						begin

							if ( arg = 'email' ) then
							begin

								if ( set_email ) then
									raise Exception.Create( 'Duplicate property declared: "email".' );

								set_flag := TRUE;

								arg := LowerCase( trim( query.nextArg() ) );

								if ( arg = '' ) then
									raise Exception.Create( 'Expected user email value, @ argument #' + IntToStr( query.currentArgumentIndex ) );

								val_email := db.normalizeEntity( arg, ENTITY_EMAIL );

								if ( val_email = '' ) then
									raise Exception.Create( 'Invalid email address: "' + arg + '"' );

								set_email := TRUE;

							end else
							if ( arg = 'real_name' ) then
							begin

								if ( set_real_name ) then
									raise Exception.Create( 'Duplicate property declared: "real_name".' );

								set_flag := TRUE;

								arg := trim( query.nextArg() );

								if ( arg = '' ) then
									raise Exception.Create( 'Expected user real name value, @ argument #' + IntToStr( query.currentArgumentIndex ) );

								val_real_name := db.normalizeEntity( arg, ENTITY_REAL_NAME );

								if ( val_real_name = '' ) then
									raise Exception.Create( 'Invalid user real name: "' + arg + '"' );

								set_real_name := TRUE;

							end else
							if ( arg = 'enabled' ) then
							begin

								if ( set_enabled ) then
									raise Exception.Create( 'Duplicate property declared: "enabled"' );

								set_flag := TRUE;

								arg := trim( LowerCase( query.nextArg() ) );

								if ( arg = '' ) then
									raise Exception.Create( 'Expected user enabled value, @ argument #' + IntToStr( query.currentArgumentIndex ) );

								if ( arg = '1' ) or ( arg = 'yes' ) or ( arg = 'true' ) or ( arg = 'on' ) or ( arg = 'y' )
								then val_enabled := TRUE
								else
								if ( arg = '0' ) or ( arg = 'no' ) or ( arg = 'false' ) or ( arg = 'off' ) or ( arg = 'n' )
								then val_enabled := FALSE
								else raise Exception.Create( 'User enabled value can be: 1, 0, y, n, yes, no, on, off' );

								set_enabled := TRUE;

							end else
							if ( arg = 'admin' ) then
							begin

								if ( set_admin ) then
									raise Exception.Create( 'Duplicate property declared: "admin"' );

								set_flag := TRUE;

								arg := trim( LowerCase( query.nextArg() ) );

								if ( arg = '' ) then
									raise Exception.Create( 'Expected user admin value, @ argument #' + IntToStr( query.currentArgumentIndex ) );

								if ( arg = '1' ) or ( arg = 'yes' ) or ( arg = 'true' ) or ( arg = 'on' ) or ( arg = 'y' )
								then val_admin := TRUE
								else
								if ( arg = '0' ) or ( arg = 'no' ) or ( arg = 'false' ) or ( arg = 'off' ) or ( arg = 'n' )
								then val_admin := FALSE
								else raise Exception.Create( 'User admin value can be: 1, 0, y, n, yes, no, on, off' );

								set_admin := TRUE;

							end else
							if ( arg = 'password' ) then
							begin

								if ( set_password ) then
									raise Exception.Create( 'Duplicate property declared: "password"' );

								set_flag := TRUE;

								arg := query.nextArg();


								if ( arg = '' ) then
									raise Exception.Create( 'Expected user password value, @ argument #' + IntToStr( query.currentArgumentIndex ) );

								val_password := arg;

								set_password := TRUE;

							end else
								raise Exception.Create( 'Unknown user property "' + arg + '" encountered in SET clause!' );

						end;

					until arg = '';

					if ( set_flag = FALSE ) then
						raise Exception.Create( 'Unexpected end of query. Expected a list with user attributes' );

				end;

				if db.userExists( uName ) then
					raise Exception.Create( 'A user with the same name allready exist!' );

				db.createSnapshot();

				try

					if ( set_flag = FALSE ) then
					
						db.createUser( uName )
					
					else begin
						
						if ( set_email = FALSE ) then val_email := '';
						if ( set_real_name = FALSE ) then val_real_name := '';
						if ( set_enabled = FALSE ) then val_enabled := TRUE;
						if ( set_admin = FALSE ) then val_admin := FALSE;
						if ( set_password = FALSE ) then val_password := '';

						if ( db.createUser( uName, val_real_name, val_email, val_enabled, val_admin, val_password ) = NIL ) then
						begin
							raise Exception.Create('Failed to create user: ' + str_join( db.errorMessages, ', ' ) );
						end;

					end;

					db.commit();

					db.discardSnapshot();

					result := '{"explain": ' + json_encode( 'Create user "' + uName + '"' ) + '}';

				except
					On E: Exception do
					begin
						db.rollbackSnapshot();
						raise;
					end
				end;
				

			end else
			begin

				if ( arg = 'set' ) then
					raise Exception.Create( 'Unexpected token "set", at argument ' + IntToStr( query.currentArgumentIndex ) );

				if not db.userExists( uName ) then
					raise Exception.Create('User "' + uName + '" does not exist!' );

				db.createSnapshot();

				try
					db.getUserByName( uName ).remove();

					db.commit();

					db.discardSnapshot();

					result := '{"explain": ' + json_encode( 'Remove user "' + uName + '"' ) + '}';
				
				except

					On E: Exception do
					begin
						db.rollbackSnapshot();
						raise;
					end;
				end;

			end;

		end;

	end else
	begin
		// OPERATION IS OP_ENABLE, or OP_DISABLE

		isWildCard := FALSE;

		subjects :=  query.readEntities( ENTITY_USER, TRUE, db, END_OF_QUERY, isWildCard );

		arg := LowerCase( query.nextArg() );

		if ( arg <> '' ) then
			raise Exception.Create( 'Invalid token "' + arg + '" at index ' + IntToStr( Query.currentArgumentIndex ) );

		Len := Length( subjects );

		if ( not isWildCard ) and ( Len = 0 ) then
			raise Exception.Create( 'Expected at least one user, at index 3' );

		// check admin privileges
		if admin = FALSE then
			raise Exception.Create( 'Access denied' );

		// check if all users exist
		if ( not isWildCard ) then
		begin

			for i := 0 to Len - 1 do
			begin
				if not db.userExists(subjects[i]) then
					raise Exception.Create( 'User "' + subjects[i] + '" does not exist!' );
			end;

		end;

		if ( isWildCard ) then
		begin

			if ( operation = OP_ENABLE ) then
				explain := 'Enable ALL users (' + IntToStr(len) + ')'
			else
				explain := 'Disable ALL users (' + IntToStr(len) + ')'

		end else
		begin

			if ( operation = OP_ENABLE ) 
			then explain := 'Enable '
			else explain := 'Disable ';
			if len = 1 then explain := explain + 'user ' else explain := explain + 'users ';

			explain := explain + '"' + str_join( subjects, '", "' ) + '"';

		end;

		db.createSnapshot();
		db.hasErrors := FALSE;

		try

			for i := 0 to Len - 1 do
			begin
				user := db.getUserByName( subjects[i] );
				
				if ( user <> NIL ) then
				begin

					if ( operation = OP_ENABLE ) then
					begin
						user.enabled := TRUE;
					end else
					begin
						user.enabled := FALSE;
					end;

					if ( db.hasErrors ) then
					begin
						raise Exception.Create( str_join( db.errorMessages, ', ' ) );
					end;

				end else
				begin
					raise Exception.Create('User "' + subjects[i] + '" was not found' );
				end;

			end;
	
			db.commit();

			db.discardSnapshot();

			result := '{"explain": ' + json_encode( explain ) + '}';

		except

			On E: Exception do
			begin
				db.rollbackSnapshot();
				raise;
			end;
		end;

	end;


end;


function TPam2ExecutionContext.cmd_select ( query: TQueryParser ): AnsiString;
var arg: AnsiString;
	narg: AnsiString;

    iEnabled: boolean;
    useEnabled: boolean;
    iDefault: boolean;
    useDefault : boolean;
    
    user: TPam2User;
    host: TPam2Host;
    service: TPam2Service;
    group: TPam2Group;

    subjects: TStrArray;
    isWildCard: boolean;
    isMultiple: boolean;

    END_OF_QUERY: TStrArray;

    entityType: integer;

    queryResults: TStrArray;
    match: boolean;

    numResults : Integer;

    explain: AnsiString;

    i : Integer;
    Len: Integer;

begin
	
	setLength( END_OF_QUERY, 0 );
	numResults := 0;

	arg := query.nextArg();

	if ( arg = '' ) then
	begin
		raise Exception.Create('Unexpected end of query!');
	end else
	if ( arg = 'my' ) then
	begin

		arg := LowerCase( query.nextArg() );

		if ( ( arg = 'user' ) or ( arg = 'details' ) or ( arg = 'identity' ) or ( arg = 'profile' ) ) then
		begin
			user := db.getUserById( lockedToUserId );
			
			if ( user = NIL ) then
			begin
				raise Exception.Create('Could not find you on server!');
			end;

			result := '{"explain": "Who you are", "data":' + user.toJSON + '}';

		end else
		if ( arg = 'groups' ) then
		begin

			user := db.getUserById( lockedToUserId );

			if ( user = NIL ) then
			begin
				raise Exception.Create('Could not find you on server!');
			end;

			result := '{"explain": "Your groups", "data": ' + json_encode( user.groupNames ) + '}';

		end else
		if ( arg = '' ) then
		begin
			raise Exception.Create('Unexpected end of query!' );
		end else
			raise Exception.Create('Unexpected token "' + arg + '"' );

	end else
	begin

		iEnabled := FALSE;
		useEnabled := FALSE;

		iDefault := FALSE;
		useDefault := FALSE;


		arg := lowercase( query.getArg( query.currentArgumentIndex - 1 ) );

		if ( arg = 'enabled' ) or ( arg = 'disabled' ) then
		begin
			useEnabled := true;

			if ( arg = 'enabled' ) then
				iEnabled := true;

			arg := lowercase( query.nextArg );

		end else
		if ( arg = 'default' ) then
		begin
			
			useDefault := TRUE;

			arg := lowercase( query.nextArg );

		end;

		if ( arg = '' ) then
		begin
			raise Exception.Create('Unexpected end of query!');
		end;

		isWildCard := FALSE;

		// compute the explain
		explain := 'List ';

		if ( useEnabled ) then
		begin
			if ( iEnabled ) then
				explain := explain + 'enabled '
			else
				explain := explain + 'disabled ';
		end;

		if ( useDefault ) then
			explain := explain + 'default ';

		case arg of
			'user': begin
				isMultiple := false;
				entityType := ENTITY_USER;
				
				arg := trim( query.nextArg() );

				if arg = '' then
					raise Exception.Create('User name expected!' );

				nArg := db.normalizeEntity( arg, ENTITY_USER );

				if ( nArg = '' ) then
					raise Exception.Create('Invalid user name "' + arg + '"' );

				setLength( subjects, 1 );
				subjects[0] := nArg;

				explain := explain + 'user named "' + arg + '"';

			end;

			'users': begin
				
				isMultiple := true;
				entityType := ENTITY_USER;

				subjects := query.readEntities( ENTITY_USER, TRUE, db, END_OF_QUERY, isWildCard );

				if ( not isWildCard ) and ( length(subjects) = 0 ) then
					raise Exception.Create('Expected a list of users or a wildcard' );

				if ( isWildCard ) then
					explain := explain + 'users (ALL)'
				else
					explain := explain + 'users who are named: "' + str_join( subjects, '", "' ) + '"';

			end;

			'group': begin
				isMultiple := false;
				entityType := ENTITY_GROUP;

				arg := trim( query.nextArg() );

				if ( arg = '' ) then
					raise Exception.Create('Group name expected!' );

				nArg := db.normalizeEntity( arg, ENTITY_GROUP );

				if ( nArg = '' ) then
					raise Exception.Create('Invalid group name "' + arg + '"' );

				setLength( subjects, 1 );
				subjects[0] := nArg;

				explain := explain + 'group named "' + arg + '"';

			end;

			'groups': begin
				isMultiple := true;
				entityType := ENTITY_GROUP;

				subjects := query.readEntities( ENTITY_GROUP, TRUE, db, END_OF_QUERY, isWildCard );

				if ( not isWildCard ) and ( length(subjects) = 0 ) then
					raise Exception.Create('Expected a list of groups or a wildcard' );

				if ( isWildCard ) then
					explain := explain + 'groups (ALL)'
				else
					explain := explain + 'groups who are named: "' + str_join( subjects, '", "' ) + '"';

			end;

			'host': begin

				isMultiple := false;
				entityType := ENTITY_HOST;

				arg := trim( query.nextArg() );

				if ( arg = '' ) then
					raise Exception.Create('Host name expected!' );

				nArg := db.normalizeEntity(arg, ENTITY_HOST );

				if ( nArg = '' ) then
					raise Exception.Create('Invalid host name "' + arg + '"' );

				setLength( subjects, 1 );
				subjects[0] := nArg;

				explain := explain + 'host named "' + arg + '"';

			end;

			'hosts': begin
				isMultiple := true;
				entityType := ENTITY_HOST;

				subjects := query.readEntities( ENTITY_HOST, TRUE, db, END_OF_QUERY, isWildCard );

				if ( not isWildCard ) and ( length(subjects) = 0 ) then
					raise Exception.Create('Expected a list of hosts or a wildcard' );

				if ( isWildCard ) then
					explain := explain + 'hosts (ALL)'
				else
					explain := explain + 'hosts who are named: "' + str_join( subjects, '", "' ) + '"';

			end;

			'service': begin

				isMultiple := false;
				entityType := ENTITY_SERVICE;
				
				arg := trim( query.nextArg );
				
				if ( arg = '' ) then
					raise Exception.Create('Service name expected!' );

				nArg := db.normalizeEntity( arg, ENTITY_SERVICE );

				if ( nArg = '' ) then
					raise Exception.Create('Invalid service name "' + arg + '"' );

				setLength( subjects, 1 );
				subjects[0] := nArg;

				explain := explain + 'service named "' + arg + '"';

			end;
			'services': begin
				isMultiple := true;
				entityType := ENTITY_SERVICE;

				subjects := query.readEntities( ENTITY_SERVICE, TRUE, db, END_OF_QUERY, isWildCard );

				if ( not isWildCard ) and ( length(subjects) = 0 ) then
					raise Exception.Create('Expected a list of services or a wildcard' );

				if ( isWildCard ) then
					explain := explain + 'services (ALL)'
				else
					explain := explain + 'services who are named: "' + str_join( subjects, '", "' ) + '"';

			end
			else begin
				raise Exception.Create('Invalid token "' + arg + '"' );
			end;
		end; // case

		arg := query.nextArg();

		if ( arg <> '' ) then
			raise Exception.Create( 'Unexpected token "' + arg + '"' );

		if ( not admin ) then
			raise Exception.Create( 'Acces denied. This command requires administrative privileges' );

		// test if everything exists
		len := Length( subjects );

		for i := 0 to len - 1 do
		begin

			case entityType of
				ENTITY_USER: begin

					if ( useDefault ) then
						raise Exception.Create('The "default" filter does not work when selecting users!' );

					user := db.getUserByName( subjects[i] );

					if ( user = NIL ) then
						raise Exception.Create('User "' + subjects[i] + '" does not exist!' );

				end;
				ENTITY_GROUP: begin

					if ( useDefault ) then
						raise Exception.Create('The "default" filter does not work when selecting groups!' );

					group := db.getGroupByName( subjects[i] );

					if ( group = NIL ) then
						raise Exception.Create('Group "' + subjects[i] + '" does not exist!' );

				end;
				ENTITY_SERVICE: begin

					if ( useDefault ) then
						raise Exception.Create('The "default" filter does not work when selecting services!' );

					if ( useEnabled ) then
						raise Exception.Create( 'The "enabled" or "disabled" filter does not work when searching services' );

					service := db.getServiceByName( subjects[i] );

					if ( service = NIL ) then
						raise Exception.Create( 'Service "' + subjects[i] + '" does not exist!' );

				end;
				ENTITY_HOST: begin

					if ( useEnabled ) then
						raise Exception.Create( 'The "enabled" or "disabled" filter does not work when searching hosts' );

					host := db.getHostByName( subjects[i] );

					if ( host = NIL ) then
						raise Exception.Create( 'Host "' + subjects[i] + '" does not exist!' );

				end;
			end;

		end;

		// everything exists.

		setLength( queryResults, 0 );

		for i := 0 to len - 1 do
		begin

			match := TRUE;

			case entityType of

				ENTITY_USER: begin

					user := db.getUserByName( subjects[i] );

					if ( useEnabled ) and ( user.enabled <> iEnabled ) then
						match := FALSE;

					if match then
					begin
						setLength( queryResults, numResults + 1 );
						queryResults[ numResults ] := user.toJSON;
						numResults := numResults + 1;
					end;

				end;

				ENTITY_GROUP: begin

					group := db.getGroupByName( subjects[i] );

					if ( useEnabled ) and ( not group.enabled ) then
						match := FALSE;

					if match then
					begin
						setLength( queryResults, numResults + 1 );
						queryResults[numResults] := group.toJSON;
						numResults := numResults + 1;
					end;

				end;

				ENTITY_SERVICE: begin

					service := db.getServiceByName( subjects[i] );
					
					setLength( queryResults, numResults + 1 );
					queryResults[ numResults ] := service.toJSON;
					numResults := numResults + 1;

				end;

				ENTITY_HOST: begin

					host := db.getHostByName( subjects[i] );

					if ( useDefault ) and ( host.default <> iDefault ) then
						match := FALSE;

					if match then
					begin
						setLength( queryResults, numResults + 1 );
						queryResults[ numResults ] := host.toJSON;
						numResults := numResults + 1;
					end;

				end;

			end;

		end;

		explain := explain + ' : ' + IntToStr( numResults ) + ' result(s) found';

		if ( isMultiple ) then
		begin

			result := '{"explain": ' + json_encode( explain ) + ', "data": [' + str_join(queryResults, ',') + '] }';

		end else
		begin

			if ( numResults > 0 ) then
			begin
				result := '{"explain": ' + json_encode( explain ) + ', "data": ' + queryResults[0] + '}';
			end else
			begin
				result := '{"explain": ' + json_encode( explain ) + ', "data": null }';
			end;

		end;

	end;

end;

function TPam2ExecutionContext.cmd_help( query: TQueryParser ): AnsiString;
var arg: AnsiString;
	helpFiles: TStrArray;
	helpPath: AnsiString;

	info: TSearchRec;
begin

	arg := trim( lowerCase( query.nextArg ) );

	if ( arg = '' ) or ( arg = 'server' ) then
	begin

		arg := trim( lowerCase( query.nextArg ) );

		if ( arg = '' ) then
		begin

			result := '{"explain": "Available server help", "data": ';

			setLength( helpFiles, 0 );

			if ( FindFirst( getApplicationDir() + PATH_SEPARATOR + 'help' + PATH_SEPARATOR + '*.txt', faAnyFile, Info ) = 0 ) then
			begin

				repeat

					setLength( helpFiles, Length( helpFiles ) + 1 );
					helpFiles[ Length(helpFiles) - 1 ] := copy( Info.Name, 1, Length( Info.Name ) - 4 );

				until FindNext( info ) <> 0;

				FindClose( info );

			end;


			result := result + json_encode( #10#13 + 'Type "help server <command>" to display additional info:'#10#13#10#13 + str_join( helpFiles, #10#13 ) + #10#13 ) + '}';

		end else
		begin

			if not str_match_chars( arg, 'abcdefghijklmnopqrstuvwxyz0123456789' ) then
			begin
				raise Exception.Create('Invalid command name "' + arg + '"' );
			end;

			helpPath := getApplicationDir() + PATH_SEPARATOR + 'help' + PATH_SEPARATOR + arg + '.txt';

			if ( not fileExists( helpPath ) ) then
				raise Exception.Create('Help for command "' + arg + '" was not found!' );

			result := '{"explain": "HELP for command ' + arg + '", "data": ';

			result := result + json_encode( readTextFileToString( helpPath ) );

			result := result + '}';

		end;


	end else
	begin

		raise Exception.Create('Unexpected token: ' + arg );

	end;

end;