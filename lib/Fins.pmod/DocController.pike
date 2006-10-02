inherit .FinsController;
import Tools.Logging;
Fins.Template.Template __layout;

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

object __get_layout(object request)
{
  if(__layout) return __layout;

  mixed e;
  object l;
  array paths = ({
  });

  foreach(request->controller_path/"/";; string p)
  {
    if(!sizeof(p)) continue;
      
    if(sizeof(paths))
      paths += ({ paths[-1] + "/" + p });
    else paths += ({"/layouts/" + p });
  }

  paths = reverse(paths);

  paths +=({ "/layouts/application" });

  foreach(paths;; string p)
  {
    e = catch(l = view->low_get_template(view->default_template, p, 0, 1));
    if(!e)
      break;
  }

  return l;
}

private class DocRunner(mixed req)
{
  inherit .Helpers.Runner;

  static mixed `()(Fins.Request request, Fins.Response response, mixed ... args) 
  {
    run(request, response, @args);
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
    object layout = __get_layout(request);
    Fins.Template.View lview;

    mixed e = catch(lview = view->get_view(request->not_args));
    if(e) Log.exception("An error occurred while loading the template " + request->not_args + "\n", e);
    if(layout && lview)
      lview->set_layout(layout);
    req(request, response, lview, args);    
    if(lview)
      response->set_view(lview);

    return;

  }
}
