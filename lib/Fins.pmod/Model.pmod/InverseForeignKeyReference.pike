inherit .Relationship;

constant type="Foreign Key";

string otherobject; 
string otherkey; 
mixed default_value = .Undefined;
int null = 0;
int is_shadow=1;
int unique;
.Criteria criteria;

static void create(string _name, string _otherobject, string _otherkey, .Criteria|void _criteria, int|void _unique)
{
  name = _name;
  otherobject = _otherobject;
  otherkey = _otherkey;
  criteria = _criteria;
  unique = _unique;
}

// value will be null in a foreign key, as we're not in an object where that's a real field.
mixed decode(string value, void|.DataObjectInstance i)
{
  if(unique)
  	 return (.DataObjectInstance(UNDEFINED, otherobject)->find(([ otherkey :
                                  (int) i->get_id()]), criteria))[0];

  else
  	 return .DataObjectInstance(UNDEFINED, otherobject)->find(([ otherkey :
                                  (int) i->get_id()]), criteria);
}

// value should be a dataobject instance of the type we're looking to set.
string encode(.DataObjectInstance value, void|.DataObjectInstance i)
{
  return "";
}


mixed validate(mixed value, void|.DataObjectInstance i)
{
  return 0;
}

