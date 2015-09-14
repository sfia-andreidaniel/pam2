// Declaration of Pam2Group object type. Form implementation,
// please see Pam2Group_impl.inc file

type TPam2Group = class

		protected

			db: TPam2DB;

			_group_id: integer;
			_group_name: AnsiString;
			_enabled: boolean;

			_users: Array of Integer;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

			procedure setGroupName( value: AnsiString );
			procedure setEnabled  ( value: Boolean );

		public
			

			property id        : integer    read _group_id;
			property groupName : AnsiString read _group_name write setGroupName;
			property enabled   : Boolean    read _enabled    write setEnabled;

			constructor Create( _db: TPam2DB; gid: integer; group_name: AnsiString; _is_enabled: Boolean; isSaved: boolean );
			constructor Create( _db: TPam2DB );

			function    Save(): Boolean;
			
			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure remove();
			procedure snapshot();
			procedure updateIdAfterInsertion();
			procedure rollback( snapshotLine: AnsiString );

	end;

