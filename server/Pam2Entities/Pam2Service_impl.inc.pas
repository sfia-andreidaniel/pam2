constructor TPam2Service.Create( _db: TPam2DB; sid: integer; sname: AnsiString; isSaved: boolean );
begin

	db := _db;

	saved := isSaved;
	needSave := not saved;
	deleted := FALSE;

	_service_id := sid;
	_service_name := sname;

end;

constructor TPam2Service.Create( _db: TPam2DB; sid: Integer );
begin

	db := _db;

	saved := TRUE;
	needSave := FALSE;
	deleted := FALSE;

	_service_id := sid;
	_service_name := '';
end;

procedure TPam2Service.snapshot();
begin

	if ( _service_id = 0 ) then exit; // cannot snapshot

	db.addSnapshot( 'SERVICE ' + IntToStr( _service_id ) );

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

procedure TPam2Service.remove();
begin

	if ( not deleted ) then
	begin
		deleted := TRUE;
		needSave := TRUE;
		db.unbindHSG( self );
		db.unbindHSU( self );
	end;

end;

function TPam2Service.Equals( service: TPam2Service ): Boolean;
begin
	if service = NIL then
	begin
		result := FALSE;
	end else
	begin

		if ( ( id > 0 ) and ( id = service.id ) ) or
		   ( ( serviceName <> '' ) and ( serviceName = service.serviceName ) )
		then result := TRUE
		else result := FALSE;

	end;
end;
