
    {DECLARATION OF THE "QUERY" COMMAND OF THE PAM2 DAEMON}
    
    PAM2_QUERY = class( TPam2Command )
        
        constructor Create( _Session: TPam2Session; _Args: TJSON ); override;

        procedure   OnMessage( Data: AnsiString; Binary: Boolean ); override;

        destructor  Free; override;
        
        
    End;
    
    {IMPLEMENTATION OF THIS COMMAND IS FOUND IN "PAM2_Query_Impl.inc" FILE}