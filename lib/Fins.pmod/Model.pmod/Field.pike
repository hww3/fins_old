string name;
string field_name;
.DataModelContext context;

mixed validate(mixed value)
{
  return value;
}

mixed decode(string value)
{
   return value;
}

string encode(mixed value);

string translate_fieldname()
{
   return lower_case(name);
}

void set_context(.DataModelContext c)
{
   context = c;
}

static void create()
{
   name = name;
   field_name = translate_fieldname();
}
