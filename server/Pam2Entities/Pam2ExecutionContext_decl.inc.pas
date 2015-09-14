// Declaration of TPam2ExecutionContext class. For implementation, see
// file Pam2ExecutionContext_impl.inc


type TPam2ExecutionContext = class

		protected
			db: TPam2DB;
			admin: Boolean;
			lockedToUserId: Integer;

			// THE cmd_* functions should return a value allready encoded in JSON format,
			// or raise an exception if an error occurs.

			function cmd_host   ( query: TQueryParser ): AnsiString;
			function cmd_user   ( query: TQueryParser ): AnsiString;
			function cmd_service( query: TQueryParser ): AnsiString;
			function cmd_group  ( query: TQueryParser ): AnsiString;
			function cmd_select ( query: TQueryParser ): AnsiString;

		public 
			constructor Create( _db: TPam2DB; isAdmin: Boolean; lockedUserId: Integer );
			destructor  Free();

			function executeQuery( query: TQueryParser ): AnsiString;

	end;
