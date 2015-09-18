procedure do_query( query: TStrArray );

var i: integer;
    len: integer;

begin

	len := length( query );

	for i := 0 to len - 1 do writeln( i, '=>', query[i] );

	writeln;

end;

function prev_history(): AnsiString;
begin

	if ( historypos > 0 ) then
	begin
		historypos := historypos - 1;
		result := history[ historypos ];
	end else
	if ( historypos = 0 ) then
	begin
		result := '';
	end else
	begin

		if ( length( history ) > 0 ) then
		begin
			historypos := length( history ) - 1;
			result := history[ historypos ];
		end else
		begin
			result := '';
		end;

	end;

end;

function next_history(): AnsiString;
begin

	if ( historypos = -1 ) or ( historypos >= length( history ) - 1 ) then
	begin

		result := ''; // at end of history

	end else

	begin

		historypos := historypos + 1;
		result := history[ historypos ];

	end;

end;

function add_to_history( cmd: ansistring ): boolean;
var len: integer;
    i: integer;
    lastline: ansistring;
    tmp: ansistring;
begin

	len := length( history );

	result := false;

	if ( length( trim( cmd ) ) = 0 ) then
		exit;

	result := true;

	if ( len > 0 ) then
	begin

		lastline := history[ len - 1 ];

		for i := 0 to len - 1 do
		begin

			if ( history[i] = cmd ) then
			begin

				tmp := history[i];
				history[i] := lastline;
				history[ length(history) - 1 ] := tmp;
				exit;

			end;

		end;

		setLength( history, len + 1 );
		history[ len ] := cmd;

	end else
	begin

		setLength( history, len + 1 );
		history[ len ] := cmd;

	end;

	historypos := -1;

end;

procedure read_query( var query: TStrArray; user: AnsiString; host: AnsiString; var read_user: boolean; var read_host: boolean; var read_password: boolean );
var x: integer;
    c: char;
    cmd: ansistring;
    cmdi: ansistring;
    inspos: integer;
    histline: ansistring;

    parser: TQueryParser;

begin

	setLength( query, 0 );

	x := 1;

	inspos := 0;

	historypos := -1;

	gotoxy( 1, wherey );

	if ( read_user ) then
	begin
		x := x + length( user );
		textcolor( lightcyan );
		write(user);
	end;

	if ( read_host ) then
	begin

		textcolor(lightgray);
		write('@');
		textcolor(lightgreen);
		write(host);
		x := x + length( host ) + 1;

	end;

	textcolor(white);

	write('> ');

	x := x + 2;

	cmd := '';

	repeat

		c := readKey;

		if ( ord( c ) >= 32 ) then
		begin

			//cmd := cmd + c;

			cmdi := c;

			insert( cmdi, cmd, inspos + 1 );

			inspos := inspos + 1;

		end else
		begin

			case c of
				#0: begin 
					c := readkey; 

					case c of

						#0: begin end;
						

						#75: begin // left
							if ( inspos > 0 ) then
								inspos := inspos - 1;
						end;

						#77: begin // right
							if ( inspos < length( cmd ) ) then
								inspos := inspos + 1;
						end;

						#72: begin
							
							if ( cmd <> '' ) and ( ( historypos = -1 ) or ( historypos = length(history)-1 ) ) then
							begin
								add_to_history( cmd );
								historypos := length( history ) - 1;
							end;

							histline := prev_history();

							if ( histline <> '' ) then
							begin
								cmd := histline;
								inspos := length( cmd );
							end;

						end;

						#80: begin
					
							histline := next_history();

							if ( histline <> '' ) then
							begin

								cmd := histline;
								inspos := length( cmd );

							end;

						end;

						#83: begin //delete
							if ( inspos < length(cmd) ) then
								delete( cmd, inspos + 1, 1 );
						end

						else begin
							writeln( '#0', ord(c) );
						end;

					end;

				end;

				#8: begin //backspace
					
					if ( inspos > 0 ) then
					begin
						delete( cmd, inspos, 1 );
						inspos := inspos - 1;
					end;

				end
			end;

		end;

		gotoxy( x, wherey );
		clreol();
		textcolor( lightgray );
		write( cmd );

		gotoxy( x + inspos, wherey );

	until c = #13;

	if ( add_to_history( cmd ) ) then
	begin

		setLength( query, 0 );
		parser := TQueryParser.Create( cmd );

		repeat

			cmd := parser.nextArg;

			if ( cmd <> '' ) then
			begin
				setLength( query, length(query) + 1 );
				query[length(query)-1] := cmd;
			end;

		until cmd = '';

		parser.Free;

	end;

	writeln();

end;