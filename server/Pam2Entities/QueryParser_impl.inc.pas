function TQueryParser.toString(): AnsiString;
var i: integer;
begin
	result := '';
	for i := 0 to count - 1 do
	begin
		result := result + getArg(i);
		if i < count - 1 then result := result + ' ';
	end;
end;

function TQueryParser.nextArg(): AnsiString;
begin
	result := getArg( currentArg );
	currentArg := currentArg + 1;
end;

procedure TQueryParser.reset();
begin
	currentArg := 0;
end;

constructor TQueryParser.Create( query: AnsiString );

var i: integer;
    c: char;
    queryLen: integer;
    arg: ansiString;
    argLen: integer;
    iEsc: boolean;
    iQuote: boolean;

begin

	currentArg := 0;

	count := 0;
	setLength( args, 0 );

	queryLen := length( query );
	arg := '';
	argLen := 0;

	iEsc := FALSE;
	iQuote := FALSE;

	for i := 1 to queryLen do
	begin
		c := query[i];

		case c of

			'"': begin

				if iEsc = TRUE then
				begin
					argLen := argLen+1;
					arg := arg + c;
					iEsc := FALSE;
				end else
				begin
					iQuote := NOT iQuote;
					if iQuote = FALSE then
					begin
						if argLen > 0 then
							begin
								count := count + 1;
								setLength(args, count);
								args[count-1] := arg;
								arg := '';
								argLen := 0;
							end;
					end;
				end;
			end;

			'\': begin

				if iEsc = TRUE then
				begin
					argLen := argLen + 1;
					arg := arg + c;
					iEsc := FALSE;
				end else
				begin
					iEsc := TRUE;
				end;

			end;

			' ': begin

				if iEsc or iQuote then
				begin
					argLen := argLen + 1;
					arg := arg + c;
					iEsc := FALSE;
				end else
				begin

					if not iQuote then
					begin

						if argLen > 0 then
						begin
							count := count + 1;
							setLength(args, count);
							args[count-1] := arg;
							arg := '';
							argLen := 0;
						end;
					end;
				end;

			end

			else begin

				argLen := argLen + 1;
				arg := arg + c;

			end;

		end;		

	end;

	if argLen > 0 then
	begin
		count := count + 1;
		setLength(args, count);
		args[count-1] := arg;
	end;

end;

function TQueryParser.getArg( index: integer ): AnsiString;
begin
	if ( index >= 0 ) AND ( index < count ) then
	begin
		result := args[index];
	end else
	begin
		result := '';
	end;
end;

destructor TQueryParser.Free;
begin
	setLength( args, 0 );
end;

function TQueryParser.readEntities( 
	
	entityType: Integer; 
	allowWildcard: Boolean; 
	pam2Database: TPam2DB;
	
	const stopWords: TStrArray;

	var isWildCard: boolean

): TStrArray;

var arg: AnsiString;
    arg1 : AnsiString;

begin

	isWildCard := FALSE;

	setLength( result, 0 );

	if ( entityType <> ENTITY_HOST ) and
	   ( entityType <> ENTITY_USER ) and
	   ( entityType <> ENTITY_SERVICE ) and
	   ( entityType <> ENTITY_GROUP )
	then exit;

	if ( allowWildCard ) and ( getArg( currentArg ) = '*' ) then
	begin

		case entityType of
			ENTITY_HOST:     result := pam2Database.allHosts;
			ENTITY_USER:     result := pam2Database.allUsers;
			ENTITY_GROUP:    result := pam2Database.allGroups;
			ENTITY_SERVICE:  result := pam2Database.allServices;
		end;

		isWildCard := TRUE;

		currentArg := currentArg + 1;

		exit;

	end;

	arg := LowerCase( getArg( currentArg ) );

	while ( Length( arg ) > 0 ) and ( array_find( stopWords, arg ) = -1 )
	do begin

		if ( arg = '*' ) then
		begin

			case entityType of
				ENTITY_HOST: raise Exception.Create( 'Either you specify a wildcard (*), either you specify individual host names!' );
				ENTITY_USER: raise Exception.Create( 'Either you specify a wildcard (*), either you specify individual user names!' );
				ENTITY_GROUP: raise Exception.Create( 'Either you specify a wildcard (*), either you specify individual group names!' );
				ENTITY_SERVICE: raise Exception.Create( 'Either you specify a wildcard (*), either you specify individual service names!' );
			end;

		end;

		arg1 := pam2Database.normalizeEntity( arg, entityType );

		if  arg1 <> '' then
		begin
			setLength( result, Length( result ) + 1 );
			result[ Length( result ) - 1 ] := arg1;
			currentArg := currentArg + 1;
			arg := LowerCase( getArg( currentArg ) );
		end else
		begin

			case entityType of
				ENTITY_HOST: raise Exception.Create( '"' + getArg( currentArg ) + '" is not a valid host name' );
				ENTITY_USER: raise Exception.Create( '"' + getArg( currentArg ) + '" is not a valid user name' );
				ENTITY_GROUP: raise Exception.Create( '"' + getArg( currentArg ) + '" is not a valid group name' );
				ENTITY_SERVICE: raise Exception.Create( '"' + getArg( currentArg ) + '" is not a valid service name' );
			end;

		end;

	end;

	array_unique( result );

end;

// 1-based index
function TQueryParser.getCurrentArgumentIndex(): Integer;
begin
	result := currentArg;
end;

// 1-based index
function TQueryParser.getNextArgumentIndex(): Integer;
begin
	result := currentArg + 1;
end;