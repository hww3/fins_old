
mapping(string:.DataObject) object_definitions = ([]);
mapping(string:program) instance_definitions = ([]);

.DataObject get_object(string name)
{
   return object_definitions[name];
}

program get_instance(string name)
{
   return instance_definitions[name];
}

void add_object_type(.DataObject t, program i)
{
werror("adding type def: %O\n", t->instance_name);
   object_definitions[t->instance_name] = t;
   instance_definitions[t->instance_name] = i;
}

array find(string|object ot, mapping qualifiers, void|.Criteria criteria)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return get_instance(o->instance_name)(UNDEFINED)->find(qualifiers, criteria);
}


.DataObjectInstance find_by_id(string|object ot, int id)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return  get_instance(o->instance_name)(id);
}

.DataObjectInstance new(string|object ot)
{
   object o;
   if(stringp(ot))
     o = get_object(ot);
   else
     o = ot;
  if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
  return  get_instance(o->instance_name)(UNDEFINED);
}
