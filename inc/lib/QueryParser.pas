{$mode objfpc}
{$H+}
unit QueryParser;

interface uses
	{$ifdef unix}cthreads, {$endif}
	StringsLib
;

type TQueryParser = Class

	protected 
		args: TStrArray;
		currentArg: integer;

	public

		count: integer;

		property    raw: TStrArray read args;

		constructor Create( query: AnsiString );

		function getArg( index: integer ): AnsiString;
		function nextArg(): AnsiString;
		function toString(): AnsiString;

		procedure reset();

		destructor Free();

	end;

implementation
	
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

end.