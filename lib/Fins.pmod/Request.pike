/*
#if defined(SCRIPTRUNNER)
#elseif defined(CAUDIUM)
#elseif defined(ROXEN)
#else
*/

inherit Protocols.HTTP.Server.Request;

void parse_request()
{
  ::parse_request();

  remoteaddr = (my_fd->query_address()/":")[0];
}

public string remoteaddr = "";

//#endif
