// Declaration of PAM2DB class. For implementation, please consult file
// Pam2DB_impl.inc

type TPam2DB = class

		protected

			db             : TSqlConnection;

			hosts          : Array of TPam2Host;
			services       : Array of TPam2Service;
			groups         : Array of TPam2Group;
			users          : Array of TPam2User;

			sqlStatements  : TStrArray;
			explanations   : TStrArray;
			errors         : TStrArray;

			{ the in-memory dump state of db, which alows us to do rollback if something goes wrong }
			snapshot       : TStrArray;

			{ ( host, service, group, allow ) permission }
			HSGPermissions : TPam2HSGPermission_List;

			{ ( host, service, user, allow ) permissions }
			HSUPermissions : TPam2HSUPermission_List;

			{ ( user, group ) binding }
			UGBindings     : TPam2UGBinding_List;

			{ ( service, option ) binding }
			SOBindings     : TPam2ServiceOption_List;

			{ ( service, host, option ) binding }
			SHOBindings    : TPam2ServiceHostOption_List;

			procedure Load;
			function  getDefaultHost 			    : TPam2Host;
			function  generateRandomUserPassword    : AnsiString;

			function  getAllUsersList 				: TStrArray;
			function  getAllGroupsList				: TStrArray;
			function  getAllServicesList			: TStrArray;
			function  getAllHostsList				: TStrArray;

			function  getHasErrors					: Boolean;
			procedure setHasErrors( on: Boolean );

			procedure removeAndDisposeDeletedObjects;
			procedure dispatchSnapshotLine( snapshotLine: AnsiString );

			function  getBinDump(): AnsiString;

		public

			constructor Create( _db: TSqlConnection );
			destructor  Free();

			property defaultHost      : TPam2Host 		read getDefaultHost;
			
			property allUsers         : TStrArray 		read getAllUsersList;
			property allHosts         : TStrArray 		read getAllHostsList;
			property allServices      : TStrArray 		read getAllServicesList;
			property allGroups        : TStrArray 		read getAllGroupsList;

			property hasErrors        : Boolean   		read getHasErrors 
														write setHasErrors;

			property errorMessages    : TStrArray 		read errors;

			property binaryDump       : AnsiString      read getBinDump;


			function getUserById      ( userId: Integer )											: TPam2User;
			function getUserByName    ( loginName: AnsiString )										: TPam2User;
			function getUserByEmail   ( emailAddress: AnsiString )									: TPam2User;

			function getGroupById     ( groupId: Integer )											: TPam2Group;
			function getGroupByName   ( groupName: AnsiString )										: TPam2Group;

			function getHostById      ( hostId: Integer )											: TPam2Host;
			function getHostByName    ( hostName: AnsiString )										: TPam2Host;

			function getServiceById   ( serviceId: Integer )										: TPam2Service;
			function getServiceByName ( serviceName: AnsiString )									: TPam2Service;

			function userExists       ( userName: AnsiString; const ignoreUserId: integer = 0 )		: Boolean;
			function userExists       ( userId: Integer; const ignoreUserId: integer = 0 )		 	: Boolean;
			function userExistsByEmail( emailAddress: string; const ignoreUserId: integer = 0 )		: Boolean;

			function groupExists      ( groupName: AnsiString; const ignoreGroupId: integer = 0 )	: Boolean;
			function groupExists      ( groupId: Integer; const ignoreGroupId: integer = 0 )		: Boolean;
			
			function hostExists       ( hostName: AnsiString; const ignoreHostId: integer = 0 )		: Boolean;
			function hostExists       ( hostId: Integer; const ignoreHostId: Integer = 0 )			: Boolean;
			
			function serviceExists    ( serviceName: AnsiString; const ignoreServiceId: integer = 0 ): Boolean;
			function serviceExists    ( serviceId: Integer; const ignoreServiceId: Integer = 0 )	: Boolean;

			function  encryptPassword ( password: AnsiString )										: AnsiString;


			// SNAPSHOTS, STATEMENTS, ETC. INTERNAL STUFF

			procedure addSQLStatement ( statement: AnsiString );
			procedure addExplanation  ( explanation: AnsiString );
			procedure addError        ( error: AnsiString );
			procedure addSnapshot     ( line: AnsiString );

			// Context execution

			function createContext    ( userName: ansiString; password: AnsiString )				: TPam2ExecutionContext;

			// CREATE FUNCTIONS

			{ Creates a new User }
			function createUser       ( loginName: AnsiString; 
				                        const realName: AnsiString = ''; 
				                        const emailAddress: AnsiString = ''; 
				                        const enabled: boolean = TRUE; 
				                        const isAdmin: boolean = FALSE; 
				                        const password: AnsiString = ''
				                      ): TPam2User;

			{ Creates a new Group }
			function createGroup      ( groupName: AnsiString;
										const enabled: boolean = TRUE
									  ): TPam2Group;

			{ Creates a new Host }
			function createHost       ( hostName: AnsiString; 
				                        const isDefault: Boolean = false 
				                      ): TPam2Host;

			{ Creates a new service }
			function createService    ( serviceName: AnsiString ): TPam2Service;

			{ HOST + SERVICE + GROUPS bindings routines }
			procedure bindHSG          ( host: TPam2Host; group: TPam2Group; service: TPam2Service; allow: Boolean; const remove: Boolean = FALSE );
			procedure bindHSG          ( hostId: Integer; groupId: Integer; serviceId: Integer; allow: Boolean; const remove: Boolean = FALSE );
			procedure bindHSG          ( hostName: AnsiString; groupName: AnsiString; serviceName: AnsiString; allow: Boolean; const remove: Boolean = FALSE );
			procedure unbindHSG        ( host: TPam2Host );
			procedure unbindHSG        ( service: TPam2Service );
			procedure unbindHSG        ( group: TPam2Group );
			function  getHSGPermissions( host: TPam2Host )       : TPam2HSGPermission_List;
			function  getHSGPermissions( service: TPam2Service ) : TPam2HSGPermission_List;
			function  getHSGPermissions( group: TPam2Group )     : TPam2HSGPermission_List;

			{ HOST + SERVICE + USER bindings routines }
			procedure bindHSU          ( host: TPam2Host; user: TPam2User; service: TPam2Service; allow: Boolean; const remove: Boolean = FALSE );
			procedure bindHSU          ( hostId: Integer; userId: Integer; serviceId: Integer; allow: Boolean; const remove: Boolean = FALSE );
			procedure bindHSU          ( hostName: AnsiString; userName: AnsiString; serviceName: AnsiString; allow: Boolean; const remove: Boolean = FALSE );
			procedure unbindHSU        ( host: TPam2Host );
			procedure unbindHSU        ( service: TPam2Service );
			procedure unbindHSU        ( user: TPam2User );
			function  getHSUPermissions( host: TPam2Host )       : TPam2HSUPermission_List;
			function  getHSUPermissions( service: TPam2Service ) : TPam2HSUPermission_List;
			function  getHSUPermissions( user: TPam2User )       : TPam2HSUPermission_List;

			{ GROUP + USER bindings routines }
			procedure bindUG           ( user: TPam2User; group: TPam2Group      );
			procedure bindUG           ( userId: Integer; groupId: Integer         );
			procedure bindUG           ( userName: AnsiString; groupName: AnsiString );

			procedure unbindUG         ( user: TPam2User; group: TPam2Group );
			procedure unbindUG         ( user: TPam2User   );
			procedure unbindUG         ( group: TPam2Group );

			function  getUGBindings    ( user: TPam2User   ): TPam2UGBinding_List;
			function  getUGBindings    ( group: TPam2Group ): TPam2UGBinding_List;

			{ SERVICE + OPTIONS bindings routines }
			procedure bindSO           ( service: TPam2Service; option: AnsiString; value: AnsiString );
			procedure bindSO           ( serviceId: Integer; option: AnsiString; value: AnsiString );
			procedure unbindSO         ( service: TPam2Service; option: AnsiString );
			procedure unbindSO         ( service: TPam2Service );
			function  getSOBindings    ( service: TPam2Service ): TPam2ServiceOption_List;

			{ SERVICE + HOST + OPTIONS binding routines }
			procedure bindSHO          ( service: TPam2Service; host: TPam2Host; option: AnsiString; value: AnsiString );
			procedure bindSHO          ( serviceId: Integer;    hostId: Integer; option: AnsiString; value: AnsiString );
			procedure unbindSHO        ( service: TPam2service; host: TPam2Host );
			procedure unbindSHO        ( service: TPam2Service );
			procedure unbindSHO        ( host: TPam2Host );

			procedure unbindSHO        ( service: TPam2Service; option: AnsiString );
			procedure unbindSHO        ( host:    TPam2Host;    option: AnsiString );
			procedure unbindSHO        ( service: TPam2Service; host: TPam2Host; option: AnsiString );

			function  getSHOBindings   ( service: TPam2Service; host: TPam2Host ) 		: TPam2ServiceHostOption_List;
			function  getSHOBindings   ( service: TPam2Service ) 						: TPam2ServiceHostOption_List;
			function  getSHOBindings   ( host: TPam2Host )   							: TPam2ServiceHostOption_List;


			{ SNAPSHOT FUNCTIONALITY }

			// create an in-memory snapshot of the entities
			procedure createSnapshot();
			
			// displays the snapshot in console
			procedure debugSnapshot();
			
			// restores the snapshot
			procedure rollbackSnapshot();

			// clears the snapshot from memory, without saving it to database
			procedure discardSnapshot();

			// used to fetch primary keys of selected objects ( select id from ... where ... )
			function  fetchSQLStatementResultAsInt( statement: AnsiString ): Integer;

			// commits all pending operations.
			procedure commit();

			// commits only the pending sql statements
			procedure commitSQLStatements();
			
			procedure doSQLStatement( statement: AnsiString );

			function  normalizeEntity( inputStr: AnsiString; entityType: Integer ): AnsiString;

	end;

