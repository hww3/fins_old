import Fins;
import Tools.Logging;
inherit FinsBase;

//! an object whose indices are the (mandatory) data type definitions for your model
//!
//! this value is used for automatic type registration.
object datatype_definition_module = 0;

//! an object whose indices are the (optional) classes that are used for direct data access
//!
//! this value is used for automatic type registration.
object datatype_instance_module = 0;

//!
object context;

//! an object that provides Model repository service, by default
//! this will be @[Fins.Model].
object repository = Fins.Model.module;

static void create(Fins.Application a)
{
  ::create(a);
  load_model();
}

void load_model()
{
   object s = Sql.Sql(config->get_value("model", "datasource"));
   object d = Fins.Model.DataModelContext();
   d->sql = s;
   d->debug = (int)(config->get_value("model", "debug"));
   d->repository = repository;
   d->cache = cache;
   d->app = app;
   d->initialize();

   context = d;

   register_types();
   initialize_links();
}

//!
void register_types()
{
  if(!datatype_definition_module)
  {
    Log.warn("Using automatic model registration, but no datatype_definition_module set. Skipping.");
    return;
  }
  foreach(indices(datatype_definition_module);; string n)
  {
    object d = datatype_definition_module[n](context);
    program di;
    if(datatype_instance_module && datatype_instance_module[n]) di = datatype_instance_module[n];
    else
    {
      string dip = "inherit Fins.Model.DirectAccessInstance;\n string type_name = \"" + n + "\";\n"
                   "object repository = " + get_repo_class() + ";";

      di = compile_string(dip); 
    }
    Log.info("Registering data type %s", d->instance_name);
    repository->add_object_type(d, di);
  }
}

string get_repo_class()
{
  if(repository == Fins.Model.module) return "Fins.Model.module";

  string s = master()->describe_object(repository);

  if(search(s, "()") != -1) // ok, we probably have a non-module class. providing a 
                            // program as opposed to a module will result in non-functional 
                            // model. i have no idea what would happen if you provided a 
                            // repository made available through add_constant.
    s = "((program)\"" + master()->describe_program(object_program(repository)) + "\")()";

  return s;
}

void initialize_links()
{
  if(!context->repository->object_definitions || 
     !sizeof(context->repository->object_definitions)) return;

  foreach(context->builder->belongs_to;; mapping a)
  {
    if(!a->my_name) a->my_name = a->other_type;
    if(!a->my_field) a->my_field = lower_case(a->other_type + "_" + context->repository->get_object(a->other_type)->primary_key->field_name);    
    a->obj->add_field(Model.KeyReference(a->my_name, a->my_field, a->other_type));
  }

  foreach(context->builder->has_many;; mapping a)
  {
    if(!a->my_name) a->my_name = a->other_type;
    if(!a->other_field) a->other_field = a->obj->instance_name;    
    a->obj->add_field(Model.InverseForeignKeyReference(a->my_name, Tools.Language.Inflect.singularize(a->other_type), a->other_field));
  }

  foreach(context->builder->possible_links;; mapping pl)
  {
    Log.debug("investigating possible link %s.", pl->field->name);
    string pln = lower_case(pl->field->name);

    foreach(context->repository->object_definitions; string on; object od)
    {
      string mln = Tools.Language.Inflect.singularize(od->table_name) + "_" + od->primary_key->field_name;
      Log.debug("considering %s as a possible field linkage.", mln);
      if(pln == lower_case(mln))
      {
        pl->obj->add_field(Model.KeyReference(od->instance_name, pl->field->name, od->instance_name));
        od->add_field(Model.InverseForeignKeyReference(Tools.Language.Inflect.pluralize(pl->obj->instance_name), pl->obj->instance_name, od->instance_name));
        context->builder->possible_links -= ({pl});
      }
    }

  }

  array table_components = ({});
    

  foreach(context->repository->object_definitions; string on; object od)
  {
    table_components += ({ (["tn": lower_case(Tools.Language.Inflect.pluralize(on)), "od": od ]) });  
  }
    
  multiset available_tables = (multiset)context->sql->list_tables();
    
  foreach(table_components;; mapping o)
  {
    Log.debug("looking for multi link reference for %s.", o->tn);

    foreach(table_components;; mapping q)
    {
      if(q->tn == o->tn) continue;  // skip self-self relationships :)

      if(available_tables[o->tn + "_" + q->tn])
      {
        Log.debug("have a mlr on %s", o->tn + "_" + q->tn);
          o->od->add_field(Model.MultiKeyReference(o->od, Tools.Language.Inflect.pluralize(q->od->instance_name),
            o->tn + "_" + q->tn, 
            lower_case(o->od->instance_name + "_" + o->od->primary_key->field_name), 
            lower_case(q->od->instance_name + "_" + q->od->primary_key->field_name),
             q->od->instance_name, q->od->primary_key->name));

          q->od->add_field(Model.MultiKeyReference(q->od, Tools.Language.Inflect.pluralize(o->od->instance_name),
            o->tn + "_" + q->tn, 
            lower_case(q->od->instance_name + "_" + q->od->primary_key->field_name), 
            lower_case(o->od->instance_name + "_" + o->od->primary_key->field_name),
             o->od->instance_name, o->od->primary_key->name));

      }
    }
  }

  werror("possible links left over: %O\n", context->builder->possible_links);
  foreach(context->builder->possible_links;; mapping pl)
  {
    pl->obj->do_add_field(pl->field);
  }
}
