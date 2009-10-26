inherit .DataObjectInstance;

//! provides direct data object instance access

//!
string type_name = "unknown";

//!
string context_name = "_default";

//!
static void create(int|void identifier, void|.DataModelContext c)
{
  if(!c)
	  c = Fins.Model.get_context(context_name);
  object o = c->repository->get_object(type_name);
  ::create(identifier, o, c);
}
