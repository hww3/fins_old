//! This relationship is a variation of the InverseForeignKeyReference, that is the "one" in one-to-many,
//! where the gathered records are presented as a mapping or array. The records are indexed using the values of 
//! a field on the related object. 
//!
//! For example:
//!
//! A type "user" has a primary key field id. A type "preference" has a foreign key field "user_id" that 
//! indicates the user for which that preference is associated. The definition of the "preference" type 
//! would contain a reference for the foreign key (a @Fins.Model.ForeignKeyRelationship) whereas the
//! "user" object definition would contain the inverse relationship (@Fins.Model.InverseForeignKeyRelationship)
//! which could be used to find all "preference" objects owned by that user.
//! 
//! Alternately, if the "preference" object had some field that identified the particular preference for this 
//! user, perhaps "preference_name", we could use this relationship type to organize the user's preferences in a mapping
//! by name, saving us from having to perform an additional find operation:
//!
//! someuser["preferences"]["default_folder"]


//inherit .InverseForeignKeyReference;
inherit .Relationship;

constant type="Indexed Foreign Key";

string index_field;
string otherkey; 
mixed default_value = .Undefined;
int null = 0;
int is_shadow=1;
int unique;
.Criteria criteria;

static void create(string _name, string _otherobject, string _otherkey, string _index_field, .Criteria|void _criteria)
{
  name = _name;
  otherobject = _otherobject;
  otherkey = _otherkey;
  criteria = _criteria;
  index_field = _index_field;	
//	::create(_name, _otherobject, _otherkey, _criteria);	
}

// value will be null in a foreign key, as we're not in an object where that's a real field. 
mixed decode(string value, void|.DataObjectInstance i) 
{ 
  //werror("**--> decoding " + name + ", a link to %O from %O using %O\n", otherobject, i, otherkey);
	return .ObjectMapping(this, i, 0, index_field);
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

string get_editor_string(mixed|void value, void|.DataObjectInstance i)
{
  return "whee";
}

//optional mixed from_form(mapping value, void|.DataObjectInstance i);

