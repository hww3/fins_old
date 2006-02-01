inherit .FinsController;

//!
//!  Impliments a controller which automatically provides a view based on
//!  the position of the request within the tree
//!
//!  it is the same as the standard controller, except that event functions
//!  receive an additional argument:
//!
//!  void event(Fins.Request request, Fins.Response response,
//!                  Fins.Template.View view, mixed ... args);
//!

static mixed `[](mixed a)
{
  mixed v; 
  if(v = ::`[](a, 2))
  {
    if(objectp(v)) return v;
    else if(functionp(v))
      return DocRunner(v);
  }
  else 
  {
    return UNDEFINED;
  }
}

private class DocRunner(mixed req)
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
    Fins.Template.View view = view->get_view(request->not_args);
    req(request, response, view, args);    
    response->set_view(view);

    return;

  }
}
