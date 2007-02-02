string name;
string field_name;
.DataModelContext context;
constant type = "";
int is_shadow = 0;

optional string get_editor_string(string value, void|.DataObjectInstance i);

mixed validate(mixed value, void|.DataObjectInstance i)
{
  return value;
}

mixed decode(string value, void|.DataObjectInstance i)
{
   return value;
}

string encode(mixed value, void|.DataObjectInstance i);

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
   field_name = translate_fieldname();
}

string make_qualifier(mixed v)
{
  return field_name + "=" + encode(v);
}
