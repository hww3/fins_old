
mapping(string:.DataObject) object_definitions = ([]);

.DataObject get_object(string name)
{
   return object_definitions[name];
}

void add_object_type(.DataObject t)
{
   object_definitions[t->instance_name] = t;
}

array find(string|object ot, mapping qualifiers, void|.Criteria criteria)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return .DataObjectInstance(UNDEFINED, o)->find(qualifiers, criteria);
}


.DataObjectInstance find_by_id(string|object ot, int id)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return .DataObjectInstance(id, o);
}

.DataObjectInstance new(string|object ot)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
  if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
  return .DataObjectInstance(UNDEFINED, o);
}


