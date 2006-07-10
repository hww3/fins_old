import Fins;
import Tools.Logging;
inherit FinsBase;

//!
object context;

//! an object that provides Model repository service, by default
//! this will be @[Fins.Model].
object repository = Fins.Model;

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

}

void initialize_links()
{
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
}
