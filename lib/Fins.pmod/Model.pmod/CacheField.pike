inherit .Field;

int len;
int null;
mixed default_value;
string name;
string cachefield;
int is_shadow = 1;
constant type = "Float";

void create(string _name, string _cachefield, object ctx)
{
   context = ctx;
   name = _name;
   cachefield = _cachefield;
}

int decode(string value, void|.DataObjectInstance i)
{
   mixed o = context->cache->get(sprintf("CACHEFIELD%s-%d",
       name, i->get_id()));
   if(o) return o;

   o = i[cachefield];

    context->cache->set(sprintf("CACHEFIELD%s-%d", 
       name, i->get_id()), o, 600);
   return o;
}

string encode(mixed value, void|.DataObjectInstance i)
{
  return (string)value;
}

mixed validate(mixed value, void|.DataObjectInstance i)
{   
   return value;
}
