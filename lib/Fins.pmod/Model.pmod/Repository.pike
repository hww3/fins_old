import Tools.Logging;

mapping(string:.DataObject) object_definitions = ([]);
mapping(string:program) instance_definitions = ([]);
static mapping(object:object) scaffold_controllers = ([]);

object Objects = objects(this);

class objects(object repository)
{
  mixed `[](mixed a)
  {
    if(instance_definitions[a]) return instance_definitions[a];
    else throw(Error.Generic("unknown object type " + a + ".\n"));
  }
}

//!
.DataObject get_object(string name)
{
   return object_definitions[name];
}

//!
program get_instance(string name)
{
   return instance_definitions[name];
}

//!
void add_object_type(.DataObject t, program i)
{
   Log.debug("adding type def: %O", t->instance_name);
   object_definitions[t->instance_name] = t;
   instance_definitions[t->instance_name] = i;
}

//!
void find_all(string|object ot)
{
  find(ot, ([]));
}

//!
object get_scaffold_controller(object model_component)
{
  return scaffold_controllers[model_component];
}

//!
void set_scaffold_controller(object model_component, object controller)
{
   scaffold_controllers[model_component] = controller;
}

//!
array find(string|object ot, mapping qualifiers, void|.Criteria criteria)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return get_instance(o->instance_name)(UNDEFINED)->find(qualifiers, criteria);
}

//!
.DataObjectInstance find_by_id(string|object ot, int id)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return  get_instance(o->instance_name)(id);
}

//!
.DataObjectInstance find_by_alternate(string|object ot, mixed id)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   if(!o->alternate_key)
     throw(Error.Generic("Object type " + ot + " does not have an alternate key.\n"));

   return find(o, ([o->alternate_key->name: id]))[0];
}

//!
.DataObjectInstance new(string|object ot)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
  if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
  return  get_instance(o->instance_name)(UNDEFINED);
}
