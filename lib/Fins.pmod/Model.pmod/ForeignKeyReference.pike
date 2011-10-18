
//! This relationship represents one half (the many or child) of a one-to-many or parent-and-child between 
//! one type and another. 
//! Thie "child" uses the direct (ForeignKeyReference) relationship because it contains the field holding the foreign key.
//! The "parent" uses the "inverse" relationship because it does not contain a reference to the child itself.
//!
//! Put more technically, this relationship can be used to access objects of another type (the child) using a 
//! field on that type containing the object id of an object of this (the parent) type.
//!
//! For example:
//! A type "user" has a primary key field id. A type "preference" has a foreign key field "user_id" that 
//! indicates the user for which that preference is associated. The definition of the "preference" type 
//! would contain a reference for the foreign key (a @[Fins.Model.ForeignKeyRelationship]) whereas the
//! "user" object definition would contain the inverse relationship (@[Fins.Model.InverseForeignKeyRelationship])
//! which could be used to find all "preference" objects owned by that user.


inherit .Relationship;

constant type="Foreign Key";

mapping otherobjects = ([]);

string otherkey; 
mixed default_value = .Undefined;
int null = 0;
int is_shadow=1;

static void create(string _name)
{
  name = _name;
}

// value will be null in a foreign key, as we're not in an object where that's a real field.
mixed decode(string value, void|.DataObjectInstance i)
{
  return .DataObjectInstance(UNDEFINED, otherobject, i->context)->find(([ 			
		i->master_object->primary_key->field_name :
                                  (int) i->get_id()]));
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
  
  
