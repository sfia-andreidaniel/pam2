// Declaration of class Pam2Host entity. For implementation, please consult
// Pam2Host_impl.inc file.

type TPam2Host = class

		protected 

			db: TPam2DB;

			_host_id: integer;
		    _host_name: AnsiString;
		    _default_host: Boolean;

		    _services: TPam2ServiceList;

		    // mapping for db table: service_host_groups
		    _group_policies: Array of TServiceHostGroupBinding;

		    // mapping for db table: service_host_users
		    _user_policies: Array of TServiceHostUserBinding;

		    _service_option_bindings: Array of TServiceHostOptionsBinding;

		    _service_useroption_bindings: Array of TServiceHostUserOptionBinding;
		    _service_groupoption_bindgs: Array of TServiceGroupOptionBinding;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

			procedure setHostName( value: AnsiString );
			procedure setDefaultHost( value: Boolean );

			function  getMachineServices(): TStrArray;
			procedure setMachineServices( svcs: TStrArray );

		public

			property id       : Integer read _host_id;
			property hostName : AnsiString read _host_name write setHostName;
			property default  : Boolean read _default_host write setDefaultHost;

			property machineServices: TStrArray read getMachineServices write setMachineServices;

			constructor Create( _db: TPam2DB; hid: integer; hname: AnsiString; defaultHost: boolean; isSaved: boolean );
			constructor Create( _db: TPam2DB; hid: integer );

			function    Save(): Boolean;
			
			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure remove();
			procedure snapshot();
			procedure updateIdAfterInsertion();
			procedure rollback( snapshotLine: AnsiString );

			function Equals( host: TPam2Host ): Boolean;

			procedure saveReferences();
			procedure deleteReferences();

	end;
