procedure show_help();
begin
	writeln('PAM2 client');
	writeln('USAGE:');
	writeln('pam2 [ -u <username> ] [ -p <password> ] [ -h <hostname> ] [ -q <query_arg_1> <query_arg_2> ... <query_arg_n> ]' );
	writeln('pam2 --version   - shows version');
	writeln('pam2 --help      - shows this help');
	halt(0);
end;

procedure show_version();
begin
	writeln('1.0');
	halt(0);
end;

function is_quit( cmd: TStrArray ): boolean;
begin
	if ( length(cmd) = 1 ) and ( lowercase( cmd[0] ) = 'quit' ) then
	begin
		result := true;
	end else
	begin
		result := false;
	end;
end;

function is_login( cmd: TStrArray ): boolean;
begin

	if ( length( cmd ) = 1 ) and ( lowercase( cmd[0] ) = 'login' ) then
	begin
		result := true;
	end else
	begin
		result := false;
	end;

end;

function is_clear( cmd: TStrArray ): boolean;
begin

	if ( length( cmd ) = 1 ) and ( lowercase( cmd[0] ) = 'clear' ) then
	begin
		result := true;
	end else
	begin
		result := false;
	end;

end;


function is_host( cmd: TStrArray ): boolean;
begin

	if ( length( cmd ) >= 1 ) and ( lowercase(cmd[0]) = 'host' ) then
	begin

		result := true;

	end else
	begin
		result := false;
	end;

end;

function is_help( cmd: TStrArray ): boolean;
begin

	if ( length( cmd ) = 1 ) and ( lowercase(cmd[0]) = 'help' ) then
	begin
		result := true;
	end else
	begin
		result := false;
	end;

end;