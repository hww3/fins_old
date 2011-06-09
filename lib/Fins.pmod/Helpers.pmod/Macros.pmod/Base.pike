//! retrieves a value from a mapping given a dot separated variable name. 
//! 
//! @returns 
//!  the variable (or zero if not present)
mixed get_var_value(string varname, mixed var)
{
  mixed myvar = var;

//  TODO: this is an incompatible change where we assume that values 
//  that do not start with $ are constants, otherwise we look them up.
  if(varname[0] != '$') return varname;
  else varname = varname[1..];

  // we can employ the "fly by the seat of the pants" method, because 
  // if we fail to get a value somewhere along the way, we want an error
  // to be thrown.
//werror("obj: %O->%O\n",varname, myvar);
  foreach(varname/".";; string vn)
  {
    myvar = myvar[vn];
  }

  return myvar;
}

string describe_array(object o, string key, object a)
{
  array x = ({});
  foreach(a;; object v)
  {
    if(objectp(v))
      x += ({ describe_object(0, key, v) });
    else x+= ({ (string)v });
  }

  return x * ", ";
}

string describe_object(object m, string key, object o)
{
  string rv;
  if(o->master_object && o->master_object->alternate_key)
  {
    object model;
    string link;
    model = o->master_object->context->app->model;
    link = get_view_url(model, o);
    if(link) link = " <a href=\"" + link + "\">view</a>";
    else link = "";
    return (string)o->describe()
     + link;
  }
  else if(o->_cast)
    return  (string)o;
  else if(m && (rv = m->describe_value(key, o)))
    return rv;
  else return sprintf("%O", o);
}

string get_view_url(object model, object o)
{
  object controller = model->repository->get_scaffold_controller(o->master_object);  
  if(!controller)
    return 0;

  string url;

  url = model->app->url_for_action(controller->display, 0, (["id": o[o->master_object->primary_key->name]]));  

  return url;
}
