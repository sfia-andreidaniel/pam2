// Declaration of class Pam2Host entity. For implementation, please consult
// Pam2Host_impl.inc file.

type TPam2Host = class

		protected 

			db: TPam2DB;

			_host_id: integer;
		    _host_name: AnsiString;
		    _default_host: Boolean;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

			procedure   setHostName( value: AnsiString );
			procedure   setDefaultHost( value: Boolean );
			function    _toJSON(): AnsiString;

		public

			property    id       : Integer read _host_id;
			property    hostName : AnsiString read _host_name write setHostName;
			property    default  : Boolean read _default_host write setDefaultHost;
			property    toJSON   : AnsiString read _toJSON;

			constructor Create( _db: TPam2DB; hid: integer; hname: AnsiString; defaultHost: boolean; isSaved: boolean );
			constructor Create( _db: TPam2DB; hid: integer );

			function    save(): Boolean;
			
			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure   remove();
			procedure   snapshot();
			procedure   updateIdAfterInsertion();
			procedure   rollback( snapshotLine: AnsiString );

			function    equals( host: TPam2Host ): Boolean;

	end;
