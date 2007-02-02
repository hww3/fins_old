//!
//! A controller that impliments CRUD functionality
//! for a given Model segment.
//!

inherit Fins.FinsController;

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

  object items = model->find(model_object, ([]));
  if(!sizeof(items))
  {
    rv = "No " + 
      Tools.Language.Inflect.pluralize(model_object->instance_name) + 
         " found.";
  }
  else
  {
    foreach(items;; object item)
    {
      rv += " <a href=\"display?id=" + item->get_id() + "\">view</a> ";
      rv += sprintf("%O<br/>\n", item);
    }
  }
  response->set_data(rv);
}

public void display(Fins.Request request, Fins.Response response, mixed ... args)
{
  object item = model->find_by_id(model_object, (int)request->variables->id);

  string rv = "";

  if(!item)
  {
    response->set_data("item not found.");
  }

  else foreach(item->get_atomic(); string key; mixed value)
  {
    if(stringp(value) || intp(value))
      rv += "<b>" + make_nice(key) + "</b>: " + value + "<br/>"; 
    else if(arrayp(value))
      rv += "<b>" + make_nice(key) + "</b>: " + describe_array(value) + "<br/>";
    else if(objectp(value))
      rv += "<b>" + make_nice(key) + "</b>: " + describe_object(value) + "<br/>";
  }

  response->set_data(rv);
}

public void new(Fins.Request request, Fins.Response response, mixed ... args)
{
  response->set_data("new");
}

public void update(Fins.Request request, Fins.Response response, mixed ... args)
{
  response->set_data("update");
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
werror(" controller: %O\n", controller);
  if(!controller)
    return 0;

  string url = app->get_path_for_controller(controller);

  url = url + "/display/?id=" + o[o->master_object->primary_key->name];  

  return url;
}
