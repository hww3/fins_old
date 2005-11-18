inherit .Field;

int len;
int null;
mixed default_value;
string name;
string transformfield;
function transformer;
int is_shadow = 1;

constant type = "Float";

void create(string _name, string _transformfield, function _transformer)
{
   name = _name;
   transformfield = _transformfield;
   transformer = _transformer;
}

int decode(string value, void|.DataObjectInstance i)
{
   return transformer(i[transformfield], i);
}

string encode(mixed value, void|.DataObjectInstance i)
{
  return (string)value;
}

mixed validate(mixed value, void|.DataObjectInstance i)
{   
   return value;
}
