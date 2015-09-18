{$define client}
uses crt, AppUtils, StringsLib, sysutils;

var node_path : AnsiString;
    query : TStrArray;
    i: Integer;
    len: Integer;
    isQuery: boolean;
    arg: AnsiString;

    isArgs: Boolean;

    u_user: boolean;
    u_host: boolean;
    u_pwd : boolean;

    read_user: boolean;
    read_host: boolean;
    read_pwd: boolean;

    username: AnsiString;
    hostname: AnsiString;
    password: AnsiString;

    history: TStrArray;
    historypos: Integer;

{$I server/Pam2Entities/QueryParser_decl.inc.pas}
{$I server/Pam2Entities/QueryParser_impl.inc.pas}

{$I client/help.inc.pas}
{$I client/query.inc.pas}


begin

	setLength( history, 0 );
	historypos := -1;

	node_path := searchExecutable( 'node' );
	
	if ( node_path = '' ) then
		node_path := searchExecutable( 'nodejs' );

	if ( node_path = '' ) then
		die('This program requires the "nodejs" application. You can install it from "https://nodejs.org/en/".' );

	if not fileExists( getApplicationDir() + PATH_SEPARATOR + 'pam2.js' ) then
	begin
		die('A require file called "pam2.js" is missing from the application directory!');
	end;

	isQuery := FALSE;

	// process program arguments
	len := paramCount;

	isArgs := FALSE;

	setLength( query, 0 );

	read_user := false; u_user := false;
	read_host := false; u_host := false;
	read_pwd  := false; u_pwd  := false;

	username := '';
	hostname := '';
	password := '';


	for i := 1 to paramCount do
	begin

		arg := paramStr( i );
	
		case arg of
			'-q': begin
				isQuery := TRUE;
				isArgs := TRUE;
			end;
			'--help': begin
				if ( isArgs ) then
				begin
					die('Invalid argument "--help". The help argument cannot be used in conjunction with other arguments!' );
				end else
				begin
					show_help();
				end;
			end;
			'--version': begin
				if ( isArgs ) then
				begin
					die('Invalid argument "--version". The version argument cannot be used in conjunction with other arguments!');
				end else
				begin
					show_version();
				end;
			end;
			else begin
				if isQuery = TRUE then
				begin
					setLength( query, length( query ) + 1 );
					query[ length(query) - 1 ] := arg;
				end else
				begin

					if ( read_user = true ) or ( read_host = true ) or ( read_pwd = true ) then
					begin
						if ( read_user ) then
						begin
							username := arg;
							read_user := false;
						end else
						if ( read_host ) then
						begin
							hostname := arg;
							read_host := false;
						end else
						if ( read_pwd ) then
						begin
							password := arg;
							read_pwd := false;
						end
					end else
					begin

						case arg of
							'-u': begin

								if ( u_user ) then
								begin

									die( 'Duplicate argument "-u". Please type --help for help.' );

								end else
								begin

									u_user := true;
									read_user := true;

								end;

							end;
							'-p': begin

								if ( u_pwd ) then
								begin

									die( 'Duplicate argument "-p". Please type --help for help.' );

								end else
								begin

									u_pwd := true;
									read_pwd := true;

								end;

							end;
							'-h': begin

								if ( u_host ) then
								begin

									die( 'Duplicate argument "-h". Please type --help for help.' );

								end else
								begin

									u_host := true;
									read_host := true;

								end;

							end else
							begin
								die( 'Invalid argument: "' + arg + '". Please type --help for help.' );
							end;
						end;
					end;
				end;
			end;
		end;
	end;

	if ( read_user ) then
	begin
		die('Incomplete arguments list. Expected "<username>".');
	end else
	if ( read_pwd ) then
	begin
		die('Incomplete arguments list. Expected "<password>".');
	end else
	if ( read_host ) then
	begin
		die('Incomplete arguments list. Expected "<hostname>"');
	end;
	if ( isQuery ) and ( length(query) = 0 ) then
	begin
		die( 'Incomplete arguments list. Expected a PAM2 query!' );
	end;

	if ( isQuery ) then
	begin
		do_query( query );
	end else
	begin
		repeat
			
			read_query( query, username, hostname, u_user, u_host, u_pwd );

			if ( not is_quit( query ) and ( length(query) > 0 ) ) then
			begin
				do_query( query );
			end;

		until is_quit( query );

	end;


end.