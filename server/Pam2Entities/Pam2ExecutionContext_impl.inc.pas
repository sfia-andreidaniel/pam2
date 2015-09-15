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
			raise Exception.Create( 'Invalid command: "' + arg + '" ( argument index: 0 )' );

	except

		On E: Exception Do
		begin

			raise;
		end;
	end;
end;

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
    subjects1: TStrArray;

    len: Integer;
    len1: Integer;

    uArg: AnsiString;

    isWildCard: Boolean;
    isWildCard1: Boolean;

    i: Integer;
    j: Integer;

    group: TPam2Group;
    user: TPam2User;
    host: TPam2Host;
    service: TPam2Service;

    needHost : Boolean;

    END_OF_QUERY: TStrArray;
    STOPWORD_ON: TStrArray;

    explain: AnsiString;

begin
	
	setLength( END_OF_QUERY, 0 );
	setLength( STOPWORD_ON, 1 ); STOPWORD_ON[0] := 'on';

	arg := LowerCase( query.nextArg() );

	setLength( subjects, 0 );

	if arg = '' then raise Exception.Create( 'Missing token ( expected "add" or "remove" ), at index 1' );

	if arg = 'add' then
		operation := OP_ADD
	else
	if arg = 'remove' then
		operation := OP_REMOVE
	else
	if arg = 'unset' then
		operation := OP_UNSET
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
						db.bindUserToGroup( user, group );
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
						db.unbindUserFromGroup( user, group );
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
			needHost := FALSE;

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



end;

function TPam2ExecutionContext.cmd_select ( query: TQueryParser ): AnsiString;
begin
	raise Exception.Create( 'select command is not implemented' );
end;
