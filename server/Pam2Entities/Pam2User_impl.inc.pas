constructor TPam2User.Create( _db: TPam2DB; uid: integer; login_name: AnsiString; real_name: AnsiString; user_email: AnsiString; user_enabled: boolean; is_admin: boolean; pam2_password: AnsiString; isSaved: boolean );
begin

	needSave := not isSaved;
	deleted := false;

	db := _db;

	_user_id := uid;
	_login_name := login_name;
	_real_name := real_name;
	_email := user_email;
	_enabled := user_enabled;
	_password := pam2_password;
	_admin := is_admin;

end;

constructor TPam2User.Create( _db: TPam2DB; uid: Integer );
begin

	needSave := FALSE;
	deleted := FALSE;
	db := _db;

	_user_id := uid;
	_login_name := '';
	_real_name := '';
	_email := '';
	_enabled := FALSE;
	_password := '';
end;

function TPam2User.Save(): boolean;
begin

	if ( needSave = FALSE ) then
	begin
		result := TRUE;
	end else
	begin

		if not deleted then
		begin

			if ( _user_id = 0 ) then
			begin
				// DO INSERT
				
				db.addSQLStatement( 
					'INSERT INTO `user` ( `login_name`, `real_name`, `email`, `user_enabled`, `is_admin`, `password` ) ' +
					'VALUES ( ' + 
						json_encode( _login_name ) + ', ' +
						json_encode( _real_name ) + ', ' +
						json_encode( _email ) + ', ' +
						IntToStr( Integer( _enabled ) ) + ', ' +
						IntToStr( Integer( _admin ) ) + ', ' +
						json_encode( _password ) + 
					')'
				);

			end else
			begin
				// DO UPDATE
				db.addSQLStatement(
					'UPDATE `user` SET '    +
						'`login_name` = '   + json_encode( _login_name )      + ', ' +
						'`real_name` = '    + json_encode( _real_name )       + ', ' +
						'`email` = '        + json_encode( _email )           + ', ' +
						'`user_enabled` = ' + IntToStr( Integer( _enabled ) ) + ', ' +
						'`is_admin` = '     + IntToStr( Integer( _admin ) )   + ', ' +
						'`password` = '     + json_encode( _password )        + ' '  +
					'WHERE user_id = ' + IntToStr( _user_id ) + ' ' +
					'LIMIT 1'
				);

			end;

		end else
		begin

			if ( _user_id > 0 ) then
			begin
				// DO DELETION
				db.addSQLStatement( 'DELETE FROM `user` WHERE `user_id` = ' + IntToStr( _user_id ) + ' LIMIT 1' );
			end;

		end;

		result := TRUE;
		needSave := FALSE;
	end;

end;

destructor TPam2User.Free();
begin

	if needSave = TRUE then
		Save();

	FreeWithoutSaving();

end;

destructor TPam2User.FreeWithoutSaving();
begin
end;


procedure TPam2User.snapshot();
begin

	if ( _user_id = 0 ) then exit; // cannot snapshot

	db.addSnapshot( 'USER ' + IntToStr( _user_id ) );

	db.addSnapshot( '_login_name: '  + _login_name );
	db.addSnapshot( '_real_name: '   + _real_name );
	db.addSnapshot( '_email: '       + _email );
	db.addSnapshot( '_enabled: '     + IntToStr( Integer( _enabled ) ) );
	db.addSnapshot( '_password: '    + _password );
	db.addSnapshot( '_admin: '       + IntToStr( Integer( _admin ) ) );
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
		needSave := TRUE;
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
		db.addError( '"' + value + '" real name is invalid or contains invalid characters!' );
	end else
	if rName = _real_name then
	begin
		// return
	end else
	begin
		needSave := TRUE;
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
		needSave := TRUE;
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
		
		needSave := TRUE;

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

		needSave := TRUE;

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

		needSave := TRUE;

	end;

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
		end else
		begin
			raise Exception.Create('Failed to update id of user ' + _login_name );
		end;
	end;

end;

procedure TPam2User.remove();
begin

	if ( not deleted ) then
	begin
		deleted := TRUE;
		needSave := TRUE;
		db.unbindUG( self );
		db.unbindHSU( self );
	end;

end;

procedure TPam2User.makeMemberOf( group: TPam2Group );
begin
	db.bindUG( self, group );
end;

procedure TPam2User.removeMembershipFrom( group: TPam2Group );
begin
	db.unbindUG( self, group );
end;

function TPam2User.equals( user: TPam2User ): Boolean;
begin

	if ( user = NIL ) then
	begin
		result := FALSE;
	end else
	begin

		if ( ( id > 0 ) and ( id = user.id ) ) or
		   ( ( loginName <> '' ) and ( loginName = user.loginName ) )
		then result := TRUE
		else result := FALSE;

	end;

end;

function TPam2User._toJSON(): AnsiString;
begin
	result := '{"type":"user",';

	result := result + '"id":' + json_encode(_user_id) + ',';
	result := result + '"name":' + json_encode( _login_name ) + ',';
	result := result + '"realName":' + json_encode( _real_name ) + ',';
	result := result + '"email":' + json_encode( _email ) + ',';
	result := result + '"enabled":'+json_encode( _enabled ) + ',';
	result := result + '"isAdmin":' + json_encode( _admin ) + ',';
	result := result + '"groups":' + json_encode( _getGroupNames );

	result := result + '}';
end;

function TPam2User._getGroupNames(): TStrArray;
var groups: TPam2UGBinding_List;
	i: Integer;
	Len: Integer;
begin
	groups := db.getUGBindings( self );
	Len := Length(groups);
	setLength( result, len );
	
	for i := 0 to Len - 1 do
		result[i] := groups[i].group.groupName;
end;