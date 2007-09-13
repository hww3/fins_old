//! This is an object that defines a model-domain data type.
//! This class is singleton for a given data type. Use a
//! DataObjectInstance object to retrieve data for a given
//! data type.

import Tools.Logging;

string default_operator = " AND ";

//!
constant SORT_ASCEND = 1;

//!
constant SORT_DESCEND = -1;

//! an array with each element being an array with 2 elements: a field name and 
//! the sort order  @[SORT_ASCEND] or @[SORT_DESCEND]. Note that any 
//! criteria provided to a find operation will override this setting.
//!
//! @example
//!   array default_sort_fields = ({ ({"name", SORT_DESCEND}) });
array default_sort_fields;

string _default_sort_order_cached;

mapping default_values = ([]);

//!
.Field primary_key;

//!
.Field alternate_key;


//!
.DataModelContext context;

object my_undef = .Undefined;

//!
mapping objs = ([]);

//!
mapping fields = ([]);

//!
mapping relationships = ([]);

string single_select_query = "SELECT %s FROM %s WHERE %s=%s";
string multi_select_query = "SELECT %s FROM %s WHERE %s";
string multi_select_nowhere_query = "SELECT %s FROM %s";
string single_update_query = "UPDATE %s SET %s=%s WHERE %s=%s";
string single_delete_query = "DELETE FROM %s WHERE %s=%s";
string multi_update_query = "UPDATE %s SET %s WHERE %s=%s";
string insert_query = "INSERT INTO %s %s VALUES %s";

int autosave = 1;

string instance_name = "";
string table_name = "";
mapping new_object_data = ([]);
array field_order = ({});

//!
void create(.DataModelContext c)
{
   context = c;

   if(define && functionp(define))
   {
     define();
   }
   else
   { 
     reflect_definition();
   }

   if(post_define && functionp(post_define))
     post_define();
}

string describe_value(string key, mixed value, .DataObjectInstance|void i)
{
  return fields[key]->describe(value, i);
}

string describe(object i)
{
  mixed e = catch{
  if(!i[primary_key->name]) return ("unidentified");
  if(alternate_key)
    return (alternate_key->name + "=" + (string)i[alternate_key->name]);
  return (primary_key->name + "=" + i[primary_key->name]);
  };

  if(e) return "unidentified";
}

//!
.PrimaryKeyField get_primary_key()
{
  return primary_key;
}

//! define the object's fields and relationships
//! if not defined, the object will attempt to auto-configure itself
//! from the table definition. see the Fins automatic model configuration
//! documentation for details.
void define();

//! define the object's fields and relationships; useful for adding custom attributes
//! when also using automatic definition.
void post_define();

//! set the default operator to use when querying on multiple fields.
//!  valid values are @[Fins.Model.OPER_AND] and @[Fins.Model.OPER_OR].
void set_operator(int oper_type)
{
  if(oper_type == Fins.Model.OPER_AND)
    default_operator = " AND ";
  else if(oper_type == Fins.Model.OPER_OR)
    default_operator = " OR ";
}

//! validates the data being set for an object.
//! runs for each individual or atomic change. all applicable validation methods
//! will be called, and if any errors have been registered in the @[Fins.Errors.Validation]
//! object, the error object will be thrown.
//!
//! @param changes
//!  a mapping containing the field-value pairs changed.
//! @param errors
//!  a @[Fins.Errors.Validation] object that can be used to aggregate error messages
//!  by using the add() method.
//! @param i
//!  the DataInstanceObject being created or updated.
//!
void validate(mapping changes, Fins.Errors.Validation errors, .DataObjectInstance i);

//! validates the data being set for an object.
//! runs for each individual or atomic change on updates only. all applicable validation methods
//! will be called, and if any errors have been registered in the @[Fins.Errors.Validation]
//! object, the error object will be thrown.
//!
//! @param changes
//!  a mapping containing the field-value pairs changed.
//! @param errors
//!  a @[Fins.Errors.Validation] object that can be used to aggregate error messages
//!  by using the add() method.
//! @param i
//!  the DataInstanceObject being created or updated.
//!
void validate_on_update(mapping changes, Fins.Errors.Validation errors, .DataObjectInstance i);

//! validates the data being set for an object.
//! runs for atomic changes at object creation time. all applicable validation methods
//! will be called, and if any errors have been registered in the @[Fins.Errors.Validation]
//! object, the error object will be thrown.
//!
//! @param changes
//!  a mapping containing the field-value pairs changed.
//! @param errors
//!  a @[Fins.Errors.Validation] object that can be used to aggregate error messages
//!  by using the add() method.
//! @param i
//!  the DataInstanceObject being created or updated.
//!
void validate_on_create(mapping changes, Fins.Errors.Validation errors, .DataObjectInstance i);

static void reflect_definition()
{
  string instance =
             (replace(master()->describe_program(object_program(this)), ".", "/")/"/")[-1];

  if(!get_table_name() || !sizeof(get_table_name()))
  {
    string table = Tools.Language.Inflect.pluralize(lower_case(instance));
	Log.info("reflect_definition: table name for %s is %s.", instance, table);
    set_table_name(table);
    set_instance_name(instance);
    foreach(context->sql->list_fields(table);; mapping t)
    {
      mapping field = context->personality->map_field(t);

      Log.info("reflect_definition: looking at field %s: %O.", field->name, field);

      if(field->primary_key || (!primary_key && field->name =="id"))
      {
        // for now, primary keys must be integer.
        if(field->type!="integer") continue;

        Log.info("reflect_definition: have a primary key.");  
        add_field(.PrimaryKeyField(field->name));        
        set_primary_key(field->name);
      }

      else if(field->type != "integer" || search(field->name, "_")==-1)
        do_add_field(field);
      else  
      {
        Log.info("reflect_definition: have a possible link.");
        context->builder->possible_links += ({ (["obj": this, "field": field]) });
      }
    }
  }

  if(!primary_key) throw(Error.Generic("No primary key defined for " + instance_name + ".\n"));

}

void do_add_field(mapping field)
{
      if(field->type == "integer")
      {
        add_field(.IntField(field->name, field->length, !field->not_null, (int)field->default));
      }
      if(field->type == "timestamp")
      {
        add_field(.TimeStampField(field->name, 0));
      }
      else if(field->type == "date")
      {
        add_field(.DateField(field->name, !field->not_null, field->default));
      }
      else if(field->type == "datetime")
      {
        add_field(.DateTimeField(field->name, !field->not_null, field->default));
      }
      else if(field->type == "time")
      {
        add_field(.TimeField(field->name, !field->not_null, field->default));
      }
      else if(field->type == "string")
      {
        add_field(.StringField(field->name, field->length, !field->not_null, field->default));
      }
      else if(field->type == "binary_string")
      {
        add_field(.BinaryStringField(field->name, field->length, !field->not_null, field->default));
      }
   if(field->flags && field->flags->unique && ! alternate_key)
     set_alternate_key(field->name);
}

//! define a one to one relationship in which the local object has a field
//! which contains the id of instance of another data type. the reverse 
//! relationship can be defined in the other datatype using @[has_many].
//!
//! @param other_type
//!   the data type name (not the table name) of the type the field references.
//! @param my_name
//!   an optional attribute used to specify the name the object will be available
//!   as in the current object. The default, if not specified, is the name of the
//!   other type.
//! @param my_field
//!   an optional attribute that specifies the field in the table of the local
//!   datatype. if not specified, this defaults to the singular inflection of the
//!   other datatype, and the database field name of the other data type's primary
//!   key, separated by an underscore.
void belongs_to(string other_type, string|void my_name, string|void my_field)
{
  context->builder->belongs_to += ({ (["my_name": my_name, "other_type": other_type, "my_field": my_field, "obj": this]) });
}

//! define a one to many relationship in which the local object is referred to
//! by one or more objects of another datatype. this method defines the reverse of
//! @[belongs_to]. note that a datatype that uses this method won't have a field
//! in the corresponding "local" database table that contains the reference 
//! information. as a result, the parameters in this method don't use database
//! field names at all, unlink @[belongs_to].
//!
//! @param other_type
//!   pluralized version of the data type name (not the table name) of the type the field references.
//! @param my_name
//!   an optional attribute used to specify the name the object will be available
//!   as in the current object. The default, if not specified, is the pluralized name of the
//!   other type.
//!  @param other_field
//!   the name of the field in the other datatype (not a database field name) that
//!   represents the link to this data type. If you used @[belongs_to] and specified an alternate
//!   value for the my_name attribute, you'll need to provide that value to this parameter as well.
void has_many(string other_type, string|void my_name, string|void other_field)
{
  context->builder->has_many += ({ (["my_name": my_name, "other_type": other_type, "other_field": other_field, "obj": this]) });  
}

void add_ref(.DataObjectInstance o)
{
  // FIXME: we shouldn't have to do this in more than one location!
  if(!objs[o->get_id()])
  {
    objs[o->get_id()] = ({0, ([])});
  }

  objs[o->get_id()][0]++;
}

void sub_ref(.DataObjectInstance o)
{
  if(!o->is_initialized()) return;

  if(!objs[o->get_id()]) return;

  objs[o->get_id()][0]--;

  if(objs[o->get_id()][0] == 0)
  {
    m_delete(objs, o->get_id());
  }
}

//!
void set_instance_name(string _name)
{
  instance_name = _name;
}

string get_table_name()
{
  return table_name;
}

//!
void set_table_name(string _name)
{
  table_name = _name;
}

//!
void set_primary_key(string _key)
{
  if(!fields[_key])
    throw(Error.Generic("Primary key field " + _key + " does not exist.\n"));

  else primary_key = fields[_key];
}


//!
void set_alternate_key(string _key)
{
  if(!fields[_key])
    throw(Error.Generic("Primary key field " + _key + " does not exist.\n"));

  else alternate_key = fields[_key];
}

//! 
void add_default_value_object(string field, string objecttype, mapping criteria, int unique)
{
   if(unique)
     default_values[field] = lambda(){ return context->repository->find(objecttype, criteria)[0];};
   else
     default_values[field] = lambda(){ return context->repository->find(objecttype, criteria);};
}

//!
void add_field(.Field f)
{
   f->set_context(context);
   fields[f->name] = f;
   field_order += ({f});

   if(Program.inherits(object_program(f), .Relationship))
   {
     relationships[f->name] = f;
   }
}

array find(mapping qualifiers, .Criteria|void criteria, .DataObjectInstance i)
{
  string query;
  array(object(.DataObjectInstance)) results = ({});

  array _fields = ({});
  array _where = ({});
  array _tables = ({table_name});
  mapping _fieldnames = ([]);
  foreach(fields;; .Field f)
   if(f->field_name)
   {
      string mfn = table_name + "__" + f->field_name;
      _fields += ({ table_name + "." + f->field_name + " AS " + mfn});
      _fieldnames += ([f:mfn]);
   }

  foreach(qualifiers; mixed name; mixed q)
  {
     if(objectp(q) && Program.implements(object_program(q), .Criteria))
     {
         _where += ({ q->get(name, this) });
	if(q->get_table)
	  _tables += ({q->get_table(this)});
     }
     else if(objectp(name) && Program.implements(object_program(name), .MultiKeyReference))
     {
         _where += ({ name->get(q, i) });
	 if(name->get_table)
	   _tables += ({name->get_table(q, i)});
     }
     else if(!fields[name])
     {
        throw(Error.Generic("Field " + name + " does not exist in object " + instance_name + ".\n"));
     }
     else
     {
       _where += ({ fields[name]->make_qualifier(q)});
       if(objectp(name) && name->get_table)
         _tables += ({name->get_table(q, i)});
		 else if(fields[name]->get_table)
		{
			_tables += ({fields[name]->get_table(q, i)});
		}
     }
  }      

  if(_where && sizeof(_where)) 
    query = sprintf(multi_select_query, (_fields * ", "), 
      (Array.uniq(_tables) * ", "), (_where * default_operator));

  else
    query = sprintf(multi_select_nowhere_query, (_fields * ", "), 
      table_name);

  // criteria always overrides default sorting.
  if(criteria)
  {
     query += " " + criteria->get("", this);
  }
  else if(default_sort_fields)
  {
    if(!_default_sort_order_cached)
      generate_sort_order();	
    query += (" " + _default_sort_order_cached);
  }

  if(context->debug) werror("QUERY: %O\n", query);
  
  array qr = context->sql->query(query);

  foreach(qr;; mapping row)
  {
    string fn = table_name + "__" + primary_key->field_name;
    object item = object_program(i)(UNDEFINED, this);
    item->set_id(primary_key->decode(row[fn]));
    item->set_new_object(0);
    low_load(row, item, _fieldnames);
    add_ref(item);
    results+= ({ item  });
  }

  return results;
}

void generate_sort_order()
{
	string o = "ORDER BY ";
	array x = ({});
	foreach(default_sort_fields;; array f)
	{
		x += ({f[0] + " " + (f[1]==1?"ASC":"DESC")});
	}
	o += x*", ";
	
	_default_sort_order_cached = o;
}

void load(mixed id, .DataObjectInstance i, int|void force)
{

   if(force || !(id  && objs[id])) // not a new object, so there might be an opportunity to load from cache.
   {
     mapping _fieldnames = ([]);
     array _fields = ({});

     foreach(fields;; .Field f)
     {
       if(!f->field_name) continue;
       string mfn = (f->get_table?f->get_table():table_name) + "__" + f->field_name;
       _fieldnames[f] = mfn;
       _fields += ({ (f->get_table?f->get_table():table_name) + "." + f->field_name + " AS " + mfn});
     }      
     string query = sprintf(single_select_query, (_fields * ", "), 
       table_name, primary_key->field_name, primary_key->encode(id));

     if(context->debug) werror("QUERY: %O\n", query);

     array result = context->sql->query(query);

     if(sizeof(result) != 1)
     {
       	throw(Error.Generic("Unable to load " + instance_name + " id " + id + ".\n"));
     }
     else
       if(context->debug) werror("got results from query: %s\n", query);

     i->set_id(id);
     i->set_new_object(0);
     i->set_initialized(1);
     low_load(result[0], i, _fieldnames);
  }
  else // guess we need this here, also.
  {
     i->set_initialized(1);
     i->set_id(primary_key->decode(objs[id][1][primary_key->field_name]));
     i->set_new_object(0);
  }
}

void low_load(mapping row, .DataObjectInstance i, mapping|void fieldnames)
{
  mixed id = i->get_id();
  mapping r = ([]);
  int n = 0;
  foreach(fields; string fn; .Field f)
  {
    string fn;
    if(fieldnames && fieldnames[f] && f->field_name)
      fn = fieldnames[f];
    else if(f->get_table)
      fn = f->get_table()  + "." + f->field_name;
    else 
      fn = table_name + "." + f->field_name;
    r[f->name] = row[fn];
    n++;
  }
  if(!objs[id])
  {
    objs[id] = ({0, ([])});
  }



  objs[id][1] = r;

  return;
}

mapping get_atomic(.DataObjectInstance i)
{
  mapping a = ([]);

  foreach(fields;string n; object f )
  {
    a[f->name] = get(f->name, i);
  }

  return a;
}

mixed get(string field, .DataObjectInstance i)
{

   if(!fields[field])
   {
     throw(Error.Generic("Field " + field + " does not exist in " + instance_name + "\n"));
   }

   if(objs[i->get_id()] && has_index(objs[i->get_id()][1], field))
   {
     return fields[field]->decode(objs[i->get_id()][1][field], i);
   }     

   else if(i->is_new_object())
   {
     return i->object_data[field];
   }

   string query = sprintf(single_select_query, fields[field]->field_name, table_name, 
     primary_key->field_name, primary_key->encode(i->get_id()), i);

      if(context->debug) werror("QUERY: %O\n", query);

   mixed result = context->sql->query(query);

   if(sizeof(result) != 1)
   {
     throw(Error.Generic("Unable to obtain information for " + instance_name + " id " + i->get_id() + "\n"));
   }
   else 
   {
//	  werror("R: %O, %O\n", result[0], fields[field]->field_name);
     return fields[field]->decode(result[0][fields[field]->field_name], i);
   }
}

int set_atomic(mapping values, int|void no_validation, .DataObjectInstance i)
{
   mapping object_data = ([]);
   multiset fields_set = (<>);
   mixed key_value;

   foreach(values; string field; mixed value)
   {
      if(!fields[field])
      {
         throw(Error.Generic("Field " + field + " does not exist in object " + instance_name + ".\n"));   
      }
		if(Program.implements(object_program(fields[field]), .ObjectArray))
		{
			continue;
		}
      if(fields[field]->is_shadow)
      {
         throw(Error.Generic("Cannot set shadow field " + field + ".\n"));   
      }

       object_data[field] = fields[field]->validate(value);
       fields_set[field] = 1;      
   }

   if(i->is_new_object())
   {
      mixed key;
      commit_changes(fields_set, object_data, no_validation, 0, i);
      key = primary_key->get_id(i);
      i->set_id(key);
      i->set_new_object(0);
      i->set_saved(1);
      add_ref(i);
      i->object_data = ([]);
      i->fields_set = (<>);      
   }
   else
     commit_changes(fields_set, object_data, no_validation, i->get_id(), i);
   load(i->get_id(), i, 1);
}

int set(string field, mixed value, int|void no_validation, .DataObjectInstance i)
{
   if(!fields[field])
   {
      throw(Error.Generic("Field " + field + " does not exist in object " + instance_name + ".\n"));   
   }
   
	if(Program.inherits(object_program(fields[field]), .Relationship) && fields[field]->is_shadow)
	{
		return 0;
	}
	
   if(fields[field]->is_shadow)
   {
     throw(Error.Generic("Cannot set shadow field " + field + ".\n"));   
   }

   if(!i->is_new_object() && fields[field] == primary_key)
   {
      throw(Error.Generic("Cannot modify primary key field " + field + ".\n"));
   }
   
   if(!i->is_new_object() && autosave)
   {
     string new_value = fields[field]->encode(value);
     string key_value = primary_key->encode(i->get_id());

     if(!no_validation)
     {
       Fins.Errors.Validation er;

       // we need to validate against validates and validates_on_update
       if(validate && functionp(validate))
       {  
         if(!er)
           er = Fins.Errors.Validation("Data Validation Error\n");
         validate(([field: value]), er, i);
       }     
 
       if(validate_on_update && functionp(validate_on_update))
       {  
         if(!er)
           er = Fins.Errors.Validation("Data Validation Error\n");
         validate_on_update(([field: value]), er, i);
       }     

       if(er && sizeof(er->validation_errors()))
       {
          throw(er);
       }
     }

     string update_query = sprintf(single_update_query, table_name, fields[field]->field_name, new_value, primary_key->name, key_value);
     i->set_saved(1);
     if(context->debug) werror("QUERY: %O\n", update_query);
     context->sql->query(update_query);
     load(i->get_id(), i, 1);   
   }
   
   else
   {
     i->set_saved(0);
     i->object_data[field] = fields[field]->validate(value);
     i->fields_set[field] = 1;
   }
   
   return 1;
}

//! if we force, any objects that refer to us will also
//! be deleted, and so on. this is a very dangerous behavior
//! and could result in large numbers of records not directly 
//! related to this object being deleted.
int delete(int|void force, .DataObjectInstance i)
{
   // first, check to see what we link to.
   string key_value = primary_key->encode(i->get_id());

   // we need to check any relationships to see of we're referenced 
   // anywhere. this will be tricky, because we need to maintain
   // data integrity, but we also don't want to delete referenced records
   // inadvertently.   

   foreach(relationships; string n; .Relationship r)
   {
     if(Program.inherits(object_program(r), .InverseForeignKeyReference))
     {
       werror("%O is a link to this table's primary key\n", n);
       mixed m = get(n, i);
       if(m && sizeof(m) && !force) // this should work, because any object should have a size.
       {
         throw(Error.Generic("An object of type " + r->otherobject + " refers to this object.\n"));
       }
       else if(m && sizeof(m))
       {
         // we do the delete.
         if(Program.inherits(object_program(r), .DataObjectInstance))
         {
            m->delete(force-1);
         }
         if(Program.inherits(object_program(r), .ObjectArray))
         {
           foreach(m, object item)
             item->delete(force-1);
         }
       }
     }

     else if(Program.inherits(object_program(r), .MultiKeyReference))
     {
       foreach(get(n, i);; object mem)
         i[n]-=mem;
     }
   }
   
//   return 0;

   string delete_query = sprintf(single_delete_query, table_name, primary_key->name, key_value);

   if(context->debug) werror("QUERY: %O\n", delete_query);
   context->sql->query(delete_query);
   m_delete(objs, i->get_id());
   destruct(i);
   return 1;
}

static mapping mk_validate_fields(object i, multiset fields_set, mapping object_data)
{
  mapping vf = ([]);
  foreach(fields_set; string f;)
  { 
    vf[f] = object_data[f];
  }
  return vf;
}

Fins.Errors.Validation valid(object i)
{
   Fins.Errors.Validation er;
   mapping validate_fields;

   multiset fields_set = i->fields_set;
   mapping object_data = i->object_data;

   // we need to validate against validates and validates_on_update
   if(validate && functionp(validate))
   {  
     if(!er)
       er = Fins.Errors.Validation("Data Validation Error\n");
     if(!validate_fields)
       validate_fields = mk_validate_fields(i, fields_set, object_data);
     validate(validate_fields, er, i);
   }     

   if(!i->is_new_object())
     if(validate_on_update && functionp(validate_on_update))
     {  
       if(!er)
         er = Fins.Errors.Validation("Data Validation Error\n");
       if(!validate_fields)
         validate_fields = mk_validate_fields(i, fields_set, object_data);
       validate_on_update(validate_fields, er, i);
     }     
   else
     if(validate_on_create && functionp(validate_on_create))
     {  
       if(!er)
         er = Fins.Errors.Validation("Data Validation Error\n");
       if(!validate_fields)
         validate_fields = mk_validate_fields(i, fields_set, object_data);
       validate_on_create(validate_fields, er, i);
     }       

   if(er && sizeof(er->validation_errors()))
   {
     return er;
   }
   else return 0;
}

static int commit_changes(multiset fields_set, mapping object_data, int|void no_validation, mixed update_id, object i)
{
   string query;
   array qfields = ({});
   array qvalues = ({});

      Fins.Errors.Validation er;
   mapping validate_fields;

   // we need to validate against validates and validates_on_update
   if(!no_validation)
   {
     if(validate && functionp(validate))
     {  
       if(!er)
         er = Fins.Errors.Validation("Data Validation Error\n");
       if(!validate_fields)
         validate_fields = mk_validate_fields(i, fields_set, object_data);
       validate(validate_fields, er, i);
     }     

     if(update_id)
       if(validate_on_update && functionp(validate_on_update))
       {  
         if(!er)
           er = Fins.Errors.Validation("Data Validation Error\n");
         if(!validate_fields)
           validate_fields = mk_validate_fields(i, fields_set, object_data);
         validate_on_update(validate_fields, er, i);
       }     
     else
       if(validate_on_create && functionp(validate_on_create))
       {  
         if(!er)
           er = Fins.Errors.Validation("Data Validation Error\n");
         if(!validate_fields)
           validate_fields = mk_validate_fields(i, fields_set, object_data);
         validate_on_create(validate_fields, er, i);
       }       

     if(er && sizeof(er->validation_errors()))
     {
        throw(er);
     }
   }

      foreach(fields;; .Field f)
      {
         if(f->is_shadow) continue;  // We just skip right over "shadow" fields.

         if(update_id && fields_set[f->name] && f == primary_key)
         {
            throw(Error.Generic("Changing id for " + instance_name + " not allowed for existing objects.\n"));
         }
         else if(update_id && f == primary_key)
         {
            // we can skip the primary key for existing objects.
         }
         else if(!fields_set[f->name] && default_values[f->name])
         {
            qfields += ({f->field_name});
            qvalues += ({f->encode(default_values[f->name]())});
         }
         // have we set nothing, and are allowed to?
         // if we're updating, it's not required.
         else if((!fields_set[f->name] && f->null) || 
                    (!fields_set[f->name] && update_id))
         {
         }
         else if(!fields_set[f->name] && !f->null)
         {
            qfields += ({f->field_name});
            qvalues += ({f->encode(.Undefined)});
         }
         else
         {
            qfields += ({f->field_name});
            qvalues += ({f->encode(object_data[f->name])});
         }
      }
      
      if(!update_id)
      {
         string fields_clause = "(" + (qfields * ", ") + ")";
         string values_clause = "(" + (qvalues * ", ") + ")";

         query = sprintf(insert_query, table_name, fields_clause, values_clause);
         if(context->debug) werror("QUERY: %O\n", query);
      }
      else
      {
         array set = ({});
         string set_clause = "";
         
         foreach(qfields; int i; string n)
         {
            set += ({ n + "=" + qvalues[i]});
         }

         set_clause = (set * ", ");
         
         query = sprintf(multi_update_query, table_name, set_clause, primary_key->field_name, primary_key->encode(update_id));
         if(context->debug) werror("QUERY: %O\n", query);
      }
      context->sql->query(query);
}

int save(int|void no_validation, .DataObjectInstance i)
{   
   if(i->is_new_object())
   {
      mixed key;
      commit_changes(i->fields_set, i->object_data, no_validation, 0, i);
      key = primary_key->get_id(i);
      i->set_id(key);
      i->set_new_object(0);
      i->set_saved(1);
      add_ref(i);
      i->object_data = ([]);
      i->fields_set = (<>);      
   }
   else if(autosave == 0)
   {
      commit_changes(i->fields_set, i->object_data, no_validation, i->get_id(), i);
      i->set_id(primary_key->get_id(i));
      i->set_saved(1);
      i->object_data = ([]);
      i->fields_set = (<>);            
   }
   else
   {
      throw(Error.Generic("Cannot save() when autosave is enabled.\n"));
   }

   load(i->get_id(), i, 1);
}
