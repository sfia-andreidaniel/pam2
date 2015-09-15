unit Pam2Entities;

interface uses

	{ if unix is defined, the cthread unit should be FIRST used }
	{$ifdef unix}cthreads, {$endif}

	{ loggin function ( Console.* functions ) }
	Logger,

	{ standard free pascal classes }
	classes,

	{ unit that handles strings routines }
	StringsLib,

	{ system utilities unit }
	sysutils,

	{ JSON utilities unit }
	JSON,

	{database support}
    sqldb, pqconnection, { IBConnnection, ODBCConn, }
    mysql50conn, mysql55conn   
    {end of database support}

; { end of units used by the interface }


{ PUBLIC CONSTANTS }
const ENTITY_USER           = 0;
      ENTITY_HOST           = 1;
      ENTITY_GROUP          = 2;
      ENTITY_SERVICE        = 3;
      ENTITY_SERVICE_OPTION = 4;
      ENTITY_EMAIL          = 5;
      ENTITY_REAL_NAME      = 6;



{ FORWARD DECLARATIONS. This unit implements these classes: }

{ class that handles a user }
type TPam2User             = class;

{ class that handles groups }
type TPam2Group            = class;

{ class that handles hosts in a cloud }
type TPam2Host             = class;

{ class that handles services types that a host in a cloud can serve }
type TPam2Service          = class;

{ class that handles PAM2DB query execution, depending on user context that is invoking the query }
type TPam2ExecutionContext = class;

{ root in-memory database class that holds all the Pam2Entities classes }
type TPam2DB               = class;

{ command parser }
type TQueryParser          = class;

{ COMMON TYPES, used by the unit                     }
{$I ./Pam2Entities/types.inc.pas                     }

{ CLASS DECLARATIONS }

{$I ./Pam2Entities/Pam2User_decl.inc.pas             }
{$I ./Pam2Entities/Pam2Group_decl.inc.pas            }
{$I ./Pam2Entities/Pam2Service_decl.inc.pas          }
{$I ./Pam2Entities/Pam2Host_decl.inc.pas             }
{$I ./Pam2Entities/Pam2ExecutionContext_decl.inc.pas }
{$I ./Pam2Entities/Pam2DB_decl.inc.pas               }
{$I ./Pam2Entities/QueryParser_decl.inc.pas          }

implementation uses md5;

{ misc declaration types                             }
{$I ./Pam2Entities/types_impl.inc.pas                }

{ misc implementation functions                      }
{$I ./Pam2Entities/misc_impl.inc.pas                 }

{ implementation methods of TPam2User class          }
{$I ./Pam2Entities/Pam2User_impl.inc.pas             }

{ implementation methods of TPam2Group class         }
{$I ./Pam2Entities/Pam2Group_impl.inc.pas            }

{ implementation methods of TPam2Host class          }
{$I ./Pam2Entities/Pam2Host_impl.inc.pas             }

{ implementation methods of TPam2Service class       }
{$I ./Pam2Entities/Pam2Service_impl.inc.pas          }

{ implementation methods of TPam2ExecutionContext class }
{$I ./Pam2Entities/Pam2ExecutionContext_impl.inc.pas }

{ implementation methods of TPam2DB class            }
{$I ./Pam2Entities/Pam2DB_impl.inc.pas               }

{ implementation methods of TQueryParser class       }
{$I ./Pam2Entities/QueryParser_impl.inc.pas          }

initialization

{ some assertions made by the unit                   }	
{$I ./Pam2Entities/asserts_init.inc.pas              }

end.