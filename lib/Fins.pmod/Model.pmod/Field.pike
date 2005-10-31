string name;
string field_name;
.DataModelContext context;
constant type = "";
int is_shadow = 0;

mixed validate(mixed value, void|.DataModelInstance i)
{
  return value;
}

mixed decode(string value, void|.DataModelInstance i)
{
   return value;
}

string encode(mixed value, void|.DataModelInstance i);

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

string make_qualifier(mixed v)
{
  return field_name + "=" + encode(v);
}
