//! This relationship object is used to model a many-to-many relationship between two
//! data types using a third "join" table containing the primary keys of the two types 
//! to be mapped.

inherit .Relationship;

constant type="Multi Key";

object parent;
string otherkey; 
int null = 0;
int is_shadow=1;
int unique;
.Criteria criteria;
string mappingtable;
string my_mappingfield;
string other_mappingfield;

static void create(object p, string _name, string _mappingtable, string _my_mappingfield, 
	string _other_mappingfield, string _otherobject, string _otherkey, .Criteria|void _criteria)
{
  name = _name;
  mappingtable = _mappingtable;
  my_mappingfield = _my_mappingfield;
  other_mappingfield = _other_mappingfield;
  otherobject = _otherobject;
  otherkey = _otherkey;
  criteria = _criteria;
  parent = p;
}

// value will be null in a foreign key, as we're not in an object where that's a real field. 
mixed decode(string value, void|.DataObjectInstance i) 
{ 
    return .MultiObjectArray(this, i, i->context);
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

string make_qualifier(mixed value)
{
  string v = "";

  if(arrayp(value))
  {
    error("We don't do arrays yet!\n");	
  }
  else
  {
     v = mappingtable + "." + other_mappingfield + "=" + value->get_id() + " AND " + 
	      parent->table_name + "." + parent->primary_key->field_name + "=" + mappingtable + "." + my_mappingfield ;	
  }

  return v;
}

string get(mixed name, mixed value, .DataObjectInstance i)
{
	string v = "";

   if(value)
   {
     v = mappingtable + "." + my_mappingfield + "=" + name->get_id() + " AND " + 
	    context->repository->get_object(otherobject)->table_name + "." + 
	    otherkey + "=" + mappingtable + "." + other_mappingfield ;
   }
   return v;
}

string get_table(string name, string value, .DataObjectInstance i)
{
	return mappingtable;
}
