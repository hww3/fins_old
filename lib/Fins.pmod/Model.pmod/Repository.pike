//! contains and manages the Data Mapping and Object Instance definitions, ScaffoldControllers 
//! and other objects associated with a given model definition.
//!
//! most of the values and methods in this class are used internally by the model.

mapping(string:.DataObject) object_definitions = ([]);
mapping(program:.DataObject) program_definitions = ([]);
mapping(string:program) instance_definitions = ([]);
static mapping(string:mapping(object:object)) scaffold_controllers = ([]);
static object model_module;
static object object_module;

object log = Tools.Logging.get_logger("fins.model");

object Objects = objects(this);

private .DataModelContext default_context;

class objects(object repository)
{
  mixed `[](mixed a)
  {
    if(instance_definitions[a]) return instance_definitions[a];
    else throw(Error.Generic("unknown object type " + a + ".\n"));
  }
}

.DataModelContext get_default_context()
{
   return default_context;
}

void set_default_context(.DataModelContext c)
{
	default_context = c;
}

//!
object get_model_module()
{ 
  return model_module;
}

//!
object get_object_module()
{
  return object_module;
}

//! called in Fins.FinsModel.
void set_model_module(object o)
{
  model_module = o;
}

//! called in Fins.FinsModel.
void set_object_module(object o)
{
  object_module = o;
}

//!
.DataObject get_object(string|program name)
{
  if(programp(name))
   return program_definitions[name];
  else
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
   log->debug("adding type def: %O", t->instance_name);
   object_definitions[t->instance_name] = t;
   program_definitions[object_program(t)] = t;
   instance_definitions[t->instance_name] = i;
}

//!
object get_scaffold_controller(string type, object model_component)
{
 // werror("get_scaffold_controller(%O) in %O\n", model_component, scaffold_controllers);

  if(!scaffold_controllers[type])
    scaffold_controllers[type] = ([]);
  return scaffold_controllers[type][model_component];
}

//!
void set_scaffold_controller(string type, object model_component, object controller)
{
  if(!scaffold_controllers[type])
    scaffold_controllers[type] = ([]);
   scaffold_controllers[type][model_component] = controller;
}
