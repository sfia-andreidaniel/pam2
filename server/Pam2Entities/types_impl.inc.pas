// Implementation types of Pam2Entities unit

const ENCTYPE_PLAIN         = 0;
      ENCTYPE_MD5           = 1;
      ENCTYPE_CRYPT         = 2;
      ENCTYPE_PASSWORD      = 3;

      FMT_USER              = '0123456789abcdefghijklmnopqrstuvwxyz_';
      FMT_USER_BEGIN        = 'abcdefghijklmnopqrstuvwxyz';

      FMT_GROUP             = FMT_USER;
      FMT_GROUP_BEGIN       = FMT_USER_BEGIN;

      FMT_SERVICE           = FMT_USER;
      FMT_SERVICE_BEGIN     = FMT_USER_BEGIN;

      FMT_HOST              = '0123456789abcdefghijklmnopqrstuvwxyz_-.';
      FMT_HOST_BEGIN        = '0123456789abcdefghijklmnopqrstuvwxyz';

      FMT_SERVICEOPTION= FMT_USER;
      FMT_SERVICEOPTION_BEGIN = FMT_USER_BEGIN + '_';

      FMT_EMAIL             = '0123456789abcdefghijklmnopqrstuvwxyz_@.';
      FMT_EMAIL_BEGIN       = 'abcdefghijklmnopqrstuvwxyz_';

      FMT_REALNAME          = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789&. @';

      MAXLEN_USER           = 16;
      MAXLEN_GROUP          = 30;
      MAXLEN_REALNAME       = 64;
      MAXLEN_EMAIL          = 96;
      MAXLEN_HOST           = 64;
      MAXLEN_SERVICE        = 16;
      MAXLEN_SERVICEOPTION  = 45;
      MINLEN_PAM2_PASSWORD  = 6;

      OP_ADD                = 1;
      OP_REMOVE             = 0;
      OP_UNSET              = 2;
      
