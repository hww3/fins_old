//!
//! A controller that impliments CRUD functionality
//! for a given Model segment.
//!

import Fins;
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
  if(request->misc->flash && request->misc->flash->msg)
    rv += "<i>" + request->misc->flash->msg + "</i><p>\n";

  rv += "<a href=\"new\">new " + make_nice(model_object->instance_name) + "</a><p>";
  object items = model->repository->find(model_object, ([]));
  if(!sizeof(items))
  {
    rv += "No " + 
      Tools.Language.Inflect.pluralize(model_object->instance_name) + 
         " found.<p>\n";
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
  object item = model->repository->find_by_id(model_object, (int)request->variables->id);

  string rv = "";

  rv = "<h1>Viewing " + make_nice(model_object->instance_name) + "</h1>\n";
  if(request->misc->flash && request->misc->flash->msg)
    rv += "<i>" + request->misc->flash->msg + "</i><p>\n";
  rv += "<a href=\"update?id=" + request->variables->id + "\">edit " + make_nice(model_object->instance_name) + "</a><p>";

  rv += "<table>\n";

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }

  mapping val = item->get_atomic();

  foreach(model_object->field_order; int key; mixed field)
  {
      rv += "<tr><td><b>" + make_nice(field->name) + "</b>: </td><td> " + describe(field->name, val[field->name]) + "</td></tr>\n"; 
  }
 
  rv += "</table>\n";
  rv += "<form action=\"list\" method=\"post\">";
  rv += "<input name=\"___return\" value=\"Return\" type=\"submit\"> ";
  rv += "</form>";

  response->set_data(rv);
}

public void delete(Request id, Response response, mixed ... args)
{
  if(!id->variables->id)
  {
    response->set_data("error: invalid data.");
    return;	
  }
  response->redirect("dodelete?id=" + id->variables->id);
}

public void dodelete(Request id, Response response, mixed ... args)
{
  if(!id->variables->id)
  {
    response->set_data("error: invalid data.");
    return;	
  }
  
  object item = model->repository->find_by_id(model_object, (int)id->variables->id);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }
  
  item->delete();

  response->flash("msg", make_nice(model_object->instance_name) + " deleted successfully.");
  response->redirect("list");

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
  object item = model->repository->find_by_id(model_object, (int)request->variables->id);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }


  string rv = "";
  rv = "<h1>Editing " + make_nice(model_object->instance_name) + "</h1>\n";
  if(request->misc->flash && request->misc->flash->msg)
    rv += "<i>" + request->misc->flash->msg + "</i><p>\n";
  rv += "<form action=\"doupdate\" method=\"post\">";
  rv += "<table>\n";

  mapping val = item->get_atomic();

  foreach(model_object->field_order; int key; mixed value)
  {	
	string ed = make_value_editor(value->name, val[value->name], item);
    if(ed)
      rv += "<tr><td><b>" + make_nice(value->name) + "</b>: </td><td> " + ed + "</td></tr>\n"; 
  }
 
  rv += "</table>\n";
  rv += "<input name=\"___cancel\" value=\"Cancel\" type=\"submit\">";
  rv += "<input name=\"___save\" value=\"Save\" type=\"submit\"> ";
  rv += "</form>";
  response->set_data(rv);
}

public void doupdate(Fins.Request request, Fins.Response response, mixed ... args)
{
mixed e;

e=catch{
  if(!request->variables->id || !(request->variables->___save || request->variables->___cancel))
  {
	response->set_data("error: invalid data");
	return;
  }

  if(request->variables->___cancel)
  {
	response->flash("msg", "editing canceled");
    response->redirect("list");
    return;	
  }

  object item = model->repository->find_by_id(model_object, (int)request->variables->id);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
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


public void donew(Fins.Request request, Fins.Response response, mixed ... args)
{
mixed e;

e=catch{
  if(!(request->variables->___save || request->variables->___cancel))
  {
	response->set_data("error: invalid data");
	return;
  }

  if(request->variables->___cancel)
  {
	response->flash("msg", "create canceled.");
    response->redirect("list");
    return;	
  }

  object item = model->repository->new(model_object);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }

  
  m_delete(request->variables, "___save");
  
  foreach(request->variables; string key; string value)
  {
	{
		Log.debug("Scaffold: " + key + " in " + model_object->instance_name + " changed.");
		item[key] = value;
	}
  }

  item->save();

  response->redirect("list");

  response->flash("msg", "create successful.");

};
if(e)
  Log.exception("error", e);
}


public void new(Fins.Request request, Fins.Response response, mixed ... args)
{
  string rv = "";
  rv = "<h1>Creating new " + model_object->instance_name + "</h1>\n";
  if(request->misc->flash && request->misc->flash->msg)
    rv += "<i>" + request->misc->flash->msg + "</i><p>\n";
  rv += "<form action=\"donew\" method=\"post\">";
  rv += "<table>\n";

  foreach(model_object->field_order; int key; mixed value)
  {	
//	 if(value->is_shadow) continue;
	  string ed = make_value_editor(value->name);
      if(ed)
        rv += "<tr><td><b>" + make_nice(value->name) + "</b>: </td><td> " + ed + "</td></tr>\n"; 
  }

  rv += "</table>\n";
  rv += "<input name=\"___cancel\" value=\"Cancel\" type=\"submit\">";
  rv += "<input name=\"___save\" value=\"Save\" type=\"submit\">";
  rv += "</form>";
  response->set_data(rv);
}

string make_nice(string v)
{
  return Tools.Language.Inflect.humanize(v);
}

string make_value_editor(string key, void|mixed value, void|object o)
{
  if(model_object->fields[key]->is_shadow)
  {
	if(o)
      return describe(key, value);   
    else return "";
  }
  else if(model_object->primary_key->name == key)
  {
    if(o) return "<input type=\"hidden\" name=\"id\" value=\"" + value + "\">" + value;	
    else return 0;
  }
  else if(model_object->fields[key]->get_editor_string)
	if(o)
      return model_object->fields[key]->get_editor_string(value, o);
	else return model_object->fields[key]->get_editor_string();
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
