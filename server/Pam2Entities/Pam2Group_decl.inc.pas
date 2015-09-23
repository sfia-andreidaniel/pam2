// Declaration of Pam2Group object type. Form implementation,
// please see Pam2Group_impl.inc file

type TPam2Group = class

		protected

			db: TPam2DB;

			_group_id: integer;
			_group_name: AnsiString;
			_enabled: boolean;

			needSave: boolean;
			deleted: boolean;

			procedure setGroupName( value: AnsiString );
			procedure setEnabled  ( value: Boolean );
			function  _toJSON(): AnsiString;
			function  _getUserNames: TStrArray;

		public

			property    id        : integer    read _group_id;
			property    groupName : AnsiString read _group_name write setGroupName;
			property    enabled   : Boolean    read _enabled    write setEnabled;
			property    userNames : TStrArray  read _getUserNames;
			property    toJSON    : AnsiString read _toJSON;

			constructor Create( _db: TPam2DB; gid: integer; group_name: AnsiString; _is_enabled: Boolean; isSaved: boolean );
			constructor Create( _db: TPam2DB; gid: Integer );

			function    Save(): Boolean;
			
			destructor  Free();
			destructor  FreeWithoutSaving();

			procedure 	remove();
			procedure 	snapshot();
			procedure 	updateIdAfterInsertion();
			procedure 	rollback( snapshotLine: AnsiString );

			procedure 	addUser   ( user: TPam2User; const unsave: boolean = TRUE );
			procedure 	removeUser( user: TPam2User; const unsave: boolean = TRUE );

			function  	equals( group: TPam2Group ): Boolean;

end;

