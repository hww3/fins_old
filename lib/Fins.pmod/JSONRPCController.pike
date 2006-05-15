inherit .FinsController;

//! makes methods in this object available via JSONRPC.
//! all methods receive the request object as their first
//! argument. Any following arguments will be provided as 
//! subsequent arguments.

public object index = JSONRPCRunner(this, ::`[]);

static mixed `[](mixed a)
{
  if(objectp(::`[](a, 2)))
  {
    return ::`[](a, 2);
  }
  else if(a == "index")
  {
    return JSONRPCRunner(this, a);
  }

  else return UNDEFINED;
}


private class JSONRPCRunner(object obj, function indexer)
{
  inherit .Helpers.Runner;

  static mixed `()(Fins.Request request, Fins.Response response, mixed ... args) 
  {
    run(request, response, args);
    return 0;
  }

  static int(0..1) _is_type(string bt)
  {
    if(bt=="function")
      return 1;
    else
      return 0;
  }

  void run(Fins.Request request, Fins.Response response, mixed ... args)
  {
        mapping m;
        int off = search(request->raw, "\r\n\r\n");

        if(off<=0) error("invalid request format.\n");

        object X;
        if(catch(X=Tools.JSON.RPC.decode_jsonrpc(request->raw[(off+4) ..])))
        {
                error("Error decoding the JSONRPC Call. Are you not speaking JSONRPC?\n");
        }
        mixed resp;

        if(object_program(X) != Tools.JSON.RPC.Request)
        {
                error("We received something other than a JSONRPC request. We're sort of limited that way.\n");
        }

        mixed err = catch {
          mixed z = indexer(X->json->method, 2);
          if(!functionp(z))
            throw(Error.Generic("Invalid method request: not a function.\n"));
          resp = z(request, @X->json->params);
        };

  if(err)
  {
    response->set_data(Tools.JSON.RPC.encode_error(X->json->id, err[0]));
  }
  else
  {
    response->set_data(Tools.JSON.RPC.encode_response(resp));
  }
   response->set_type("text/json");

   return;

  }

}
