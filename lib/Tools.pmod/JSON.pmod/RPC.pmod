
//!
string encode_call(string method, mixed id, mixed ... params)
{
  mapping request = ([]);

  request->method = method;
  request->id = id;
  request->params = params;

  return (string).JSONObject(request);
}

//!
string encode_response(mixed id, void|mixed result)
{
  mapping request = ([]);

  request->id = id;
  request->result = result;

  return (string).JSONObject(request);
}

//!
string encode_error(mixed id, mixed error)
{
  mapping request = ([]);

  request->id = id;
  request->error = (["message": error]);

  return (string).JSONObject(request);
}

//!
string encode_notification(string method, mixed ... params)
{
  mapping request = ([]);

  request->method = method;
  request->id = .Null;
  request->params = params;

  return (string).JSONObject(request);
}

//!
Message decode_jsonrpc(string json)
{
  mapping r = (mapping).JSONObject(json);

  if(r->error)
  {
    // error
    return eError(r);
  }
  else if(r->result)
  {
    // response
    return Response(r);
  }
  else if(has_index(r, "id"))
  {
    if(!r->id && zero_type(r->id))
    {
      // notification
      return Notification(r);
    }
    else
    {
      // request
    return Request(r);
    }
  }
  else 
  {
    throw(Error.Generic("Invalid JSON-RPC message.\n"));
  }
}

//!
class Message(mapping json)
{
  constant type = "";
}

//!
class Request
{
  inherit Message;
  constant type = "request";
}

//!
class Response
{
  inherit Message;
  constant type = "response";
}

//!
class eError
{
  inherit Message;
  constant type = "error";
}

//!
class Notification
{
  inherit Message;
  constant type = "notification";
}
