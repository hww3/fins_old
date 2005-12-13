inherit .DataObjectInstance;

string type_name = "unknown";
object repository = .module;

static void create(int identifier)
{
  object o = repository["get_object"](type_name);

  ::create(identifier, o);
}
