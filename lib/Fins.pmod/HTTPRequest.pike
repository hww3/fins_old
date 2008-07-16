inherit Fins.Request;
inherit Protocols.HTTP.Server.Request;

string referrer = "";
constant low_protocol = "HTTP";

void parse_post()
{
  ::parse_post();

  if(variables["_lang"])
  {
    set_lang(variables["_lang"]);
    m_delete(variables, "_lang");
  }
}

void parse_request()
{
  ::parse_request();

  remoteaddr = ((my_fd->query_address()||"")/":")[0];
  string n_not_query = Protocols.HTTP.Server.http_decode_string(not_query);
  if(n_not_query != not_query)
  catch{
    n_not_query = utf8_to_string(n_not_query);
  };
  
  not_query = n_not_query;

  not_query = replace(not_query, "+", " ");
  referrer = request_headers["referer"];
}

//!
string remoteaddr = "";

void flatten_headers()
{  
  ::flatten_headers();

  if(request_headers->pragma)
    pragma |= (multiset)(request_headers->pragma/",");
}

//! an X-Forwarded-For aware method of getting the original client address. 
//! note that X-F-F headers are notoriously easy to forge, so don't rely
//! on this value to be accurate if you know there to be proxies present.
string get_client_addr()
{
  string f = request_headers["x-forwarded-for"];
  if(!f) return (remoteaddr/" ")[0];
  else return String.trim_whites((f/",")[0]);
}
