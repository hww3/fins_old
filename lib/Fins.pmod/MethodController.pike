//! A controller that implements an endpoint with each method type being handled by
//! a particular handler function
//! 
//! @example
//!
//! @code
//!  void method_post(Fins.Request request, Fins.Response response, mixed ... args)
//!  {
//!  }
//! @code

inherit Fins.FinsController;

public void index(Fins.Request request, Fins.Response response, mixed ... args)
{
  string method = request->method;
  if(!method) method = "GET";

werror("have index\n");
  method = lower_case(method);
  mixed fx;
werror("have method: %O\n", method);

  method = "method_" + method;

  if(fx = ::`[](method, 3))
  {
    werror("have " + method);
    if(objectp(fx) || functionp(fx))
    {
       werror("got it!\n");
       fx(request, response, @args);
       return;
    }
  }

  response->not_implemented();
  return;
}

