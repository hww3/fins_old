inherit .DataObjectInstance;

constant type_name = "unknown";

static void create(int identifier)
{
  object o = FinScribe.Repo.get_object(type_name);
  ::create(identifier, o);
}

