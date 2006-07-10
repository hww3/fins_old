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
}
