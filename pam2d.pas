program pam2;

uses {$ifdef unix}cthreads, cmem, {$endif}
     Logger,
     Classes,
     IdBaseComponent,
     IdCustomTCPServer,
     IdContext,
     SysUtils,
     custApp,
     IdGlobal,


     Pam2Daemon,
     Pam2Manager;

var D: TPam2Daemon;

begin

    if not IPam2ManagerLoaded then
    begin
        
        Console.error( 'pam2d will now quit' );
        
        Halt( 78 ); // configuration error
        
    end else
    begin

        try 

            D := TPam2Daemon.Create(
                IPam2Manager.ServerListenInterface,
                IPam2Manager.ServerPort,
                IPam2Manager.ServerProtocolName,
                IPam2Manager.AllowedOriginsList
            );
        
            try

                D.Run;
        
            finally
        
                D.Free;
    
            end;
        
        except
            
            On E: Exception Do
            Begin       
                
                Console.Error( 'Internal software error: ' + E.Message );
                Halt( 70 ); // Internal software error
                
            End;
        
        End;
            

    end;
    

end.