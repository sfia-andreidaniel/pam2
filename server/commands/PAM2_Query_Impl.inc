    
    { IMPLEMENTATION OF THE PAM2_QUERY COMMAND. DECLARATION CAN BE FOUND IN THE "PAM2_Query_Type.inc" }

    constructor PAM2_QUERY.Create( _Session: TPam2Session; _Args: TJSON );
    var UserName: AnsiString;
        Password: AnsiString;
        Query: AnsiString;
        CmdId: LongInt;
    begin

        Name := 'QUERY';

        inherited;
        
        // Straight at constructor, we check if the _Args is valid,
        // IF it's authenticable via the ISockFTPManager, And send
        // Back the data to the client.
        
        // {"cmd":"query","data":{"query":"a query","user":"username", "password": "password"},"id":2}
        
        IsFinished := TRUE;
        
        if _Args.hasOwnProperty( 'data' ) and ( _Args.typeof( 'data' ) = 'object' ) and

           _Args.hasOwnProperty( 'id' )   and ( _Args.typeof( 'id' ) = 'number' ) and

           _Args.get('data').hasOwnProperty('user') and ( _Args.get('data').typeof('user') = 'string' ) and

           _Args.get('data').hasOwnProperty('password') and ( _Args.get('data').typeof('password') = 'string' ) and

           _Args.get('data').hasOwnProperty('query') and ( _Args.get('data').typeof('query') = 'string' )
        then
        begin
            
            UserName := _Args.get('data').get('user', '');
            Password := _Args.get('data').get('password', '');
            Query    := _Args.get('data').get('query', '');
            CmdID    := _Args.get( 'id', 0 );
            
            _Session.SendText( '{ "id": ' + IntToStr( CmdID ) + ', "ok": true }' );
                
            Console.Log( 'Session #' + IntToStr( _Session.ID ) + ' [' + _Session.IP + '] : QUERY "' + Query + '" OK' );

        end else
        begin
            
            if _Args.hasOwnProperty( 'id' ) and ( _Args.typeof( 'id' ) = 'number' ) then
            begin
                
                CmdID    := _Args.get( 'id', 0 );
                
                _Session.SendText( '{ "id": ' + IntToStr( CmdID ) + ', "ok": false, "error": "Bad query packet" }' );
                
            end else
            begin
                
                _Session.SendText( '{ "ok": false, "error": "Bad query packet" }' );
                
            end;
            
        end;
        
    end;

    procedure PAM2_QUERY.OnMessage( Data: AnsiString; Binary: Boolean );
    begin
        inherited;
    end;

    destructor  PAM2_QUERY.Free;
    begin
        inherited;
    end;
