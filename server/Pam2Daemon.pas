{$mode delphi}
unit Pam2Daemon;

interface uses
    {$ifdef unix}cthreads, {$endif}
    IdContext,
    WebSocketDaemon,
    WebSocketSession,
    Pam2Session,
    Pam2Manager;
    
type
    
    TPam2Daemon = Class( TWebSocketDaemon )
        
        function    SessionFactory( AContext: TIdContext ): TWebSocketSession; override;
        
    End;
    
implementation uses IdGlobal, IdCustomTCPServer;

function TPam2Daemon.SessionFactory( AContext: TIdContext ): TWebSocketSession;
begin
    result := TPam2Session.Create( AContext, Protocol, Origins );
end;

end.