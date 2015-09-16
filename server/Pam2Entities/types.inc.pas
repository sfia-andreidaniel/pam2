type TServiceUserPassword = record

		service_id: integer;
		password: AnsiString;
		encType: byte; // CONSTANT ENCTYPE_*

end;

type TServiceHostGroupBinding = record
		service_id: integer;
		group_id: integer;
		allow: boolean;
end;

type TServiceHostUserBinding = record
		service_id: integer;
		user_id: integer;
		allow: boolean;
end;

type TServiceHostOptionsBinding = record
		service_id: integer;
		option_name: AnsiString;
		option_value: AnsiString;
end;

type TServiceHostUserOptionBinding = record
		service_id: integer;
		user_id: integer;
		option_name: AnsiString;
		option_value: AnsiString;
end;

type TServiceGroupOptionBinding = record
		service_id: integer;
		group_id: integer;
		option_name: AnsiString;
		option_value: AnsiString;
end;

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
