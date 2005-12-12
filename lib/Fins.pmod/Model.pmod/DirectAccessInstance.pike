inherit .DataObjectInstance;

constant type_name = "unknown";

static void create(int identifier)
{
  object o = FinScribe.Repo.get_object(type_name);

  werror("name: %O, object: %O\n", type_name, o);
  ::create(identifier, o);
}

