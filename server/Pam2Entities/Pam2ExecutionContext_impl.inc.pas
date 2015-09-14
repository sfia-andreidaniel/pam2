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
