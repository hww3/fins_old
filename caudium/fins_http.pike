inherit "protocols/http" : http;
inherit Fins.Request;

constant low_protocol = "HTTP";

static mapping _get_session_by_id(string SessionID)
{
  array x = conf->get_providers("123sessions");

  if(sizeof(x))
  {
    return x[0]->variables_retrieve("session", SessionID);
  }
  else return ([]);
}

function get_session_by_id = _get_session_by_id;


void handle_request()
{  
  // handle the language setting as early as possible.
  if(variables["_lang"])
  {
    set_lang(variables["_lang"]);
    m_delete(variables, "_lang");
  }

  http::handle_request();
}
