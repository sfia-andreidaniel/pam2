constructor TPam2Service.Create( _db: TPam2DB; sid: integer; sname: AnsiString; password_type: AnsiString; isSaved: boolean );
var nptype: AnsiString;
begin

	db := _db;

	needSave := not isSaved;
	deleted := FALSE;

	_service_id := sid;
	_service_name := sname;

	nptype := trim( lowercase( password_type ) );

	case nptype of
		'md5': begin
			_password_type := PASSTYPE_MD5;
		end;
		'crypt': begin
			_password_type := PASSTYPE_CRYPT;
		end;
		'password': begin
			_password_type := PASSTYPE_PASSWORD;
		end;
		'bin': begin
			_password_type := PASSTYPE_BIN;
		end
		else begin
			_password_type := PASSTYPE_PLAIN;
		end;
	end;

end;

constructor TPam2Service.Create( _db: TPam2DB; sid: Integer );
begin

	db := _db;

	needSave := FALSE;
	deleted := FALSE;

	_service_id := sid;
	_service_name := '';
	_password_type := PASSTYPE_PLAIN;

end;

procedure TPam2Service.snapshot();
begin

	if ( _service_id = 0 ) then exit; // cannot snapshot

	db.addSnapshot( 'SERVICE ' + IntToStr( _service_id ) );

	db.addSnapshot( '_service_name: ' + _service_name );
	db.addSnapshot( '_password_type: ' + IntToStr(_password_type ) );
	
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
	if propName = '_password_type' then
	begin
		_password_type := StrToInt( propValue );
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
	if ( needSave = FALSE ) then
	begin
		result := TRUE;
	end else
	begin

		if ( not deleted ) then
		begin

			if ( _service_id = 0 ) then
			begin

				db.addSQLStatement(
					'INSERT INTO `service` ( service_name, password_type ) VALUES (' + json_encode( _service_name ) + ', ' + json_encode( passwordType ) + ')'
				);

			end else
			begin

				db.addSQLStatement(
					'UPDATE `service` SET service_name = ' + json_encode( _service_name ) + ', password_type = ' + json_encode( passwordType ) + ' WHERE service_id = ' + IntToStr( _service_id ) + ' LIMIT 1'
				);

			end;

		end else
		begin

			if ( _service_id <> 0 ) then
			begin
				db.addSQLStatement( 'DELETE FROM `service` WHERE service_id = ' + IntToStr( _service_id ) + ' LIMIT 1' );
			end;

		end;

		result := TRUE;
		needSave := FALSE;

	end;
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
		needSave := TRUE;
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
		db.unbindSO( self );
		db.unbindSHO( self );
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

function TPam2Service._toJSON(): AnsiString;
var opts: TStrArray;
    bindings: TPam2ServiceOption_List;
    i: Integer;
    len: Integer;
begin
	result := '{"type":"service",';
	result := result + '"id":' + json_encode(_service_id) + ',';
	result := result + '"name":' + json_encode(_service_name) + ',';
	result := result + '"passwordType":' + json_encode( passwordType ) + ',';

	bindings := db.getSOBindings( self );

	len := length( bindings );

	setLength( opts, len * 2 );

	for i := 0 to len - 1 do
	begin

		opts[ i * 2 ] := bindings[i].name;
		opts[ i * 2 + 1 ] := bindings[i].value;

	end; 

	result := result + '"options": ' + json_encode_object( opts );

	result := result + '}';
end;

function TPam2Service._getOptionsNames: TStrArray;
var i: Integer;
    Len: Integer;
    bindings: TPam2ServiceOption_List;
begin
	bindings := db.getSOBindings( self );
	Len := Length( bindings );
	setLength( result, Len );
	
	for i := 0 To Len - 1 do
		result[i] := bindings[i].name;

	setLength( bindings, 0 );
end;

procedure TPam2Service.setOption( optionName: AnsiString; optionValue: AnsiString );
var lcOption: AnsiString;
    lnOption: AnsiString;
begin

	lcOption := trim( lowerCase( optionName ) );
	lnOption := normalize( lcOption, ENTITY_SERVICE_OPTION );

	if ( lcOption <> '' ) and ( lnOption = lcOption ) then
	begin

		db.bindSO( self, lcOption, optionValue );

	end else
		raise Exception.Create('Invalid service option name "' + optionName + '"' );

end;

function TPam2Service._getOptions: TPam2ServiceOption_List;
begin
	result := db.getSOBindings( self );
end;

function TPam2Service.hasOption( optionName: AnsiString ): Boolean;
var opts: TPam2ServiceOption_List;
    i: Integer;
    Len: Integer;
    optName: AnsiString;
begin

	optName := trim( lowerCase( optionName ) );
	opts := _getOptions();
	Len := Length( opts );

	result := FALSE;

	for i := 0 to Len - 1 do
		if ( opts[i].name = optName ) then
		begin
			result := TRUE;
			break;
		end;

end;

function TPam2Service._getPasswordType(): AnsiString;
begin
	result := '';

	case _password_type of
      PASSTYPE_PLAIN:    result := 'plain';
      PASSTYPE_MD5:      result := 'md5';
      PASSTYPE_CRYPT:    result := 'crypt';
      PASSTYPE_PASSWORD: result := 'password';
      PASSTYPE_BIN:      result := 'bin';
    end;
end;

procedure TPam2Service._setPasswordType( passType: AnsiString );
var lcPass: AnsiString;
	newPassType: byte;
begin

	lcPass := LowerCase( trim( passType ) );

	newPassType := PASSTYPE_PLAIN;

	case lcPass of
		'md5': begin
			newPassType := PASSTYPE_MD5;
		end;
		'crypt': begin
			newPassType := PASSTYPE_CRYPT;
		end;
		'password': begin
			newPassType := PASSTYPE_PASSWORD;
		end;
		'bin': begin
			newPassType := PASSTYPE_BIN;
		end
		else begin
			newPassType := PASSTYPE_PLAIN;
		end;
	end;

	if ( newPassType <> _password_type ) then
	begin
		_password_type := newPassType;
		db.addExplanation( 'Set service password type of "' + passwordType + '" to service "' + serviceName + '"' );
		needSave := TRUE;
	end;

end;
