// Declaration of Pam2Service class. For implementation, see file Pam2Service_impl.inc.pas

type TPam2Service = class

		protected

			db: TPam2DB;

			_service_id: integer;
			_service_name: AnsiString;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

			procedure SetServiceName( value: AnsiString );
			function  Save(): Boolean;

		public

			property    id           : Integer    read _service_id;
			property    serviceName  : AnsiString read _service_name    write   setServiceName;

			constructor Create( _db: TPam2DB; sid: integer; sname: AnsiString; isSaved: boolean );
			constructor Create( _db: TPam2DB; sid: integer );

			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure   remove();
			procedure   snapshot();
			procedure   updateIdAfterInsertion();
			procedure   rollback( snapshotLine: AnsiString );

			function    equals( service: TPam2Service ): Boolean;

	end;
