{$mode objfpc}
unit JSON;
interface uses classes, sysutils, fpjson, jsonparser, StringsLib;

type 
    TJSON = Class
        
        private 
            _data: TJSONData;
            _freeData: Boolean;

            function getLength(): Longint;
            function getKeys(): TStrArray;
        
        public
        
            Constructor Create( data: TJSONData; const FreeData: Boolean = true );
            
            function isPrimitive(): Boolean;
            
            function getAsString( default: AnsiString ): AnsiString;
            function getAsInt   ( default: Int64      ): Int64;
            function getAsFloat ( default: Double     ): Double;
            function getAsBoolean(default: Boolean    ): Boolean;
        
            function typeof(): AnsiString;
            function typeof( propertyName: AnsiString ): AnsiString;
            function typeof( index: LongInt ): AnsiString;
            
            function hasOwnProperty ( propertyName: AnsiString ): Boolean;
            function hasOwnProperty ( index: Longint ): Boolean;
            
            function get( propertyName: AnsiString ): TJSON;
            function get( index: Longint ): TJSON;
            
            function get( propertyName: AnsiString; Default: Int64 ): Int64;
            function get( propertyName: AnsiString; Default: Double ): Double;
            function get( propertyName: AnsiString; Default: AnsiString): AnsiString;
            function get( propertyName: AnsiString; Default: Boolean): Boolean;
            function get( propertyName: AnsiString ): TStrArray;

            function get( index: LongInt; Default: Int64 ): Int64;
            function get( index: LongInt; Default: Double ): Double;
            function get( index: LongInt; Default: AnsiString): AnsiString;
            function get( index: LongInt; Default: Boolean): Boolean;

            property count: LongInt read getLength;
            property keys: TStrArray read getKeys;
            
            Destructor Free();

    end;
    
    function json_decode( data: AnsiString ): TJSON;
    function json_encode( data: AnsiString ): AnsiString;
    function json_encode( data: Boolean ): AnsiString;
    function json_encode( data: Integer ): AnsiString;
    function json_encode( data: Double ): AnsiString;
    function json_encode( data: TStrArray ): AnsiString;

    function json_encode_object( data: TStrArray; const encodeValues: boolean = TRUE ): AnsiString;

implementation


    function TJSON.get( index: LongInt; Default: Boolean ): Boolean;
    var TMP: TJSON;
    begin
        TMP := get( index );
        if ( TMP = NIL ) then
            result := Default
        else begin
            result := TMP.getAsBoolean( Default );
            TMP.Free;
        end;
    end;

    function TJSON.get( index: LongInt; Default: AnsiString ): AnsiString;
    var TMP: TJSON;
    begin
        TMP := get( index );
        if ( TMP = NIL ) then
            result := Default
        else begin
            result := TMP.getAsString( Default );
            TMP.Free;
        end;
    end;

    function TJSON.get( index: LongInt; Default: Int64 ): Int64;
    var TMP: TJSON;
    begin
        TMP := get( index );
        if ( TMP = NIL ) then
            result := Default
        else begin
            result := TMP.getAsInt( Default );
            TMP.Free;
        end;
    end;

    function TJSON.get( index: LongInt; Default: Double ): Double;
    var TMP: TJSON;
    begin
        TMP := get( index );
        if ( TMP = NIL ) then
            result := Default
        else begin
            result := TMP.getAsFloat( Default );
            TMP.Free;
        end;
    end;


    function TJSON.get( propertyName: AnsiString; Default: Boolean ): Boolean;
    var TMP: TJSON;
    begin
        TMP := get( propertyName );
        if ( TMP = NIL ) then
            result := Default
        else begin
            result := TMP.getAsBoolean( Default );
            TMP.Free;
        end;
    end;

    function TJSON.get( propertyName: AnsiString; Default: AnsiString ): AnsiString;
    var TMP: TJSON;
    begin
        TMP := get( propertyName );
        if ( TMP = NIL ) then
            result := Default
        else begin
            result := TMP.getAsString( Default );
            TMP.Free;
        end;
    end;

    function TJSON.get( propertyName: AnsiString; Default: Int64 ): Int64;
    var TMP: TJSON;
    begin
        TMP := get( propertyName );
        if ( TMP = NIL ) then
            result := Default
        else begin
            result := TMP.getAsInt( Default );
            TMP.Free;
        end;
    end;

    function TJSON.get( propertyName: AnsiString; Default: Double ): Double;
    var TMP: TJSON;
    begin
        TMP := get( propertyName );
        if ( TMP = NIL ) then
            result := Default
        else begin
            result := TMP.getAsFloat( Default );
            TMP.Free;
        end;
    end;

    function TJSON.get( index: Longint ): TJSON;
    begin
        if ( _data.jsonType = jtArray )  and ( index >= 0 ) and (index < _data.Count) then
        begin
            result := TJSON.Create( _data.Items[index], FALSE );
        end else
        begin
            result := NIL;
        end;
    end;

    function TJSON.get( propertyName: AnsiString ): TJSON;
    var i: Integer;
        len: Integer;
    begin

        result := NIL;
        
        if _data.jsontype <> jtObject then
        begin
            exit;
        end;
        
        len := _data.Count;
        
        for i := 0 to len - 1 do
        begin
            
            if TJSONObject(_data).Names[ i ] = propertyName then
            begin
                result := TJSON.Create( _data.Items[ i ], FALSE );
                exit;
            end;
            
        end;

    end;

    function TJSON.get( propertyName: AnsiString ): TStrArray;
    var i: Integer;
        Len: Integer;
    begin
        Len := count;
        setLength( result, Len );
        for i := 0 to Len do
        begin
            result[ i - 1 ] := get( i, '' );
        end;
    end;

    function TJSON.hasOwnProperty( index: LongInt ): Boolean;
    begin
        
        if _data.jsonType = jtArray then
        begin
            result := ( index >= 0 ) and (index < _data.Count);
        end else
        begin
            result := false;
        end;
        
    end;

    function TJSON.hasOwnProperty( propertyName: AnsiString ): Boolean;
    var i: Integer;
        len: Integer;
    begin
        
        result := false;
        
        if _data.jsontype <> jtObject then
        begin
            exit;
        end;
        
        len := _data.Count;
        
        for i := 0 to len - 1 do
        begin
            
            if TJSONObject(_data).Names[ i ] = propertyName then
            begin
                result := true;
                exit;
            end;
            
        end;
        
    end;

    destructor TJSON.Free();
    begin
        
        if ( _FreeData ) then
        FreeAndNil( _data );
        
    end;

    function TJSON.typeof(): AnsiString;
    begin
        
        case _data.jsontype of
            jtNull: result := 'null';
            jtBoolean: result := 'boolean';
            jtNumber: result := 'number';
            jtString: result := 'string';
            jtObject: result := 'object';
            jtArray: result := 'array';
        end;
        
    end;
    
    function TJSON.typeOf( propertyName: AnsiString ): AnsiString;
    var TMP: TJSON;
    begin
        
        TMP := get( propertyName );
        
        if TMP = NIL then
            result := 'undefined'
        else begin
            result := TMP.typeOf();
            TMP.Free;
        end;
        
    end;

    function TJSON.typeOf( index: LongInt ): AnsiString;
    var TMP: TJSON;
    begin
        
        TMP := get( index );
        
        if TMP = NIL then
            result := 'undefined'
        else begin
            result := TMP.typeOf();
            TMP.Free;
        end;
        
    end;

    function TJSON.isPrimitive(): Boolean;
    begin
        result := ( _data.jsontype = jtNull ) or
                  ( _data.jsontype = jtBoolean ) or
                  ( _data.jsontype = jtNumber ) or
                  ( _data.jsontype = jtString );
    end;
    
    function TJSON.getAsFloat( default: Double ): Double;
    begin
        if _data.jsontype = jtNumber then
        begin
            if TJSONNumber( _data ).numberType = ntFloat then
            begin
                result := _data.asFloat;
            end else
            begin
                result := _data.asInt64;
            end;
            
        end else
        begin
            result := default;
        end;
    end;
    
    function TJSON.getAsString( default: AnsiString ): AnsiString;
    begin
        
        if _data.jsonType = jtString then
        begin
            result := _data.asString;
        end else
        begin
            result := default;
        end;
        
    end;
    
    function TJSON.getAsBoolean( default: Boolean ): Boolean;
    begin
        
        if _data.jsonType = jtBoolean then
        begin
            result := _data.asBoolean;
        end else
        begin
            result := default;
        end;
        
    end;

    function TJSON.getAsInt( default: Int64 ): Int64;
    begin
        if _data.jsontype = jtNumber then
        begin
            if TJSONNumber( _data ).numberType = ntFloat then
            begin
                result := round( _data.asFloat );
            end else
            begin
                result := _data.asInt64;
            end;
            
        end else
        begin
            result := default;
        end;
    end;

    function TJSON.getLength(): Longint;
    begin
        result := _data.count;
    end;

    function TJSON.getKeys(): TStrArray;
    var len: Integer;
        i: Integer;
    begin
        len := _data.Count;
        setLength( result, len );
        
        for i := 0 to len - 1 do
        begin
            result[i] := TJSONObject(_data).Names[ i ];
        end;

    end;

    Constructor TJSON.Create( data: TJSONData; const FreeData: Boolean = true );
    begin
        _Data := Data;
        _freeData := FreeData;
    End;

    function json_decode( data: AnsiString ): TJSON;
    var P: TJSONParser;
        J: TJSONData;
    begin
        
        result := NIL;
        
        try
            
            try
                
                P := TJSONParser.Create( data );
                J := TJSONData( P.Parse );


                FreeAndNil( P );
                
                if Assigned( J ) then
                    result := TJSON.Create( J )
                
            except
            
                On E: Exception Do Begin
                    writeln( 'Error decoding json: ', E.Message );
                End;
            
            end;
            
        finally
        
            if Assigned(P) then FreeAndNil( P );
            
            if Assigned(J) and ( result = NIL ) then FreeAndNil( J );
        
        end;
        
    end;
    
    function json_encode( data: AnsiString ): AnsiString;
    var i: Longint;
        len: LongInt;
    begin
    
        Len := Length( data );
        
        if Len = 0 then
            result := '""'
        else begin
            
            result := '"';
            
            for i := 1 to len do
            begin
                
                case data[i] of
                    #13: result := result + '\r';
                    #10: result := result + '\n';
                    #9 : result := result + '\t';
                    '\': result := result + '\\';
                    #0 : result := result + '';
                    '"': result := result + '\"'
                    else
                    begin
                        if ( ord(data[i]) >= 32 ) then
                        begin
                            result := result + data[i];
                        end;
                    end;
                end;
                
            end;
            
            result := result + '"';
            
        end;
    
    end;

    function json_encode( data: Boolean ): AnsiString;
    begin
        if data = TRUE then
            result := 'true'
        else
            result := 'false';
    end;

    function json_encode( data: Integer ): AnsiString;
    begin
        result := IntToStr( data );
    end;

    function json_encode( data: Double ): AnsiString;
    begin
        result := FloatToStrF( data, ffGeneral, 15, 0 );
    end;
    
    function json_encode( data: TStrArray ): AnsiString;
    var i: Integer;
        Len: Integer;
    begin
        result := '[';
        Len := Length( data );
        
        for i := 0 to Len - 1 do
        begin
            result := result + json_encode( data[i] );
            
            if ( i < Len - 1 ) then
                result := result + ',';
        
        end;
        result := result + ']';
    end;

    function json_encode_object( data: TStrArray; const encodeValues: boolean = TRUE ): AnsiString;
    var len: integer;
        i: integer;
    begin
        len := length(data);
        
        if (len mod 2) <> 0 then
        begin
            raise Exception.Create('json_encode_options: The length of the source must be even!');
        end;

        i := 0;

        result := '{';

        while ( i < len - 1 ) do
        begin

            result := result + json_encode( data[i] ) + ':';

            if ( encodeValues ) then
                result := result + json_encode( data[i+1] )
            else
                result := result + data[i+1];

            if ( i < len - 2 ) then
                result := result + ',';

            i := i + 2;

        end;

        result := result + '}';

    end;

end.