
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

