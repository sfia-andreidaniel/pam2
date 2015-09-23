
type TPam2ServiceList = Array of TPam2Service;

{ mapping of table service_options }
type TPam2ServiceOptionBinding = record
	    option_value: AnsiString;
	    default_value: AnsiString;
end;

type TPam2GroupList = Array of TPam2Group;
type TPam2UserList  = Array of TPam2User;

{ HOST + GROUP + SERVICE permission }
type TPam2HSGPermission  = record
	
	host: TPam2Host;
	service: TPam2Service;
	group: TPam2Group;

	allow: boolean;
end;

type TPam2HSGPermission_List = Array of TPam2HSGPermission;


{ USER + GROUP binding }
type TPam2UGBinding = record

	user: TPam2User;
	group: TPam2Group;

end;

type TPam2UGBinding_List = Array of TPam2UGBinding;

{ HOST + SERVICE + USER permission }
type TPam2HSUPermission = record
	host: TPam2Host;
	service: TPam2Service;
	user: TPam2User;
	allow: boolean;
end;

type TPam2HSUPermission_List = Array of TPam2HSUPermission;

{ SERVICE + OPTION binding }
type TPam2ServiceOption = record
	service: TPam2Service;
	name: AnsiString;
	value: AnsiString;
end;

type TPam2ServiceOption_List = Array of TPam2ServiceOption;

{ SERVICE + HOST + OPTION binding }
type TPam2ServiceHostOption = record
	service: TPam2Service;
	host: TPam2Host;
	name: AnsiString;
	value: AnsiString;
end;

type TPam2ServiceHostOption_List = Array of TPam2ServiceHostOption;