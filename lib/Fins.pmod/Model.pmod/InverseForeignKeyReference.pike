//! This relationship represents one half of a one-to-many or parent-and-child between one type and another. 
//! The "parent" uses the "inverse" relationship because it does not contain a reference to the child itself.
//!
//! Put more technically, this relationship can be used to access objects of another type (the child) using a 
//! field on that type containing the object id of an object of this (the parent) type.
//!
//! For example:
//!
//! A type "user" has a primary key field id. A type "preference" has a foreign key field "user_id" that 
//! indicates the user for which that preference is associated. The definition of the "preference" type 
//! would contain a reference for the foreign key (a @[Fins.Model.ForeignKeyRelationship]) whereas the
//! "user" object definition would contain the inverse relationship (@[Fins.Model.InverseForeignKeyRelationship])
//! which could be used to find all "preference" objects owned by that user.

inherit .Relationship;

constant type="Foreign Key";

string otherkey; 
mixed default_value = .Undefined;
int null = 0;
int is_shadow=1;
int unique;
.Criteria criteria;

//! "unique" implies that this is a one-to-one relationship.
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
  //werror("**--> decoding " + name + ", a link to %O from %O using %O\n", otherobject, i, otherkey);

  if(!unique)
  {
    return .ObjectArray(this, i);
  }
  else
  {
    array r = i->context->old_find(otherobject, ([ otherkey : (int) i->get_id()]), criteria);
    if(r && sizeof(r))
      return r[0];
    else return 0;
  }
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

