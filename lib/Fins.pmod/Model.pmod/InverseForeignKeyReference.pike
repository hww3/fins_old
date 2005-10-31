inherit .Relationship;

constant type="Foreign Key";

string otherobject; 
mixed default_value = .Undefined;
int null = 0;
int is_shadow=1;

static void create(string _name, string _otherobject)
{
  name = _name;
  otherobject = _otherobject;
}

// value will be null in a foreign key, as we're not in an object where that's a real field.
mixed decode(string value, void|.DataModelInstance i)
{
  return .DataObjectInstance(UNDEFINED, otherobject)->find(([ .get_object(otherobject)->primary_key->field_name :
            (int) i->get_id()]));
}

// value should be a dataobject instance of the type we're looking to set.
string encode(.DataObjectInstance value, void|.DataModelInstance i)
{
  return "";
}


mixed validate(mixed value, void|.DataModelInstance i)
{
  return 0;
}

