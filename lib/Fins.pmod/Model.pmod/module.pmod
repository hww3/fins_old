
mapping(string:.DataObject) object_definitions = ([]);

constant Undefined = .Undefined_Value;

.DataObject get_object(string name)
{
   return object_definitions[name];
}

void add_object_type(.DataObject t)
{
   object_definitions[t->instance_name] = t;
}

array find(string ot, mapping qualifiers, void|.Criteria criteria)
{
   return .DataObjectInstance(UNDEFINED, ot)->find(qualifiers, criteria);
}


.DataObjectInstance find_by_id(string ot, int id)
{
   return .DataObjectInstance(id, ot);
}

.DataObjectInstance new(string ot)
{
  return .DataObjectInstance(UNDEFINED, ot);
}
