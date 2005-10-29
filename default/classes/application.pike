import Fins;
inherit Fins.Application;

static void create(Fins.Configuration config)
{
  Template.add_simple_macro("capitalize", macro_capitalize);

  ::create(config);
}


string macro_capitalize(mapping data, string|void args)
{
  return String.capitalize(data[args]||"");
}
