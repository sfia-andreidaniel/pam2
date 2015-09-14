// Declaration of PAM2DB class. For implementation, please consult file
// Pam2DB_impl.inc

type TPam2DB = class

		protected

			db: TSqlConnection;

			hosts: Array of TPam2Host;
			services: Array of TPam2Service;
			groups: Array of TPam2Group;
			users: Array of TPam2User;

			sqlStatements: TStrArray;
			explanations : TStrArray;
			errors       : TStrArray;

			snapshot     : TStrArray;

			procedure Load();
			function  getDefaultHost(): TPam2Host;
			function  generateRandomUserPassword(): AnsiString;

			function  getAllUsersList(): TStrArray;
			procedure doSQLStatement( statement: AnsiString );
			procedure removeAndDisposeDeletedObjects();

		public

			constructor Create( _db: TSqlConnection );
			destructor  Free();

			property defaultHost: TPam2Host read getDefaultHost;
			property allUsers: TStrArray read getAllUsersList;

			function getUserById      ( userId: Integer ): TPam2User;
			function getUserByName    ( loginName: AnsiString ): TPam2User;
			function getUserByEmail   ( emailAddress: AnsiString ): TPam2User;

			function getGroupById     ( groupId: Integer ): TPam2Group;
			function getGroupByName   ( groupName: AnsiString ): TPam2Group;

			function getHostById      ( hostId: Integer ): TPam2Host;
			function getHostByName    ( hostName: AnsiString ): TPam2Host;

			function getServiceById   ( serviceId: Integer ): TPam2Service;
			function getServiceByName ( serviceName: AnsiString ): TPam2Service;

			function userExists       ( userName: AnsiString; const ignoreUserId: integer = 0 ): Boolean;
			function userExists       ( userId: Integer; const ignoreUserId: integer = 0 ): Boolean;
			function userExistsByEmail( emailAddress: string; const ignoreUserId: integer = 0 ): Boolean;

			function groupExists      ( groupName: AnsiString; const ignoreGroupId: integer = 0 ): Boolean;
			function groupExists      ( groupId: Integer; const ignoreGroupId: integer = 0 ): Boolean;
			
			function hostExists       ( hostName: AnsiString; const ignoreHostId: integer = 0 ): Boolean;
			function hostExists       ( hostId: Integer; const ignoreHostId: Integer = 0 ): Boolean;
			
			function serviceExists    ( serviceName: AnsiString; const ignoreServiceId: integer = 0 ): Boolean;
			function serviceExists    ( serviceId: Integer; const ignoreServiceId: Integer = 0 ): Boolean;

			function  encryptPassword  ( password: AnsiString ): AnsiString;

			procedure addSQLStatement ( statement: AnsiString );
			procedure addExplanation  ( explanation: AnsiString );
			procedure addError        ( error: AnsiString );
			procedure addSnapshot     ( line: AnsiString );

			// Context execution

			function createContext    ( userName: ansiString; password: AnsiString ): TPam2ExecutionContext;

			// CREATE FUNCTION
			function createUser       ( loginName: AnsiString; 
				                        const realName: AnsiString = ''; 
				                        const emailAddress: AnsiString = ''; 
				                        const enabled: boolean = TRUE; 
				                        const isAdmin: boolean = FALSE; 
				                        const password: AnsiString = ''
				                      ): TPam2User;

			function createGroup      ( groupName: AnsiString;
										const enabled: boolean = TRUE
									  ): TPam2Group;

			function createHost       ( hostName: AnsiString; 
				                        const isDefault: Boolean = false 
				                      ): TPam2Host;

			function createService    ( serviceName: AnsiString ): TPam2Service;

			// SNAPSHOT FUNCTIONALITY

			procedure createSnapshot();
			procedure debugSnapshot();
			procedure rollbackSnapshot();
			procedure discardSnapshot();

			function  fetchSQLStatementResultAsInt( statement: AnsiString ): Integer;

			procedure commit();

	end;

