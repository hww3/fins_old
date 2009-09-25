inherit .DataObjectInstance;

//! provides direct data object instance access

//!
string type_name = "unknown";

//!
object repository = .module;

//!
static void create(int|void identifier, void|.DataModelContext c)
{
  object o = repository["get_object"](type_name);

  ::create(identifier, o, c);
}
