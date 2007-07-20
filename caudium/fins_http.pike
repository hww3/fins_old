inherit "protocols/http";
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

