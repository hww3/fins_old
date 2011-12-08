inherit .FinsController;

//!
//! Impliments a controller which provides access to
//! the functions in the class via XMLRPC.
//!
//! all public methods are made available via XMLRPC
//! at the mountpoint for the controller. these methods
//! will receive the Request object as the first argument,
//! any other arguments will be passed from the XMLRPC request
//! to the called method.

 public object index = XMLRPCRunner(this, ::`[]);

static mixed `[](mixed a, int|void a2)
{
  if(objectp(::`[](a, a2||2)))
  {
    return ::`[](a, a2||2);
  }
  else if(a == "index")
  {
    return XMLRPCRunner(this, a);
  }

  else return UNDEFINED;
}

private class XMLRPCRunner(object obj, function indexer)
{
  inherit .Helpers.Runner;

  static mixed `()(Fins.Request request, Fins.Response response, mixed ... args) 
  {
    run(request, response, @args);
    return 0;
  }

  string get_name()
  {
    return "";
  }

  object get_controller()
  {
    return obj;
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
        int off = search(request->raw, "\r\n\r\n");

        if(off<=0) error("invalid request format.\n");

        object X;

      //  werror("XMLRPC: %O\n", request->raw[(off+4) ..]);

        if(catch(X=Protocols.XMLRPC.decode_call(request->raw[(off+4) ..])))
        {
                error("Error decoding the XMLRPC Call. Are you not speaking XMLRPC?\n");
        }
        mixed resp;

        mixed err = catch {
          mixed z = indexer(X->method_name, 2);
//werror("XMLRPC: %O=%O\n", X, z);
          if(!functionp(z))
            throw(Error.Generic("Invalid method request: not a function.\n"));
          resp = z(request, @X->params);
        };

  if(err)
  {
    response->set_data(Protocols.XMLRPC.encode_response_fault(1, err[0]));
  }
  else
  {
    response->set_data(Protocols.XMLRPC.encode_response(({resp})));
  }
   response->set_type("text/xml");

   return;

  }

}
