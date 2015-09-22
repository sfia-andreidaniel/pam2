unit FileUtils;

interface

function ReadTextFileToString( fname: AnsiString ): AnsiString;

implementation

function ReadTextFileToString( fname: AnsiString ): AnsiString;
var f: Text;
	l: AnsiString;
begin

	result := '';

	assign( f, fname );
	{$I-}
	reset(f);
	{$I+}
	if ( IOResult <> 0 ) then
		exit;

	while not EOF( f ) do
	begin

		readln( f, l );
		result := result + l + #10#13;

	end;

	{$I-}
	close(f);
	{$I+}

end;

end.