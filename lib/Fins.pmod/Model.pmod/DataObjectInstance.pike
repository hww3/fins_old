.DataObject master_object;
.DataModelContext context;

//! this is an actual instance containing model-domain data
//! 

string object_type;
multiset fields_set = (<>);

// this storage location of changed values local to this instance
mapping object_data = ([]);

// this storage location of changed values local to this transaction
mapping object_data_tx = ([]);

// the local storage location of the global cache for data values of this id.
mapping object_data_cache = ([]); 

// if non-zero, the id of the current transaction. not currently used.
int transaction_id;

static mixed key_value = UNDEFINED;
int new_object = 0;
int saved = 0;
int initialized;

Iterator _get_iterator()
{
  return .DataObjectIterator(this);
}

string _sprintf(mixed ... args)
{
  return object_type + "(" + get_descriptor() + "/" + key_value + ")";
}

mixed cast(string t)
{
  switch(t)
  {
    case "mapping":
      return get_atomic();
    default:
     throw(Error.Generic("Unable to cast DataObjectInstance to " + t + ".\n"));
  }
}

string describe_value(string key, mixed value)
{
  return master_object->describe_value(key, value, this);
}

string describe()
{
  return get_descriptor();
}

string get_descriptor()
{
  if(master_object && master_object->describe)
    return master_object->describe(this);
  else return ("huh? " + get_id());
}

int _is_type(string type)
{
   if(type=="mapping")
     return 1;
   return 0;
}

//!
void set_initialized(int i)
{
  initialized = i;
}

//!
int is_initialized()
{
  return initialized;
}

//!
string get_type()
{
  return object_type;
}

//! set the default operator to use when querying on multiple fields.   
//!  valid values are @[Fins.Model.OPER_AND] and @[Fins.Model.OPER_OR].
void set_operator(int o)
{
  master_object->set_operator(o);
}

//!
static void create(mixed|void id, object _object_type, .DataModelContext context)
{
  if(!_object_type)
    throw(Error.Generic("No Data Object Definition passed to create()\n"));
  if(objectp(_object_type)) 
  {
    master_object = _object_type;
     object_type = _object_type->instance_name;
  }

  this->context = context;

  if(id == UNDEFINED)
  {
    set_new_object(1);
  }

  else
  {
    master_object->load(context, id, this);
//    master_object->add_ref(this);
  }


}

//! performs validation on object and returns an error object if any errors occur.
Fins.Errors.Validation valid()
{
  return master_object->valid(this);
}

//!
void refresh()
{
   master_object->load(context, key_value, this, 1);
}

//!
.DataObjectInstance new(void|.DataModelContext c)
{
   .DataObjectInstance new_object = object_program(this)(UNDEFINED, master_object, c||context);  

   new_object->set_new_object(1);
   return   new_object;
}

//!
.DataObjectInstance find_by_alternate(mixed id, void|.DataModelContext c)
{
   .DataObjectInstance new_object = object_program(this)(UNDEFINED, master_object, c||context);  
    master_object->load_alternate(c, id, new_object);
    return new_object;
}

//!
.DataObjectInstance find_by_id(int id, void|.DataModelContext c)
{
   .DataObjectInstance new_object = object_program(this)(UNDEFINED, master_object, c||context);  

    master_object->load(c||context, id, new_object);
//    master_object->add_ref(new_object);
   return new_object;
}

//!
array(object(.DataObjectInstance)) find_all(void|.DataModelContext c)
{
  return find(([]), c||context);
}

//!
array(object(.DataObjectInstance)) find(mapping qualifiers, .Criteria|void criteria, void|.DataModelContext c)
{
  return master_object->find(c||context, qualifiers, criteria, this);
}

//!
int delete(void|int force, void|.DataModelContext c)
{
   return master_object->delete(c||context, force, this);
}

//!
int save(int|void no_validation, void|.DataModelContext c)
{
   return master_object->save(c||context, no_validation, this);
}

//!
int set_atomic(mapping values, int|void no_validation, void|.DataModelContext c)
{
   return master_object->set_atomic(c||context, values, no_validation, this);
}

//!
int set(string name, string value, int|void no_validation, void|.DataModelContext c)
{
   return master_object->set(c||context, name, value, no_validation, this);
}

//!
mixed get_atomic(void|.DataModelContext c)
{
   return master_object->get_atomic(c||context, this);
}

//!
mixed get(string name, void|.DataModelContext c)
{
   return master_object->get(c||context, name, this);
}

//!
void set_id(mixed id)
{ 
  key_value = id;   
}

//!
mixed get_id()
{
   return key_value;
}

//!
void add(string field, mixed value)
{
  master_object->add(field, value, this);	
}

//!
void set_new_object(int(0..1) i)
{
   new_object = i;
}

//!
void set_saved(int(0..1) i)
{
   saved = i;
}

//!
int is_saved()
{
   return saved;
}

//!
int is_new_object()
{ 
   return new_object;
}

//!
mixed `[]=(mixed i, mixed v)
{
  if(!v && zero_type(v) == 1)
  {
    return get(i);
  }

  else return set(i, v);
}

//!
mixed `[](mixed arg)
{
  return get(arg);
}

//!
array _indices()
{
  array a = ({});

  foreach(master_object->fields; string name; .Field f)
  {
    a+=({name});
  }

  return a;
}

//!
array _values()
{
  array a = ({});

  foreach(master_object->fields; string name; .Field f)
  {
    a+=({get(name)});
  }

  return a;
}

//!
int `==(mixed a)
{
  if(objectp(a) && (object_program(this) == object_program(a)) && (a->get_id() == this->get_id()) && (a->get_type() == this->get_type()))
    return 1;
  else return 0;
}

/*
static void destroy()
{
  if(master_object) 
    master_object->sub_ref(this);
  else
  {
    werror("ERROR! No Master object on instance destroy!\n");
  }
}
*/
