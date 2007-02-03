//!
//! A controller that impliments CRUD functionality
//! for a given Model segment.
//!

inherit Fins.FinsController;
import Tools.Logging;
string model_component = 0;
object model_object;

void start()
{
  if(model_component)
  {
    model_object = model->repository->get_object(model_component);
    model->repository->set_scaffold_controller(model_object, this);
  }
}

public void index(Fins.Request request, Fins.Response response, mixed ... args)
{
  response->redirect("list");
}

public void list(Fins.Request request, Fins.Response response, mixed ... args)
{
  string rv = "";

  rv += "<h1>" + Tools.Language.Inflect.pluralize(model_object->instance_name) + "</h1>";

  object items = model->find(model_object, ([]));
  if(!sizeof(items))
  {
    rv += "No " + 
      Tools.Language.Inflect.pluralize(model_object->instance_name) + 
         " found.";
  }
  else
  {
    rv+="<table>";
    foreach(items;; object item)
    {
      rv += "<tr><td><a href=\"display?id=" + item->get_id() + "\">view</a> </td> ";
      rv += " <td> <a href=\"update?id=" + item->get_id() + "\">edit</a> </td><td>";
      rv += " <td> <a href=\"delete?id=" + item->get_id() + "\">delete</a> </td><td>";
      rv += sprintf("%O<br/>\n", item) + "</td></tr>\n";
    }
  }

  rv +="</table>";
  response->set_data(rv);
}

public void display(Fins.Request request, Fins.Response response, mixed ... args)
{
  object item = model->find_by_id(model_object, (int)request->variables->id);

  string rv = "";

  rv = "<h1>Viewing " + model_object->instance_name + "</h1>\n";
  rv += "<table>\n";

  if(!item)
  {
    response->set_data(model_object->instance_name + " not found.");
    return;
  }

  else foreach(item->get_atomic(); string key; mixed value)
  {
      rv += "<tr><td><b>" + make_nice(key) + "</b>: </td><td> " + describe(key, value) + "</td></tr>\n"; 
  }
 
  rv += "</table>\n";

  response->set_data(rv);
}

string describe(string key, mixed value)
{
  string rv = "";

    if(stringp(value) || intp(value))
      rv += value; 
    else if(arrayp(value))
      rv += describe_array(value);
    else if(objectp(value))
      rv += describe_object(value);

  return rv;
}

public void update(Fins.Request request, Fins.Response response, mixed ... args)
{
  object item = model->find_by_id(model_object, (int)request->variables->id);

  if(!item)
  {
    response->set_data(model_object->instance_name + " not found.");
    return;
  }


  string rv = "";
  rv = "<h1>Editing " + model_object->instance_name + "</h1>\n";
  if(request->misc->flash && request->misc->flash->msg)
    rv += "<i>" + request->misc->flash->msg + "</i><p>\n";
  rv += "<form action=\"doupdate\" method=\"post\">";
  rv += "<table>\n";

  foreach(item->get_atomic(); string key; mixed value)
  {	
      rv += "<tr><td><b>" + make_nice(key) + "</b>: </td><td> " + make_value_editor(key, value, item) + "</td></tr>\n"; 
  }
 
  rv += "</table>\n";
  rv += "<input name=\"___save\" value=\"Save\" type=\"submit\">";
  rv == "</form>";
  response->set_data(rv);
}

public void doupdate(Fins.Request request, Fins.Response response, mixed ... args)
{
mixed e;

e=catch{
  if(!request->variables->id || !request->variables->___save)
  {
	response->set_data("error: invalid data");
	return;
  }

  object item = model->find_by_id(model_object, (int)request->variables->id);

  if(!item)
  {
    response->set_data(model_object->instance_name + " not found.");
    return;
  }

  response->redirect("update?id=" + request->variables->id);
  
  m_delete(request->variables, "___save");
  m_delete(request->variables, "id");
  
  mapping v = ([]);

  foreach(request->variables; string key; string value)
  {
	if(has_prefix(key, "__old_value_")) continue;
	
	if(request->variables["__old_value_" + key] != value)
	{
		Log.debug("Scaffold: " + key + " in " + model_object->instance_name + " changed.");
		v[key] = value;
	}
  }

  item->set_atomic(v);

  response->flash("msg", "update successful.");

};
if(e)
  Log.exception("error", e);
}


public void new(Fins.Request request, Fins.Response response, mixed ... args)
{
  response->set_data("new");
}

public void delete(Fins.Request request, Fins.Response response, mixed ... args)
{
  response->set_data("delete");
}


string make_nice(string v)
{
  array x = v/"_";
  foreach(x; int i; string p)
    x[i] = String.capitalize(p);
  return x*" ";
}

string make_value_editor(string key, mixed value, object o)
{
  if(model_object->fields[key]->is_shadow)
  {
    return describe(key, value);   
  }
  else if(model_object->primary_key == o->master_object->fields[key])
  {
    return "<input type=\"hidden\" name=\"id\" value=\"" + value + "\">" + value;	
  }
  else if(model_object->fields[key]->get_editor_string)
    return model_object->fields[key]->get_editor_string(value, o);
//  else if(stringp(value) || intp(value))
//    return "<input type=\"text\" name=\"" + key + "\" value=\"" + value + "\">";
  else 
    return sprintf("%O", value);
}

string describe_array(object a)
{
  array x = ({});
  foreach(a;; object v)
  {
    if(objectp(v))
      x += ({ describe_object(v) });
    else x+= ({ (string)v });
  }

  return x * ", ";
}

string describe_object(object o)
{
  if(o->master_object && o->master_object->alternate_key)
  {
    string link;
    link = get_view_url(o);
    if(link) link = " <a href=\"" + link + "\">view</a>";
    else link = "";
    return (string)o[o->master_object->alternate_key->name]
     + link;
  }

  else return sprintf("%O", o);
}

string get_view_url(object o)
{
  object controller = model->repository->get_scaffold_controller(o->master_object);  
  if(!controller)
    return 0;

  string url = app->get_path_for_controller(controller);

  url = url + "/display/?id=" + o[o->master_object->primary_key->name];  

  return url;
}
