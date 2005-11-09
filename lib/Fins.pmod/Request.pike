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
  string n_not_query = Protocols.HTTP.Server.http_decode_string(not_query);
  if(n_not_query != not_query)
  catch{
    n_not_query = utf8_to_string(n_not_query);
  };
  
  not_query = n_not_query;

  not_query = replace(not_query, "+", " ");
}

//!
public string remoteaddr = "";

//#endif
