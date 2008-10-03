//!
//! A controller that impliments CRUD functionality
//! for a given Model component.
//!

import Fins;
inherit Fins.FinsController;
import Tools.Logging;

//! this should be the name of your object type and is used to link this
//! controller to the model. For auto-configured models, this is normally
//! a capitalized singular version of your table. For example, if your
//! table is called "users", this would be "User".
string model_component = 0;

object model_object;

//! Contains default contents of the template used for displaying a list of items
//! in this scaffolding. You may override the use of this string by creating 
//! a template file. store the template file in your templates directory under
//! controller/path/list.phtml. For example, if your scaffold controller
//! is mounted at /widgets/, you would store the overriding template file in
//! templates/widgets/list.phtml.
string list_template_string = 
#"<html><head><title>Listing <%$type%></title></head>
  <body>
  <h1><%$type%></h1>
  <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
  <%foreach var=\"$items\" val=\"item\"%> [ 
  <%action_link action=\"display\" id=\"$item._id\"%>view</a> | 
  <%action_link action=\"update\" id=\"$item._id\"%>edit</a> | 
  <%action_link action=\"delete\" id=\"$item._id\"%>delete</a> ] 
  <%describe_object var=\"$item\"%><br/>
  <%end%>
  <p>
  [ <%action_link action=\"new\"%>new</a> ] 
  </body></html>";

//! Contains default contents of the template used for displaying items
//! in this scaffolding. You may override the use of this string by creating 
//! a template file. store the template file in your templates directory under
//! controller/path/display.phtml. For example, if your scaffold controller
//! is mounted at /widgets/, you would store the overriding template file in
//! templates/widgets/display.phtml.
string display_template_string =
#"<html><head><title>Displaying <%$type%></title></head>
  <body>
  <h1>Viewing <%$type%></h1>
  <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
  <%action_link action=\"update\" id=\"$item._id\"%>Edit</a><p>
  <table>
  <%foreach var=\"$item\" ind=\"key\" val=\"value\"%>
  <tr><td><b><%humanize var=\"$key\"%></b></td><td><%describe key=\"$key\" var=\"$value\"%></td></tr>
  <%end %>
  </table>
  <p/>
  <%action_link action=\"list\"%>Return to List</a><p>
  </body></html>";

//! Contains default contents of the template used for editing items
//! in this scaffolding. You may override the use of this string by creating 
//! a template file. store the template file in your templates directory under
//! controller/path/update.phtml. For example, if your scaffold controller
//! is mounted at /widgets/, you would store the overriding template file in
//! templates/widgets/update.phtml.
string update_template_string =
#  "<html><head><title>Editing <%$type%></title>
   <script type=text/javascript>function fire_select(n){
    window.document.forms[0].action = n;
    window.document.forms[0].submit();
    }</script>
  </head>
  <body>
  <h1>Editing <%$type%></h1>
  <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
  <form action=\"<% action_url action=\"doupdate\" %>\" method=\"post\">
  <table>
  <%foreach var=\"$field_order\" ind=\"key\" val=\"value\"%>
  <tr><td><b><%humanize var=\"$value.name\"%></b></td><td><%field_editor item=\"$item\" field=\"$value\" orig=\"$orig\"%></td></tr>
  <%end %>
  </table>
  <input name=\"___cancel\" value=\"Cancel\" type=\"submit\"> 
  <input name=\"___orig_data\" value=\"<%$orig_data%>\" type=\"hidden\">
  <input name=\"___save\" value=\"Save\" type=\"submit\"> 
  <input name=\"___fields\" value=\"<%$fields%>\" type=\"hidden\">
  </form>
  <p/>
  <%action_link action=\"list\"%>Return to List</a><p>
  </body></html>";

//! Contains default contents of the template used for creating items
//! in this scaffolding. You may override the use of this string by creating 
//! a template file. store the template file in your templates directory under
//! controller/path/new.phtml. For example, if your scaffold controller
//! is mounted at /widgets/, you would store the overriding template file in
//! templates/widgets/new.phtml.
string new_template_string =
#  "<html><head><title>Creating <%$type%></title>
   <script type=text/javascript>function fire_select(n){
    window.document.forms[0].action = n;
    window.document.forms[0].submit();
    }</script>
  </head>
  <body>
  <h1>Creating <%$type%></h1>
  <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
  <form action=\"<% action_url action=\"donew\" %>\" method=\"post\">
  <table>
  <%foreach var=\"$field_order\" ind=\"key\" val=\"value\"%>
  <tr><td><b><%humanize var=\"$value.name\"%></b></td><td><%field_editor item=\"$item\" field=\"$value\" orig=\"$orig\"%></td></tr>
  <%end %>
  </table>
  <input name=\"___cancel\" value=\"Cancel\" type=\"submit\"> 
  <input name=\"___save\" value=\"Save\" type=\"submit\"> 
  <input name=\"___fields\" value=\"<%$fields%>\" type=\"hidden\">
  </form>
  <p/>
  <%action_link action=\"list\"%>Return to List</a><p>
  </body></html>";


static object get_view(function f, string x)
{
  object v;
  mixed e = catch(v = view->get_view(app->get_path_for_action(f, 1)));
  if(e)
    v = view->get_string_view(x);

  return v;
}

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
  response->redirect(action_url(list));
}

public void list(Fins.Request request, Fins.Response response, mixed ... args)
{
  object v = get_view(list, list_template_string);

  v->add("type", Tools.Language.Inflect.pluralize(model_object->instance_name));

  object items = model->repository->_find(model_object, ([]));

  if(!sizeof(items))
  {
    response->flash("msg", "No " + 
      Tools.Language.Inflect.pluralize(model_object->instance_name) + 
         " found.<p>\n");
  }
  else
  {
    v->add("items", items);
  }

  response->set_view(v);
}

public void display(Fins.Request request, Fins.Response response, mixed ... args)
{
  object v = get_view(display, display_template_string);

  object item = model->repository->find_by_id(model_object, (int)request->variables->id);
  v->add("type", make_nice(model_object->instance_name));

  if(!item)
  {
    response->flash("msg", make_nice(model_object->instance_name) + " not found.");
  }
  else
  {
//    mapping val = item->get_atomic();
    v->add("item", item);
  }

  response->set_view(v);
}

public void do_pick(Request id, Response response, mixed ... args)
{
  if(!(id->variables->for && id->variables->for_id))
  {
    response->set_data("error: invalid data.");
    return;
  }

  object sc = model->repository->get_scaffold_controller(model->repository->get_object(id->variables["for"]));
  function action;

  if(!(int)id->variables->for_id)
    action = sc->new;
  else
    action = sc->update;

  id->variables->id = id->variables->for_id;
  m_delete(id->variables, "for_id");
  m_delete(id->variables, "for");

  response->redirect(action_url(action, ({}), id->variables));
}

public void pick_one(Request id, Response response, mixed ... args)
{
werror("data: %O\n", id->variables);

  object rv = String.Buffer();

  if(!(id->variables->for && id->variables->for_id && id->variables->selected_field))
  {
    response->set_data("error: invalid data.");
    return;	
  }

  id->variables->old_data = MIME.encode_base64(encode_value(id->variables), 1);
  werror("%O\n", id->variables->old_data);
  rv += "<h1>Choose " + make_nice(model_object->instance_name) + "</h1>\n";
  if(id->misc->flash && id->misc->flash->msg)
    rv += "<i>" + id->misc->flash->msg + "</i><p>\n";
  rv += "<form action=\"" + action_url(do_pick) + "\" method=\"post\">";

  array x = Fins.Model.find_all(model_component);

  foreach(x;; object o)
  {
    rv += "<input type=\"radio\" name=\"selected_id\" value=\"" 
            + o->get_id() + "\"> " + o->describe() + "<br/>";
  }

  rv += "<input type=\"hidden\" name=\"old_data\" value=\"" + id->variables->old_data + "\">";
  rv += "<input type=\"hidden\" name=\"selected_field\" value=\"" + id->variables->selected_field + "\">";
  rv += "<input type=\"hidden\" name=\"for\" value=\"" + id->variables["for"] + "\">";
  rv += "<input type=\"hidden\" name=\"for_id\" value=\"" + id->variables["for_id"] + "\">";
  rv += "<p/><input type=\"submit\" name=\"__return\" value=\"Cancel\"> ";
  rv += "<input type=\"submit\" value=\"Select\"></form>";

  response->set_data((string)rv);
  
}

public void delete(Request id, Response response, mixed ... args)
{
  if(!id->variables->id)
  {
    response->set_data("error: invalid data.");
    return;	
  }
  response->redirect(action_url(dodelete, 0, (["id": id->variables->id])));
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
  response->redirect(action_url(list));

}


string describe(object o, string key, mixed value)
{
  string rv = "";

    if(stringp(value) || intp(value))
      rv += value; 
    else if(arrayp(value))
      rv += describe_array(o, key, value);
    else if(objectp(value))
      rv += describe_object(o, key, value);

  return rv;
}

public void decode_old_values(mapping variables, mapping orig)
{
  if(variables->old_data)
  {
    decode_from_form(decode_value(MIME.decode_base64(variables->old_data)), orig);
    werror("old data: %O\n", orig);
    orig[variables->selected_field] = model->repository->find_by_id(model_object->fields[variables->selected_field]->otherobject, (int)variables->selected_id);
  }

}

public void update(Fins.Request request, Fins.Response response, mixed ... args)
{
  object v = get_view(list, update_template_string);

  v->add("type", Tools.Language.Inflect.pluralize(model_object->instance_name));
  
  mapping orig = ([]);

  object item = model->repository->find_by_id(model_object, (int)request->variables->id);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }

  decode_old_values(request->variables, orig);

  // FIXME: this could go very wrong...
  string orig_data = encode_orig_data(item->get_atomic());

  array fields = ({});

  foreach(model_object->field_order; int key; mixed value)
  {	
    if(model_object->primary_key->name != value->name)
    {
      fields += ({value->name});
    }
  }

  v->add("item", item);
  v->add("orig", orig);
  v->add("field_order", model_object->field_order);
  v->add("orig_data", orig_data);
  v->add("fields", fields*",");

  response->set_view(v);
}

static mixed make_encodable_val(mixed val)
{
  mixed rval;

  if(objectp(val))
  {
    if(rval = val["_id"])
      return rval;
    else if(val->_cast) return (string)val;
    else if(val->format_utc) return val->format_utc();
  }

  else return val;
}

static string encode_orig_data(mapping orig)
{
  mapping val = ([]);

  foreach(val; string k; mixed v)
  {
    val[k] = make_encodable_val(v);
  }

  MIME.encode_base64(encode_value(val), 1); 

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
    response->redirect(action_url(list));
    return;	
  }

  object item = model->repository->find_by_id(model_object, (int)request->variables->id);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }

  response->redirect(action_url(display, 0, (["id": request->variables->id])));
    
  mapping v = ([]);

  array inds = indices(request->variables);

  int should_update;
  foreach(request->variables->___fields/","; int ind; string field)
  {
     // we don't worry about the primary key.
     if(item->master_object->get_primary_key()->name == field) continue; 

	array elements = glob( "_" + field + "__*", inds);
	
	if(sizeof(elements))
	{
		foreach(elements;; string e)
		{
			if(request->variables["__old_value_" + e] != request->variables[e])
			{
				werror("field: %O\n", item->master_object->fields[field]);
				Log.debug("Scaffold: " + field + " in " + model_object->instance_name + " changed.");
		        if(item->master_object->fields[field]->is_shadow) continue;
				should_update = 1;
				mapping x = ([]);
				foreach(elements;; string e)
				  x[e[(sizeof(field)+3)..]] = request->variables[e];
				v[field] = model_object->fields[field]->from_form(x, item);
				break;
			}
		}
	}
        else	
 	  if(request->variables["__old_value_" + field] != request->variables[field])
	  {
		werror("field: %O\n", item->master_object->fields[field]);
		Log.debug("Scaffold: " + field + " in " + model_object->instance_name + " changed.");
        if(item->master_object->fields[field]->is_shadow) continue;
		should_update = 1;
		v[field] = request->variables[field];
	  }
  }

  mixed err;

  if(should_update)
  {
    err = catch(item->set_atomic(v));
    if(err)
      response->flash("msg", "Error: " + err[0]);
    else
      response->flash("msg", "Update successful.");
  }
  else
    response->flash("msg", "Nothing to update.");

};
if(e)
  Log.exception("error", e);
}

static void decode_from_form(mapping variables, mapping v)
{
  array inds = indices(variables);

  foreach((variables->___fields || "")/","; int ind; string field)
  {
     // we don't worry about the primary key.
     if(model_object->get_primary_key()->name == field) continue;

        array elements = glob( "_" + field + "__*", inds);

        if(sizeof(elements))
        {
                foreach(elements;; string e)
                {
                  mapping x = ([]);
                  foreach(elements;; string e)
                    x[e[(sizeof(field)+3)..]] = variables[e];
                  v[field] = model_object->fields[field]->from_form(x);
                  break;
                }
        }
        else
          {
                v[field] = variables[field];
          }
  }
}

public void donew(Fins.Request request, Fins.Response response, mixed ... args)
{
mixed e;
mapping v = ([]);
e=catch{
  if(!(request->variables->___save || request->variables->___cancel))
  {
	response->set_data("error: invalid data");
	return;
  }

  if(request->variables->___cancel)
  {
	response->flash("msg", "create canceled.");
    response->redirect(action_url(list));
    return;	
  }

  object item = model->repository->new(model_object);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }

 // werror("%O\n", request->variables);
  m_delete(request->variables, "___save");

  array inds = indices(request->variables);

  int should_update;
//werror("inds: %O\n", inds);

  foreach(request->variables->___fields/","; int ind; string field)
  {
     // we don't worry about the primary key.
     if(item->master_object->get_primary_key()->name == field) continue; 

	array elements = glob( "_" + field + "__*", inds);
//	werror ("elements: %O\n", elements);
	if(sizeof(elements) > 0)
	{
		foreach(elements;; string e)
		{
				Log.debug("Scaffold: " + field + " in " + model_object->instance_name + " changed.");
				werror("%O\n", item->master_object->fields[field]);
		        if(item->master_object->fields[field]->is_shadow) continue;
				should_update = 1;
				mapping x = ([]);
				foreach(elements;; string e)
				  x[e[(sizeof(field)+3)..]] = request->variables[e];
				v[field] = model_object->fields[field]->from_form(x, item);
				break;
		}
	}
        else	
	  {
			werror("%O\n", item->master_object->fields[field]);
	        if(item->master_object->fields[field]->is_shadow) continue;
		Log.debug("Scaffold: " + field + " in " + model_object->instance_name + " changed.");
		should_update = 1;
		v[field] = request->variables[field];
	  }
  }
werror("setting: %O\n", v);
  item->set_atomic(v);  

  response->redirect(action_url(list));

  response->flash("msg", "create successful.");

};
if(e)
  Log.exception("error", e);
}


public void new(Fins.Request request, Fins.Response response, mixed ... args)
{
  array fields = ({});
  mapping orig = ([]);

  object v = get_view(list, new_template_string);

  v->add("type", Tools.Language.Inflect.pluralize(model_object->instance_name));

  object no = Fins.Model.new(model_object->instance_name);

  decode_old_values(request->variables, orig);

  foreach(model_object->field_order; int key; mixed value)
 {	
	if(value->is_primary_key) continue;
	fields += ({value->name});
  }

  v->add("field_order", model_object->field_order);
  v->add("orig", orig);
  v->add("item", no);
  v->add("fields", fields*",");

  response->set_view(v);
}

static string make_nice(string v)
{
  return Tools.Language.Inflect.humanize(v);
}

string make_value_editor(string key, void|mixed value, void|object o)
{
werror("make_value_editor(%O=%O)\n", key, model_object->fields[key]);
  if(model_object->fields[key]->is_shadow && !model_object->fields[key]->get_editor_string)
  {
werror("no editor for shadow field " + key + "\n");
	if(o)
	  return describe(o, key, value);   
    else return "";
  }
  else if(model_object->primary_key->name == key)
  {
    if(o) return "<input type=\"hidden\" name=\"id\" value=\"" + value + "\">" + value;	
    else return 0;
  }
  else if(model_object->fields[key]->get_editor_string)
  {
    if(o)
      return model_object->fields[key]->get_editor_string(value, o);
	else return model_object->fields[key]->get_editor_string();
//  else if(stringp(value) || intp(value))
//    return "<input type=\"text\" name=\"" + key + "\" value=\"" + value + "\">";
  }
  else 
    return sprintf("%O", value);
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
    string link;
    link = get_view_url(o);
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

string get_view_url(object o)
{
  object controller = model->repository->get_scaffold_controller(o->master_object);  
  if(!controller)
    return 0;

  string url;

  url = action_url(controller->display, 0, (["id": o[o->master_object->primary_key->name]]));  

  return url;
}
