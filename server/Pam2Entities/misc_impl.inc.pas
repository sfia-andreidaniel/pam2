// Misc functions used in Pam2Entities unit implementation

function is_username( value: AnsiString ): boolean;
begin
	if ( length( value ) = 0 ) or ( length(value) > MAXLEN_USER ) 
	    or ( not str_match_chars( value, FMT_USER ) )
	    or ( not str_match_chars( value[1], FMT_USER_BEGIN ) )
		then result := FALSE
		else result := TRUE;
end;

function is_groupname( value: AnsiString ): boolean;
begin
	if ( length( value ) = 0 ) or ( length(value) > MAXLEN_GROUP ) 
		or ( not str_match_chars(value, FMT_GROUP ) )
		or ( not str_match_chars(value[1], FMT_GROUP_BEGIN ) )
		then result := FALSE
		else result := TRUE;
end;

function is_servicename( value: AnsiString ): boolean;
begin
	if ( length( value ) = 0 ) or ( length(value) > MAXLEN_SERVICE ) 
		or ( not str_match_chars( value, FMT_SERVICE ) )
		or ( not str_match_chars( value[1], FMT_SERVICE_BEGIN ))
		then result := FALSE
		else result := TRUE;
end;

function is_hostname( value: AnsiString ): boolean;
begin
	if ( length( value ) = 0 ) or ( length(value) > MAXLEN_HOST ) 
		or ( not str_match_chars( value, FMT_HOST ) )
		or ( not str_match_chars( value[1], FMT_HOST_BEGIN ) )
		then result := FALSE
		else result := TRUE;
end;

function is_serviceoption( value: AnsiString ): boolean;
begin
	if ( length( value ) = 0 ) or ( length(value) > MAXLEN_SERVICEOPTION ) 
		or ( not str_match_chars( value, FMT_SERVICEOPTION ) )
		or ( not str_match_chars( value[1], FMT_SERVICEOPTION_BEGIN ) )
		then result := FALSE
		else result := TRUE;
end;

function is_realName( value: AnsiString ): Boolean;
begin

	if ( length( value ) = 0 ) or ( length(value) > MAXLEN_REALNAME ) or ( not str_match_chars( value, FMT_REALNAME ) )
		then result := FALSE
		else result := TRUE;
end;

function is_email( value: AnsiString ): boolean;

var numMonkeys: Integer;
    minDot: Integer;
    maxDot: Integer;
    minMonkeyPos: Integer;
    i: Integer;
    len: Integer;

begin

	numMonkeys := 0;

	minDot := -1;
	maxDot := -1;
	minMonkeyPos := -1;

	len := length(value);

	if ( len < 3 ) or ( len > MAXLEN_EMAIL ) 
		or ( not str_match_chars( value, FMT_EMAIL ) )
		or ( not str_match_chars( copy(value, 1, 1 ), FMT_EMAIL_BEGIN ) )
		then result := FALSE
		else result := TRUE;


	if ( result = TRUE ) then
	begin

		for i := 0 to len - 1 do
		begin

			case value[i] of
				
				'@': begin
					numMonkeys := numMonkeys + 1;
					if ( minMonkeyPos = -1 ) then
						minMonkeyPos := i;
				end;

				'.': begin
					
					if ( minDot = -1 ) then
						minDot := i;

					if ( maxDot < i ) then
						maxDot := i;

				end;

			end;

		end;

		if ( minMonkeyPos < 1 ) or ( numMonkeys <> 1 ) or ( minDot = minMonkeyPos - 1 ) or
		   ( maxDot = len - 1 ) 
		   then result := FALSE;

	end;

end;

function normalize( value: AnsiString; entityType: Byte ): AnsiString;
begin
	
	if entityType <> ENTITY_REAL_NAME
		then result := LowerCase( trim( value ) )
		else result := trim( value );

	case entityType of
			ENTITY_USER           : begin if ( not is_username( result ) ) then result := ''; end;
			ENTITY_GROUP          : begin if ( not is_groupname( result ) ) then result := ''; end;
			ENTITY_SERVICE        : begin if ( not is_servicename( result ) ) then result := ''; end;
			ENTITY_HOST           : begin if ( not is_hostname( result ) ) then result := ''; end;
			ENTITY_SERVICE_OPTION : begin if ( not is_serviceoption( result ) ) then result := ''; end;
			ENTITY_REAL_NAME      : begin if ( not is_realname( result ) ) then result := ''; end;
			ENTITY_EMAIL          : begin if ( not is_email( result ) ) then result := ''; end;
		else begin result := ''; end;
	end;

	if ( ( result = 'to' ) or 
		 ( result = 'for' ) or 
		 ( result = 'from' ) or 
		 ( result = 'on' ) or 
		 ( result = 'where' ) or 
		 ( result = 'in' ) 
	) and ( 
		( entityType = ENTITY_USER ) or 
		( entityType = ENTITY_GROUP ) or 
		( entityType = ENTITY_SERVICE ) or 
		( entityType = ENTITY_HOST ) or 
		( entityType = ENTITY_SERVICE_OPTION ) 
	) then result := '';

end;

// removes the element @position index, and returns the new length of the array

function array_remove( var a: TPam2HSGPermission_List; index: Integer ): Integer;
var i: Integer;
begin
	
	result := Length( a );

	if ( index >= 0 ) and ( index <= result - 1 ) then
	begin
		for i := index + 1 to result - 1 do
		begin
			a[ i - 1 ] := a[ i ];
		end;
		result := result - 1;
		setLength( a, result );
	end;

end;

// removes the element @position index, and returns the new length of the array

function array_remove( var a: TPam2HSUPermission_List; index: Integer ): Integer;
var i: Integer;
begin
	
	result := Length( a );

	if ( index >= 0 ) and ( index <= result - 1 ) then
	begin
		for i := index + 1 to result - 1 do
		begin
			a[ i - 1 ] := a[ i ];
		end;
		result := result - 1;
		setLength( a, result );
	end;

end;

// removes the element @position index, and returns the new length of the array

function array_remove( var a: TPam2UGBinding_List; index: Integer ): Integer;
var i: Integer;
begin
	
	result := Length( a );

	if ( index >= 0 ) and ( index <= result - 1 ) then
	begin
		for i := index + 1 to result - 1 do
		begin
			a[ i - 1 ] := a[ i ];
		end;
		result := result - 1;
		setLength( a, result );
	end;

end;
