{$mode objfpc}
{$H+}
unit Pam2CommandParser;

interface uses
	{$ifdef unix}cthreads, {$endif}
	QueryParser,
	classes,
	Logger
	;
	

	type TPam2CommandParser = class

		private
			query: TQueryParser;
			user: AnsiString;
			pass: AnsiString;

		public

			constructor Create( cmd: AnsiString; userName: AnsiString; password: AnsiString );
			procedure   Exec();
			destructor  Free();

	end;


implementation

	constructor TPam2CommandParser.Create( cmd: AnsiString; userName: AnsiString; password: AnsiString );
	begin
		query := TQueryParser.create(cmd);
		user := userName;
		pass := password;
	end;

	procedure TPam2CommandParser.Exec();
	begin
		Console.log( '[' + user + ']', query.toString() );
	end;

	destructor TPam2CommandParser.Free();
	begin
		query.Free();
	end;

end.