// do some small tests
if ( normalize(' FOO ', ENTITY_USER ) = '' ) then
begin
	raise Exception.Create('Assert: normalize(" FOO ", ENTITY_USER) returns empty');
end;

if ( normalize(' FOO ', ENTITY_GROUP ) = '' ) then
begin
	raise Exception.Create('Assert: normalize(" FOO ", ENTITY_GROUP ) returns empty');
end;

if ( normalize(' FOO ', ENTITY_SERVICE ) = '' ) then
begin
	raise Exception.Create('Assert: normalize(" FOO ", ENTITY_SERVICE ) returns empty');
end;

if ( normalize( ' test.DOT@foo.bar ', ENTITY_EMAIL ) = '' ) then
begin
	raise Exception.Create('Assert: normalize(" test.dot@foo.bar ", ENTITY_EMAIL ) returns empty' );
end;

if ( normalize( 'John Doe', ENTITY_REAL_NAME ) = '' ) then
begin
	raise Exception.Create('Assert: normalize("John Doe", ENTITY_REAL_NAME ) returns empty' );
end;