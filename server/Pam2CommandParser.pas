{$mode objfpc}
{$H+}
unit Pam2CommandParser;

interface uses
	{$ifdef unix}cthreads, {$endif}
	classes,
	Logger,
	Pam2Manager,
	Pam2Entities,
	sysutils,
	StringsLib
	;
	

	type TPam2CommandParser = class

		private
			query: TQueryParser;
			user: AnsiString;
			pass: AnsiString;

			_isError: boolean;
			_errorMessage: AnsiString;
			_result: AnsiString;

		public

			property result : AnsiString read _result;
			property error  : Boolean    read _isError;
			property reason : AnsiString read _errorMessage;

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
		
		_isError := FALSE;
		_errorMessage := '';
		_result := '';

	end;

	procedure TPam2CommandParser.Exec();
	
	var context: TPam2ExecutionContext;
	
	begin
		
		context := NIL;

		try

			try

				if query.count = 0 then
				begin
					raise Exception.Create('Empty query');
				end;

				context := IPam2Manager.PAM.createContext( user, pass );

				_result := context.executeQuery( query );

			except

				On E: Exception Do
				begin

					_isError := TRUE;
					_errorMessage := E.Message;

				end;

			end;

		finally

			if context <> NIL then
				context.Free();
		end;

	end;

	destructor TPam2CommandParser.Free();
	begin
		query.Free();
	end;

end.