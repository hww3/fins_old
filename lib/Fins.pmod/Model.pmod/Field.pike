string name;
string field_name;
object context; // DataModelContext
constant type = "";
int is_shadow = 0;

optional string get_editor_string(mixed|void value, void|object i);
optional mixed from_form(mapping value, void|object i);

mixed validate(mixed value, void|object i)
{
  return value;
}

mixed decode(string value, void|object i)
{
   return value;
}

string encode(mixed value, void|object i);

string translate_fieldname()
{
   return lower_case(name);
}

void set_context(object c)
{
   context = c;
}

static void create()
{
   field_name = translate_fieldname();
}

string make_qualifier(mixed v)
{
  return field_name + "=" + encode(v);
}

string describe(mixed v, void|object i)
{
  return encode(v, i);
}
