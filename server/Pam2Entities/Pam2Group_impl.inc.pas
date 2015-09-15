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

constructor TPam2Group.Create( _db: TPam2DB; gid: integer );
begin

	db := _db;

	saved := TRUE;
	needSave := FALSE;
	deleted := FALSE;

	_group_id := gid;
	_group_name := '';
	_enabled := FALSE;

	setLength( _users, 0 );

end;

procedure TPam2Group.snapshot();
var i: integer;
    len: integer;
begin

	if ( _group_id = 0 ) then exit;

	db.addSnapshot( 'GROUP ' + IntToStr( _group_id )  );
	db.addSnapshot( '_group_name: ' + _group_name );
	db.addSnapshot( '_enabled: ' + IntToStr( Integer( _enabled ) ) );
	db.addSnapshot( 'saved: ' + IntToStr( Integer( saved ) ) );
	db.addSnapshot( 'needSave: ' + IntToStr( Integer( needSave ) ) );
	db.addSnapshot( 'deleted: ' + IntToStr( Integer( deleted ) ) );

	len := Length( _users );

	for i := 0 to len - 1 do
	begin
		if _users[i].id > 0 then begin
			db.addSnapshot( 'groupOf: ' + IntToStr( _users[i].id ) );
		end;
	end;

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
	if propName = 'groupOf' then
	begin
		addUser( db.getUserById( StrToInt( propValue ) ), FALSE );
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
				deleteReferences();
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

procedure TPam2Group.remove();
begin

	if ( not deleted ) then
	begin
		deleted := TRUE;
		needSave := TRUE;		
	end;

end;

procedure TPam2Group.addUser( user: TPam2User; const unsave: boolean = TRUE );
var i: Integer;
    len: Integer;
begin

	if ( user = NIL ) then
		exit;

	len := Length( _users );

	for i := 0 to len - 1 do
	begin

		if user.equals( _users[i] ) then
		begin
			exit;
		end;

	end;

	setLength( _users, len + 1 );

	_users[ len ] := user;

	if unsave then
		saved := FALSE;

end;

procedure TPam2Group.removeUser( user: TPam2User; const unsave: boolean = TRUE );

var i   : Integer;
    j   : Integer;
    len : Integer;

begin

	if ( user = NIL ) then
		exit;

	len := Length( _users );

	for i := len - 1 downto 0 do
	begin
		if _users[i].equals( user ) then
		begin
			for j := i + 1 to len - 1 do
			begin
				_users[ j - 1 ] := _users[ j + 1 ];
			end;
			setLength( _users, len - 1 );

			if unsave then
				saved := FALSE;

			break;
		end;
	end;


end;

function TPam2Group.Equals( group: TPam2Group ): Boolean;
begin
	if ( group = NIL ) then
	begin
		result := FALSE;
	end else
	begin

		if ( ( id > 0 ) and ( id = group.id ) ) or
		   ( ( groupName <> '' ) and ( groupName = group.groupName ) )

		then result := TRUE
		else result := FALSE;

	end;
end;

procedure TPam2Group.deleteReferences();
begin
	if ( _group_id > 0 ) then
	begin
		db.addSQLStatement( 'DELETE FROM `group_users` WHERE `group_id` = ' + IntToStr( _group_id ) );
	end;
end;

procedure TPam2Group.saveReferences();
var i: Integer;
    len: Integer;
begin

	deleteReferences();

	if ( _group_id > 0 ) and ( not deleted ) then
	begin

		len := Length( _users );

		for i := 0 to len - 1 do
		begin

			if ( _users[i].id > 0 ) then
			begin
				db.addSQLStatement( 'INSERT IGNORE into `group_users` ( `group_id`, `user_id` ) VALUES ( ' + IntToStr( _group_id ) + ', ' + IntToStr( _users[i].id ) + ' )' );
			end;
		end;
	end;
end;