// Declaration of Pam2Service class. For implementation, see file Pam2Service_impl.inc.pas

type TPam2Service = class

		protected

			db: TPam2DB;

			_service_id: integer;
			_service_name: AnsiString;
			_password_type: byte;

			needSave: boolean;
			deleted: boolean;

			procedure SetServiceName( value: AnsiString );
			function  Save(): Boolean;
			
			function  _getOptionsNames: TStrArray;
			function  _getOptions: TPam2ServiceOption_List;
			function  _toJSON(): AnsiString;

			function  _getPasswordType: AnsiString;
			procedure _setPasswordType( passType: AnsiString );

		public

			property    id           : Integer    read _service_id;
			property    serviceName  : AnsiString read _service_name    write   setServiceName;
			property    optionsNames : TStrArray  read _getOptionsNames;
			property    options      : TPam2ServiceOption_List read _getOptions;
			property    passwordType : AnsiString read _getPasswordType write _setPasswordType;

			property    toJSON       : AnsiString read _toJSON;

			constructor Create( _db: TPam2DB; sid: integer; sname: AnsiString; password_type: AnsiString; isSaved: boolean );
			constructor Create( _db: TPam2DB; sid: integer );

			procedure   setOption( optionName: AnsiString; optionValue: AnsiString );
			function    hasOption( optionName: AnsiString ): Boolean;

			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure   remove();
			procedure   snapshot();
			procedure   updateIdAfterInsertion();
			procedure   rollback( snapshotLine: AnsiString );

			function    equals( service: TPam2Service ): Boolean;

	end;
