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

procedure TPam2User.remove();
begin

	if ( not deleted ) then
	begin
		deleted := TRUE;
		needSave := TRUE;		
	end;

end;