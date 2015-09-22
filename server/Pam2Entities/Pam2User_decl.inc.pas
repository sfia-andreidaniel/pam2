// Declaration of PAM2 User Entity. For implementation, please see
// file Pam2User_impl.inc

type TPam2User = class

		protected

			db: TPam2DB;

			_user_id: integer;
			_login_name: AnsiString;
			_real_name: AnsiString;
			_email: AnsiString;
			_enabled: boolean;

			_admin: boolean;
			_password: AnsiString;

			saved: boolean;
			needSave: boolean;
			deleted: boolean;

			procedure setLoginName( value: AnsiString );
			procedure setRealName ( value: AnsiString );
			procedure setEmail    ( value: AnsiString );
			procedure setEnabled  ( value: Boolean );
			procedure setAdmin    ( value: Boolean );
			procedure setPassword ( value: AnsiString );

			function _getGroupNames(): TStrArray;
			function _toJSON(): AnsiString;

		public

			property id         : integer    read _user_id;
			property loginName  : AnsiString read _login_name write setLoginName;
			property realName   : AnsiString read _real_name  write setRealName;
			property email      : AnsiString read _email      write setEmail;
			property enabled    : boolean    read _enabled    write setEnabled;
			property admin      : boolean    read _admin      write setAdmin;
			property password   : AnsiString read _password   write setPassword;
			property toJSON     : AnsiString read _toJSON;
			property groupNames : TStrArray  read _getGroupNames;

			constructor Create( _db: TPam2DB; uid: integer; login_name: AnsiString; real_name: AnsiString; user_email: AnsiString; user_enabled: boolean; is_admin: boolean; pam2_password: AnsiString; isSaved: boolean );
			constructor Create( _db: TPam2DB; uid: integer );

			destructor  Free();
			destructor  FreeWithoutSaving();

			function  save(): Boolean;
			function  equals( user: TPam2User ): Boolean;

			procedure remove();
			procedure snapshot();
			procedure updateIdAfterInsertion();
			procedure rollback( snapshotLine: AnsiString );

			procedure makeMemberOf( group: TPam2Group );
			procedure removeMembershipFrom( group: TPam2Group );

	end;

