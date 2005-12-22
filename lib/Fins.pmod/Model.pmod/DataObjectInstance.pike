.DataObject master_object;

string object_type;
multiset fields_set = (<>);
mapping object_data = ([]);
static mixed key_value = UNDEFINED;
int new_object = 0;
int saved = 0;
int initialized;

string _sprintf(mixed ... args)
{
  return object_type + "(" + key_value + ")";
}

int _is_type(string type)
{
   if(type=="mapping")
     return 1;
   return 0;
}

void set_initialized(int i)
{
  initialized = i;
}

int is_initialized()
{
  return initialized;
}

string get_type()
{
  return object_type;
}

static void create(mixed|void id, object _object_type)
{
  if(objectp(_object_type)) 
  {
    master_object = _object_type;
     object_type = _object_type->instance_name;
  }
werror("DataObjectInstance\n");
   

  if(id == UNDEFINED)
  {
    set_new_object(1);
  }

  else
  {
    master_object->load(id, this);
    master_object->add_ref(this);
  }


}

void refresh()
{
   master_object->load(key_value, this, 1);
}

.DataObjectInstance new()
{
   .DataObjectInstance new_object = object_program(this)(UNDEFINED, master_object);  

   new_object->set_new_object(1);
   return   new_object;
}

.DataObjectInstance find_by_id(int id)
{
   .DataObjectInstance new_object = object_program(this)(UNDEFINED, master_object);  

    master_object->load(id, new_object);
    master_object->add_ref(new_object);
   return new_object;
}

array(object(.DataObjectInstance)) find(mapping qualifiers, .Criteria|void criteria)
{
  return master_object->find(qualifiers, criteria, this);
}

int delete(void|int force)
{
   return master_object->delete(force, this);
}

int save()
{
   return master_object->save(this);
}

int set_atomic(mapping values)
{
   return master_object->set_atomic(values, this);
}

int set(string name, string value)
{
   return master_object->set(name, value, this);
}

mixed get_atomic()
{
   return master_object->get_atomic(this);
}

mixed get(string name)
{
   return master_object->get(name, this);
}

void set_id(mixed id)
{ 
  key_value = id;   
}

mixed get_id()
{
   return key_value;
}

void add(string field, mixed value)
{
  master_object->add(field, value, this);	
}

void set_new_object(int(0..1) i)
{
   new_object = i;
}

void set_saved(int(0..1) i)
{
   saved = i;
}

int is_saved()
{
   return saved;
}

int is_new_object()
{ 
   return new_object;
}

mixed `[]=(mixed i, mixed v)
{
//  werror("ARGS: %O\n", query_num_arg());
  if(!v && zero_type(v) == 1)
  {
    return get(i);
  }

  else return set(i, v);
}

mixed `[](mixed arg)
{
  return get(arg);
}

array _indices()
{
  array a = ({});

  foreach(master_object->fields; string name; .Field f)
  {
    a+=({name});
  }

  return a;
}

array _values()
{
  array a = ({});

  foreach(master_object->fields; string name; .Field f)
  {
    a+=({get(name)});
  }

  return a;
}

static void destroy()
{
  if(master_object) 
    master_object->sub_ref(this);
  else
  {
    werror("ERROR! No Master object on instance destroy!\n");
  }
}
