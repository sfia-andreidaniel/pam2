type TQueryParser = Class

	protected 
		args: TStrArray;
		currentArg: integer;

		function getCurrentArgumentIndex(): Integer;
		function getNextArgumentIndex(): Integer;

	public

		count: integer;

		property  argsList: TStrArray read args;

		property  currentArgumentIndex: Integer read getCurrentArgumentIndex;
		property  nextArgumentIndex   : Integer read getNextArgumentIndex;

		constructor Create( query: AnsiString );

		function getArg( index: integer ): AnsiString;
		function nextArg(): AnsiString;
		function toString(): AnsiString;

		function readEntities( entityType: Integer; allowWildcard: Boolean; pam2Database: TPam2DB; const stopWords: TStrArray; var isWildCard: boolean ): TStrArray;

		procedure reset();

		destructor Free();

	end;
