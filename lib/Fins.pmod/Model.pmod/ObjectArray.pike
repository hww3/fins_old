.Field field;
object otherobject;
object parentobject;
array contents;
int changed;

static void create(.Field f, object parent)
{
  field = f; 
  parentobject = parent;
  otherobject = parent->master_object->context->repository["get_object"](field->otherobject);
  changed = 1;


}

static mixed cast(string rt)
{
  if(rt != "array")
    throw(Error.Generic("Cannot cast ObjectArray to " + rt + ".\n"));

  if(changed)
    get_contents();

  return contents;
}

Iterator _get_iterator()
{
  if(changed)
    get_contents();

  return Array.Iterator(contents);
}

int _sizeof()
{
  if(changed)
    get_contents();
  
  return sizeof(contents);
}

int(0..1) _is_type(string t)
{
  int v=0;

  switch(t)
  {
    case "array":
      v = 1;
      break;
  }

  return v;
}

void get_contents()
{
  contents = parentobject->master_object->context->repository["find"](otherobject, ([ field->otherkey :
                                  (int) parentobject->get_id()]));

  changed = 0;
}

mixed `+(mixed arg)
{

  // do we have the right kind of object?
  if(!objectp(arg) || !arg->master_object || arg->master_object != otherobject)
  {
    throw(Error.Generic("Wrong kind of object: got " + sprintf("%O", arg) 
+ ", expected DataObjectInstance.\n"));
  }

  // ok, we have the right kind of object, now we need to get the id.
  int id = parentobject->get_id();  

  arg[field->otherkey] = id;
  changed = 1;
  return this;
}

.DataObjectInstance get_element(int e)
{
  if(changed)
    get_contents();

  if(contents[e])
    return contents[e];
  else
    throw(Error.Generic("Error indexing the array with element " + e + ".\n"));
     
}

mixed `[]=(int i, mixed v)
{
  if(v == UNDEFINED)
  {
return 0;
//    return get(i);
  }
return 0;

 // else return set(i, v);
}

mixed `[](int arg)
{
  return get_element(arg);

}

