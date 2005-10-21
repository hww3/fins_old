import Fins;
inherit Fins.Application;

static void create()
{
  Template.add_simple_macro("capitalize", macro_capitalize);
}


string macro_capitalize(mapping data, string|void args)
{
  return String.capitalize(data[args]||"");
}
