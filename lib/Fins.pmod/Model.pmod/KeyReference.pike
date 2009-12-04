inherit .Relationship;

import Tools.Logging;

mixed default_value = .Undefined;
int null = 0;
.Criteria criteria;

static void create(string _name, string _myfield, string _otherobject, void|.Criteria _criteria, void|int _null)
{
  name = _name;
  field_name = _myfield;
  otherobject = _otherobject;
  criteria = _criteria;
  null = _null;
}

// value should be the value of the link field, which is the primary key of the 
// other object we're about to get.
mixed decode(string value, void|.DataObjectInstance i)
{
//	werror("INSTANCE: %O\n", i);
	object ot = context->repository->get_object(otherobject);
	mixed val = ot->primary_key->decode(value);
	if(val)
      return i->context->find_by_id(ot, val);
    else return 0;
}

// value should be a dataobject instance of the type we're looking to set.
string encode(int|.DataObjectInstance value, void|.DataObjectInstance i)
{
Log.debug("%O(%O, %O)", Tools.Function.this_function(), value, i);
  value = validate(value);
Log.debug("%O(): validate() returns %O", Tools.Function.this_function(), value);

  if(intp(value)) return (string)value;

  if(value->is_new_object())
  {
    value->save();
  }
    
  return (string)value->get_id();
}


mixed validate(mixed value, void|.DataObjectInstance i)
{
Log.debug("%O(%O, %O)", Tools.Function.this_function(), value, i);

   if(intp(value)) return value;

   if(value == .Undefined && !null && default_value == .Undefined)
   {
     throw(Error.Generic("Field " + name + " cannot be null; no default value specified.\n"));
   }

   else if (value == .Undefined && !null && default_value!= .Undefined)
   {
     return default_value;
   }

   else if (value == .Undefined)
   {
     return .Undefined;
   }

   else if(value->get_type() != otherobject)
     throw(Error.Generic(sprintf("Got %O object, expected %s.\n", value->get_type(), otherobject)));

   return value;
}



string get_editor_string(mixed|void value, void|.DataObjectInstance i)
{
  string desc = "";
  object sc = context->app->model->repository->get_scaffold_controller(context->app->model->repository->get_object(otherobject));
werror("value for keyreference is %O, scaffold controller is %O\n", value, sc);
  if(!value) desc = "not set";
  else 
  {
    if(objectp(value) && value->describe)
      desc = value->describe();
    else desc = sprintf("%O", value);

    if(sc && sc->display)
     desc = sprintf("<input type=\"hidden\" name=\"_%s__id\" value=\"%d\"><a href=\"%s\">%s</a>", 
      name, value?value->get_id():0, context->app->url_for_action(sc->display, ({}), (["id": value?value->get_id():0 ])),  
      desc);
  }

werror("other object is %O\n", otherobject);
  if(sc && sc->pick_one)
  {
    desc += sprintf(" <a href='javascript:fire_select(%O)'>select</a>",
      context->app->url_for_action(sc->pick_one, ({}), (["selected_field": name, "for": i->master_object->instance_name,"for_id": i->get_id()]))
     );
  }
werror("returning %O\n", desc);
  return desc;
}
  
optional mixed from_form(mapping value, void|.DataObjectInstance i)
{ 
  return context->app->model->repository->find_by_id(otherobject, (int)value->id);
}
  
  
