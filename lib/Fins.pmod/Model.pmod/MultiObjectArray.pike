inherit .ObjectArray;

void get_contents()
{
	werror("get_contents(): %O\n", field->name);
  contents = parentobject->master_object->context->repository->find(otherobject, ([ field : parentobject]));

werror("CONTENTS: %O\n", contents);
  changed = 0;
}

mixed `+(mixed arg)
{
  werror("`+(%O)\n", arg);

  // do we have the right kind of object?
  if(!objectp(arg) || !arg->master_object || arg->master_object != otherobject)
  {
    throw(Error.Generic("Wrong kind of object: got " + sprintf("%O", arg) + ", expected DataObjectInstance.\n"));
  }

  // ok, we have the right kind of object, now we need to get the id.
  int id = parentobject->get_id();  

  arg->master_object->context->sql->query("INSERT INTO " + field->mappingtable + 
	 "(" + field->my_mappingfield + "," + field->other_mappingfield + ") VALUES(" + 
	 parentobject->master_object->primary_key->encode(parentobject->get_id()) + "," + 
	 arg->master_object->primary_key->encode(arg->get_id()) + ")");

  changed = 1;
  return this;
}