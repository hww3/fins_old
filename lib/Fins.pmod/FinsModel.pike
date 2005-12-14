import Fins;
inherit FinsBase;

object context;
object repository = Fins.Model;

static void create(Fins.Application a)
{
  ::create(a);
  load_model();
}

void load_model()
{
   object s = Sql.Sql(app()->config->get_value("model", "datasource"));
   object d = Fins.Model.DataModelContext();
   d->sql = s;
   d->debug = (int)(app()->config->get_value("model", "debug"));
   d->repository = repository;
   d->cache = app()->cache;
   d->app = app();
   d->initialize();

   context = d;
}
