

string encode_call(string method, mixed id, mixed ... params)
{
  mapping request = ([]);

  request->method = method;
  request->id = id;
  request->params = params;

  return (string).JSONObject(request);
}

string encode_response(mixed id, mixed result)
{
  mapping request = ([]);

  request->id = id;
  request->result = result;

  return (string).JSONObject(request);
}

string encode_error(mixed id, mixed error)
{
  mapping request = ([]);

  request->id = id;
  request->error = error;

  return (string).JSONObject(request);
}

string encode_notification(string method, mixed ... params)
{
  mapping request = ([]);

  request->method = method;
  request->id = .Null;
  request->params = params;

  return (string).JSONObject(request);
}

array decode_jsonrpc(string json)
{
  mapping r = .JSONObject(json);

  if(r->error)
  {
    // error
    return .Error(r);
  }
  else if(r->result)
  {
    // response
    return .Result(r);
  }
  else if(has_index(r, "id"))
  {
    if(!r->id && zero_type(r->id))
    {
      // notification
      return .Notification(r);
    }
    else
    {
      // request
    return .Request(r);
    }
  }
  else 
  {
    throw(Error.Generic("Invalid JSON-RPC message.\n");
  }
}


class Request
{
  constant type = "request";
}

class Response
{
  constant type = "response";

}

class Error
{
  constant type = "error";

}

class Notification
{
  constant type = "notification";

}
