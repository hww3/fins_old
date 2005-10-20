.DataObject master_object;

string object_type = "";
multiset fields_set = (<>);
mapping object_data = ([]);
mixed key_value = UNDEFINED;
int new_object = 0;
int saved = 0;

void create(int|void id)
{
   .DataObject o = .get_object(object_type);  
   master_object = o;

  if(id == UNDEFINED)
  {
    set_new_object(1);
  }

  else
  {
    master_object->load(id, this);
  }

}

.DataObjectInstance new()
{
   .DataObjectInstance new_object = object_program(this)();  

   new_object->set_new_object(1);
   return   new_object;
}

.DataObjectInstance find(int id)
{
   .DataObjectInstance new_object = object_program(this)();

    master_object->load(id, new_object);

   return new_object;
}

int delete()
{
   return master_object->delete(this);
}

int save()
{
   return master_object->save(this);
}

int set(string name, string value)
{
   return master_object->set(name, value, this);
}

mixed get(string name)
{
   return master_object->get(name, this);
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
werror("[]=: %O %O\n", i, v);
  if(v == UNDEFINED)
  {
werror("Getting: " + i + "\n");
    return get(i);
  }

  else return set(i, v);
}

mixed `[](mixed arg)
{
werror("[]: %O\n",arg);
  return get(arg);
}

