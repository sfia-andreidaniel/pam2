procedure TPam2DB.Load();
var FTransaction: TSQLTransaction;
    FQuery: TSQLQuery;
    I: Integer;
begin

	try // Finally try
	try // Catch try

/// LOADING USERS

		FTransaction := TSQLTransaction.Create(NIL);

		with FTransaction do
		begin
			Database := db;
			StartTransaction;
		end;

		FQuery := TSQLQuery.Create(NIL);
		with FQuery do
		begin
			Database := db;
			Transaction := FTransaction;
			ReadOnly := TRUE;
			SQL.Clear;
			SQL.Add('SELECT user_id, login_name, real_name, email, user_enabled, is_admin, password FROM user' );
		end;

		FQuery.Open;

		i := 0;

		While not FQuery.EOF do
		begin
			setLength( users, i + 1 );

			//uid: integer; login_name: AnsiString; real_name: AnsiString; user_email: AnsiString; user_enabled: boolean; is_admin: boolean; pam2_password: AnsiString; isSaved: boolean
			users[ i ] := TPam2User.Create(
				self,
				FQuery.FieldByName( 'user_id' ).asInteger,
				FQuery.FieldByName( 'login_name' ).asString,
				FQuery.FieldByName( 'real_name' ).asString,
				FQuery.FieldByName( 'email' ).asString,
				Boolean( FQuery.FieldByName( 'user_enabled' ).asInteger ),
				Boolean( FQuery.FieldByName( 'is_admin' ).asInteger ),
				LowerCase( FQuery.FieldByName( 'password' ).asString ),
				TRUE
			);

			i := i + 1;

			FQuery.Next;

		end;

		FQuery.Free;
		FTransaction.Free;


/// LOADING GROUPS

		FTransaction := TSQLTransaction.Create(NIL);

		with FTransaction do
		begin
			Database := db;
			StartTransaction;
		end;

		FQuery := TSQLQuery.Create(NIL);
		with FQuery do
		begin
			Database := db;
			Transaction := FTransaction;
			ReadOnly := TRUE;
			SQL.Clear;
			SQL.Add('SELECT group_id, group_name, group_enabled FROM `group`' );
		end;

		FQuery.Open;

		i := 0;

		While not FQuery.EOF do
		begin
			setLength( groups, i + 1 );
		
			// _db: TPam2DB; gid: integer; group_name: AnsiString; isSaved: boolean
			groups[ i ] := TPam2Group.Create(
				self,
				FQuery.FieldByName( 'group_id' ).asInteger,
				FQuery.FieldByName( 'group_name' ).asString,
				Boolean( FQuery.FieldByName('group_enabled').asInteger ),
				TRUE
			);

			i := i + 1;

			FQuery.Next;

		end;

		FQuery.Free;
		FTransaction.Free;

/// LOADING HOSTS

		FTransaction := TSQLTransaction.Create(NIL);

		with FTransaction do
		begin
			Database := db;
			StartTransaction;
		end;

		FQuery := TSQLQuery.Create(NIL);
		with FQuery do
		begin
			Database := db;
			Transaction := FTransaction;
			ReadOnly := TRUE;
			SQL.Clear;
			SQL.Add('SELECT id, name, `default` FROM `host`' );
		end;

		FQuery.Open;

		i := 0;

		While not FQuery.EOF do
		begin
			setLength( hosts, i + 1 );

			
			// _db: TPam2DB; hid: integer; hname: AnsiString; defaultHost: boolean; isSaved: boolean
			hosts[ i ] := TPam2Host.Create(
				self,
				FQuery.FieldByName( 'id' ).asInteger,
				FQuery.FieldByName( 'name' ).asString,
				Boolean(FQuery.FieldByName('default').asInteger),
				TRUE
			);

			i := i + 1;

			FQuery.Next;

		end;

		FQuery.Free;
		FTransaction.Free;

/// LOADING SERVICES

		FTransaction := TSQLTransaction.Create(NIL);

		with FTransaction do
		begin
			Database := db;
			StartTransaction;
		end;

		FQuery := TSQLQuery.Create(NIL);
		with FQuery do
		begin
			Database := db;
			Transaction := FTransaction;
			ReadOnly := TRUE;
			SQL.Clear;
			SQL.Add('SELECT service_id, service_name, password_type FROM `service`' );
		end;

		FQuery.Open;

		i := 0;

		While not FQuery.EOF do
		begin

			setLength( services, i + 1 );
			
			// _db: TPam2DB; sid: integer; sname: AnsiString; isSaved: boolean
			services[ i ] := TPam2Service.Create(
				self,
				FQuery.FieldByName( 'service_id' ).asInteger,
				FQuery.FieldByName( 'service_name' ).asString,
				FQuery.FieldByName( 'password_type').asString,
				TRUE
			);

			i := i + 1;

			FQuery.Next;

		end;

		FQuery.Free;
		FTransaction.Free;

/// LOADING USER + GROUP BINDINGS

		FTransaction := TSQLTransaction.Create(NIL);

		with FTransaction do
		begin
			Database := db;
			StartTransaction;
		end;

		FQuery := TSQLQuery.Create(NIL);
		with FQuery do
		begin
			Database := db;
			Transaction := FTransaction;
			ReadOnly := TRUE;
			SQL.Clear;
			SQL.Add('SELECT group_id, user_id FROM `group_users`' );
		end;

		FQuery.Open;

		While not FQuery.EOF do
		begin

			bindUG( FQuery.FieldByName( 'user_id' ).asInteger, FQuery.FieldByName('group_id').asInteger );
			FQuery.Next;

		end;

		FQuery.Free;
		FTransaction.Free;

// LOADING SERVICE + OPTIONS BINDINGS
		FTransaction := TSQLTransaction.Create( NIL );

		with FTransaction do
		begin
			Database := db;
			StartTransaction;
		end;

		FQuery := TSQLQuery.Create(NIL);
		with FQuery do
		begin
			Database := db;
			Transaction := FTransaction;
			ReadOnly := TRUE;
			SQL.Clear;
			SQL.Add('SELECT service_id, option_name, default_value FROM service_options' );
		end;

		FQuery.Open;

		while not FQuery.EOF do
		begin

			bindSO( FQuery.FieldByName( 'service_id' ).asInteger, FQuery.FieldByName( 'option_name').asString, FQuery.FieldByName( 'default_value' ).asString );
			FQuery.Next;

		end;

		FQuery.Free;
		FTransaction.Free;

// LOADING SERVICE + HOST + OPTIONS BINDINGS
		FTransaction := TSQLTransaction.Create( NIL );

		with FTransaction do
		begin
			Database := db;
			StartTransaction;
		end;

		FQuery := TSQLQuery.Create(NIL);
		with FQuery do
		begin
			Database := db;
			Transaction := FTransaction;
			ReadOnly := TRUE;
			SQL.Clear;
			SQL.Add('SELECT service_id, host_id, option_name, option_value FROM service_host_options' );
		end;

		FQuery.Open;

		while not FQuery.EOF do
		begin

			bindSHO( FQuery.FieldByName( 'service_id' ).asInteger, FQuery.FieldByName( 'host_id' ).asInteger, FQuery.FieldByName( 'option_name').asString, FQuery.FieldByName( 'option_value' ).asString );
			FQuery.Next;

		end;

		FQuery.Free;
		FTransaction.Free;

/// LOADING HOST + SERVICE + GROUPS PERMISSIONS

		FTransaction := TSQLTransaction.Create(NIL);

		with FTransaction do
		begin
			Database := db;
			StartTransaction;
		end;

		FQuery := TSQLQuery.Create(NIL);
		with FQuery do
		begin
			Database := db;
			Transaction := FTransaction;
			ReadOnly := TRUE;
			SQL.Clear;
			SQL.Add('SELECT host_id, service_id, group_id, allow FROM `service_host_groups`' );
		end;

		FQuery.Open;

		While not FQuery.EOF do
		begin

			bindHSG( 
				FQuery.FieldByName( 'host_id' ).asInteger,
				FQuery.FieldByName( 'group_id' ).asInteger,
				FQuery.FieldByName( 'service_id').asInteger,
				Boolean( FQuery.FieldByName('allow').asInteger ) 
			);
			
			FQuery.Next;

		end;

		FQuery.Free;
		FTransaction.Free;

/// LOADING HOST + SERVICE + USERS PERMISSIONS

		FTransaction := TSQLTransaction.Create(NIL);

		with FTransaction do
		begin
			Database := db;
			StartTransaction;
		end;

		FQuery := TSQLQuery.Create(NIL);
		with FQuery do
		begin
			Database := db;
			Transaction := FTransaction;
			ReadOnly := TRUE;
			SQL.Clear;
			SQL.Add('SELECT host_id, service_id, user_id, allow FROM `service_host_users`' );
		end;

		FQuery.Open;

		While not FQuery.EOF do
		begin

			bindHSU( 
				FQuery.FieldByName( 'host_id' ).asInteger,
				FQuery.FieldByName( 'user_id' ).asInteger,
				FQuery.FieldByName( 'service_id').asInteger,
				Boolean( FQuery.FieldByName('allow').asInteger ) 
			);
			
			FQuery.Next;

		end;

		FQuery.Free;
		FTransaction.Free;


/// CLEAR GENERATED SQL STATEMENTS BY calling bind* functions
		setLength( sqlStatements, 0 );

/// DISPLAY STATS

		Console.log('-', Length(users), 'users' );
		Console.log('-', Length(groups), 'groups' );
		Console.log('-', Length(hosts), 'hosts' );
		Console.log('-', Length(services), 'services' );
		Console.log('-', Length(UGBindings), 'UG bindings' );
		Console.log('-', Length(SOBindings), 'SO bindings' );
		Console.log('-', Length(SHOBindings), 'SHO bindings' );
		Console.log('-', Length(HSGPermissions), 'HSG permissions' );
		Console.log('-', Length(HSUPermissions), 'HSU permissions' );

	except

		On E: Exception do
		begin
			Console.error( 'General Exception: ', E.Message );
			raise;
		end;

	end;

	finally

	end;


end;

