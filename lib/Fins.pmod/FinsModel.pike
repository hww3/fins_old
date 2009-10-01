import Fins;
inherit FinsBase;

object log = Tools.Logging.get_logger("model");

//! the default context
object context;

//! 
mapping contexts = ([]);

static void create(Fins.Application a)
{
  ::create(a);
  load_model();
}

void load_model()
{
// an object that provides Model repository service, by default
// this will be @[Fins.Model]. Do not change this, as the app loader
// won't use this value, causing the model to break.

  context = configure_context(config["model"], 1);

  contexts["_default"] = context;

  foreach(glob("model_*", config->get_sections());; string md)
  {
	 log->info("configuring model id <" + config[md]["id"] + "> specified in config secion " + md);
     object ctx = configure_context(config[md], 0);
     contexts[config[md]["id"]] = ctx;
  }

}

object configure_context(mapping config_section, int is_default)
{
  object repository;
  string definition_module;

  if(is_default)
    repository = Fins.Model.module;
  else
    repository = Fins.Model.Repository();

  object o;

  object defaults = Fins.Helpers.Defaults;
  catch(defaults = (object)"defaults");

  if(is_default) definition_module = config->app_name;
  else definition_module = config_section->definition_module;

  if(!definition_module)
  {
	throw(Error.Generic("No model definition module specified. Cannot configure model."));
  }

  if(o = master()->resolv(definition_module + "." + defaults->data_mapping_module_name))
    repository->set_model_module(o);
  if(o = master()->resolv(definition_module + "." + defaults->data_instance_module_name))
    repository->set_object_module(o);

 string url = config_section["datasource"];
 object s = Sql.Sql(url);
 object d = Fins.Model.DataModelContext();
 d->sql = s;
 d->sql_url = url;
 d->debug = (int)config_section["debug"];
 d->repository = repository;
 d->cache = cache;
 d->app = app;
 d->model = this;
 d->initialize();

 repository->set_default_context(d);

 register_types(d);
 initialize_links(d);

  return d;
}

//!
void register_types(object ctx)
{
  if(!ctx->repository->get_object_module())
  {
    log->warn("Using automatic model registration, but no datatype_definition_module set. Skipping.");
    return;
  }
  object im = ctx->repository->get_object_module();
  object mm = ctx->repository->get_model_module();

// werror("mm: %O\n", mm);
  foreach(mkmapping(indices(mm), values(mm));string n; program c)
  {
    object d = c(ctx);
    program di;
    if(im && im[n])
    {
	  di = im[n];
          if(di && !di->type_name) {/*werror("%O\n", di);di->type_name = n;*/}
    }
    else
    {
      string dip = "inherit Fins.Model.DirectAccessInstance;\n string type_name = \"" + n + "\";\n"
                   "object repository = " + get_repo_class(ctx->repository) + ";";

      di = compile_string(dip); 
    }
    log->info("Registering data type %s", d->instance_name);
    ctx->repository->add_object_type(d, di);
  }
}

//!
string get_repo_class(object repository)
{
  object r;

  if(repository == Fins.Model.module) return "Fins.Model.module";

  r = master()->resolv(app->config->app_name + ".Repo");

  if(repository == r) return app->config->app_name + ".Repo";

  string s = master()->describe_object(repository);

  if(search(s, "()") != -1) // ok, we probably have a non-module class. providing a 
                            // program as opposed to a module will result in non-functional 
                            // model. i have no idea what would happen if you provided a 
                            // repository made available through add_constant.
    s = "((program)\"" + master()->describe_program(object_program(repository)) + "\")()";

  return s;
}

void initialize_links(object ctx)
{
  if(!ctx->repository->object_definitions || 
     !sizeof(ctx->repository->object_definitions)) return;

  foreach(ctx->builder->belongs_to;; mapping a)
  {
    if(!a->my_name) a->my_name = a->other_type;
    if(!a->my_field) a->my_field = lower_case(a->other_type + "_" + ctx->repository->get_object(a->other_type)->primary_key->field_name);    
    a->obj->add_field(Model.KeyReference(a->my_name, a->my_field, a->other_type));
  }

  foreach(ctx->builder->has_many;; mapping a)
  {
    if(!a->my_name) a->my_name = a->other_type;
    if(!a->other_field) a->other_field = a->obj->instance_name;    
    a->obj->add_field(Model.InverseForeignKeyReference(a->my_name, Tools.Language.Inflect.singularize(a->other_type), a->other_field));
  }

  foreach(ctx->builder->has_many_many;; mapping a)
  {
     object this_type;
     object that_type;

     this_type = ctx->repository->object_definitions[a->this_type->instance_name];
     that_type = ctx->repository->object_definitions[a->that_type];
//werror("%O\n", a /*indices(ctx->repository->object_definitions)*/);
     log->debug("*** have a Many-to-Many relationship in %s between %O and %O", a->join_table, this_type, that_type);

     this_type->add_field(Model.MultiKeyReference(this_type, Tools.Language.Inflect.pluralize(a->that_name),
            a->join_table,
            lower_case(this_type->instance_name + "_" + this_type->primary_key->field_name),
            lower_case(that_type->instance_name + "_" + that_type->primary_key->field_name),
             that_type->instance_name, that_type->primary_key->name));

     that_type->add_field(Model.MultiKeyReference(that_type, Tools.Language.Inflect.pluralize(a->this_name),
            a->join_table,
            lower_case(that_type->instance_name + "_" + that_type->primary_key->field_name),
            lower_case(this_type->instance_name + "_" + this_type->primary_key->field_name),
             this_type->instance_name, this_type->primary_key->name));
  }

  foreach(ctx->builder->possible_links;; mapping pl)
  {
    log->debug("investigating possible link %s.", pl->field->name);
    string pln = lower_case(pl->field->name);

    foreach(ctx->repository->object_definitions; string on; object od)
    {
      string mln = Tools.Language.Inflect.singularize(od->table_name) + "_" + od->primary_key->field_name;
      log->debug("considering %s as a possible field linkage.", mln);
      if(pln == lower_case(mln))
      {
        pl->obj->add_field(Model.KeyReference(od->instance_name, pl->field->name, od->instance_name));
        od->add_field(Model.InverseForeignKeyReference(Tools.Language.Inflect.pluralize(pl->obj->instance_name), pl->obj->instance_name, od->instance_name));
        ctx->builder->possible_links -= ({pl});
      }
    }
  }

  array table_components = ({});

  foreach(ctx->repository->object_definitions; string on; object od)
  {
    table_components += ({ (["tn": lower_case(Tools.Language.Inflect.pluralize(on)), "od": od ]) });  
  }
    
  multiset available_tables = (multiset)ctx->sql->list_tables();
    
  foreach(table_components;; mapping o)
  {
    log->debug("looking for multi link reference for %s.", o->tn);

    foreach(table_components;; mapping q)
    {
      if(q->tn == o->tn) continue;  // skip self-self relationships :)

      if(available_tables[o->tn + "_" + q->tn])
      {
        log->debug("have a mlr on %s", o->tn + "_" + q->tn);
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

  log->debug("possible links left over: %O", ctx->builder->possible_links);
  foreach(ctx->builder->possible_links;; mapping pl)
  {
    pl->obj->do_add_field(pl->field);
  }
  
  ctx->builder->belongs_to = ({});
  ctx->builder->has_many = ({});
  ctx->builder->has_many_many = ({});
}
