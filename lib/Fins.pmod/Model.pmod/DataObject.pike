//! This is an object that defines a Model-domain Data Mapping for a given table/data type.
//! This class is singleton for a given data type. Use a DataObjectInstance object to 
//! retrieve data for a given data type.
//! 
//! The Fins model builder utility (pike -x fins model) will create the appropriate Pike 
//! module to contain the data mappings as well as any data mapping classes needed for
//! a given database. The default mapping module for the "default" model definition
//! is "Appname.DataMappings," for additional model definitions, the base module name is
//! specified in the "definition_module" configuration attribute of the model definition.
//! For example, if the model definition section specifies "ExternalDB" as the value of the
//! "definition_module" attribute, the data mapping classes would be stored in the module
//! "ExternalDB.DataMappings."
//!
//! Models are configured by @[Fins.FinsModel], using either database reflection or by 
//! implementing the @[define] method. By default, an object that inherits this class will 
//! automatically configure the mapping based on its name. For instance, a class named "User" 
//! will be configured from a table called "users" in the specified database. If this 
//! mapping were configured for the "default" model definition, this would be 
//! "Appname.DataMappings.User."
//! 

object log = Tools.Logging.get_logger("model.dataobject");

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

int is_base=1;

//!
.Field primary_key;

//!
.Field alternate_key;

//!
.Repository repository; 

object my_undef = .Undefined;

//!
mapping|Tools.Mapping.MappingCache  _objs = ([]);
mapping|Tools.Mapping.MappingCache  _objs_by_alt = ([]);

//! contains the list of field mappings. normally, this mapping should not be modified directly; use @[add_field] instead.
mapping(string:.Field) fields = ([]);

static  array _fields = ({});
static  mapping _fieldnames = ([]);
static  mapping _fieldnames_low = ([]);
static  string _fields_string = "";

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

//! used by @[Fins.ScaffoldController] to determine the order fields are displayed in generated forms.
array(.Field) field_order = ({});

//! repo is retained, context is not. Data mapping objects that inherit this type are
//! automatically created by the model configuration mechanism provided by @[Fins.FinsModel].
void create(.DataModelContext context, .Repository repo)
{
  repository = repo;

   if(define && functionp(define))
   {
     define(context);
   }
   else
   { 
     reflect_definition(context);
   }

   set_weak_flag(_objs, Pike.WEAK);
   set_weak_flag(_objs_by_alt, Pike.WEAK);

   if(post_define && functionp(post_define))
     post_define(context);

   gen_fields();

}

//! enables or disables autosave of objects.
//!
//! if autosave is enabled, each set of a field will result in
//! the data being instantly saved to the database. in this situation,
//! use @[set_atomic] to change multiple fields simultaneously.
//!
//! if disabled, changes will be stored until the changes are commited
//! using the @[save] function.
void set_autosave(int(0..1) enabled)
{
  autosave = enabled;
}

//! sets the cache period for objects of this data type.
//! 
//! Queries for objects by id (primary key) or by alternate key will consult the
//! data cache before querying the database. 
//! 
//! By default, values for each data object (database row) are cached until all 
//! objects using them are destroyed, at which point the data will be  eligible 
//! for expiration at the next garbage collection interval.
//!
//! @param timeout
//!  the number of seconds values for an object should be cached before a 
//!  reload from the database is forced.
void set_cacheable(int timeout)
{
  if(timeout)
  {
    _objs = Tools.Mapping.MappingCache(timeout);
    _objs_by_alt = Tools.Mapping.MappingCache(timeout);
  }
  else  
  {
    _objs = ([]);
    set_weak_flag(_objs, Pike.WEAK);
    _objs_by_alt = ([]);
    set_weak_flag(_objs_by_alt, Pike.WEAK);
  }
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
    return (string)i[alternate_key->name];
  return (primary_key->name + "=" + i[primary_key->name]);
  };

  if(e) return "unidentified";
}

//! @returns
//! the primary key field object for this data type.
.PrimaryKeyField get_primary_key()
{
  return primary_key;
}

//! define the object's fields and relationships
//! if not defined, the object will attempt to auto-configure itself
//! from the table definition. see the Fins automatic model configuration
//! documentation for details.
void define(.DataModelContext context);

//! define the object's fields and relationships; useful for adding custom attributes
//! when also using automatic definition. If defined, this method will be called
//! whether using automatic or manual configuration.
void post_define(.DataModelContext context);

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
//!
//! runs for each individual or atomic change. If defined, this method will be called
//! for creation and update events regardless of whether @[validate_on_update] or 
//! @[validate_on_create] are defined. If any validation errors have been registered in 
//! the @[Fins.Errors.Validation] object passed as the second argument, the error object 
//! will be thrown.
//!
//! @param changes
//!  a mapping containing the field-value pairs changed.
//! @param errors
//!  a @[Fins.Errors.Validation] object that can be used to aggregate error messages
//!  by using the add() method.
//! @param i
//!  the @[DataInstanceObject] being created or updated.
//!
void validate(mapping changes, Fins.Errors.Validation errors, .DataObjectInstance i);

//! validates the data being set for an object.
//!
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
//!  the @[DataInstanceObject] being created or updated.
//!
void validate_on_update(mapping changes, Fins.Errors.Validation errors, .DataObjectInstance i);

//! validates the data being set for an object.
//!
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
//!  the @[DataInstanceObject] being created or updated.
//!
void validate_on_create(mapping changes, Fins.Errors.Validation errors, .DataObjectInstance i);

static void reflect_definition(.DataModelContext context)
{
  string instance =
             (replace(master()->describe_program(object_program(this)), ".", "/")/"/")[-1];

  if(!get_table_name() || !sizeof(get_table_name()))
  {
    string table = Tools.Language.Inflect.pluralize(lower_case(instance));
	log->info("reflect_definition: table name for %s is %s.", instance, table);
    set_table_name(table);
    set_instance_name(instance);
    foreach(context->personality->list_fields(table);; mapping field)
    {
//      mapping field = context->personality->map_field(t, table);

      log->debug("reflect_definition: looking at field %s: %O.", field->name, field);

      if(field->primary_key || (!primary_key && field->name =="id"))
      {
        // for now, primary keys must be integer.
        if(field->type!="integer") continue;

        log->debug("reflect_definition: have a primary key.");  
        add_field(context, field->type_class||.PrimaryKeyField(field->name));        
        set_primary_key(field->name);
      }

      else if(field->type != "integer" || search(field->name, "_")==-1)
        do_add_field(context, field);
      else  
      {
        log->debug("reflect_definition: have a possible link.");
        context->builder->possible_links += ({ (["obj": this, "field": field]) });
      }
    }
  }

  if(!primary_key) throw(Error.Generic("No primary key defined for " + instance_name + ".\n"));

}

void do_add_field(.DataModelContext context, mapping field)
{
  // some default values are returned from the database already quoted. we want to remove that.
  if(field->default && stringp(field->default) && has_prefix(field->default, "'") && has_suffix(field->default, "'"))
    sscanf(field->default, "'%s'", field->default);

  log->debug("adding field %O.", field);
      if(field->type == "integer")
      {
        add_field(context, (field->type_class||.IntField)(field->name, field->length, !field->not_null, 		
			field->default?(int)field->default:Fins.Model.Undefined));
      }
      if(field->type == "float")
      {
        add_field(context, (field->type_class||.FloatField)(field->name, field->length, !field->not_null, field->default?(float)field->default:0));
      }
      if(field->type == "timestamp")
      {
        add_field(context, (field->type_class||.TimeStampField)(field->name, 0));
      }
      else if(field->type == "date")
      {
        add_field(context, (field->type_class||.DateField)(field->name, !field->not_null, field->default));
      }
      else if(field->type == "datetime")
      {
        add_field(context, (field->type_class||.DateTimeField)(field->name, !field->not_null, field->default));
      }
      else if(field->type == "time")
      {
        add_field(context, (field->type_class||.TimeField)(field->name, !field->not_null, field->default));
      }
      else if(field->type == "string")
      {
        add_field(context, (field->type_class||.StringField)(field->name, field->length, !field->not_null, field->default));
      }
      else if(field->type == "binary_string")
      {
        add_field(context, (field->type_class||.BinaryStringField)(field->name, field->length, !field->not_null, field->default));
      }
   if(field->unique && ! alternate_key)
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
void belongs_to(.DataModelContext context, string other_type, string|void my_name, string|void my_field, mapping|void args)
{
  context->builder->belongs_to += ({ (["my_name": my_name, "other_type": other_type, "my_field": my_field, "obj": this, "nullable": args?args->nullable:0]) });
}

//! define a one to many relationship in which the local object is referred to
//! by one or more objects of another datatype. this method defines the reverse of
//! @[belongs_to]. note that a datatype that uses this method won't have a field
//! in the corresponding "local" database table that contains the reference 
//! information. as a result, the parameters in this method don't use database
//! field names at all, unlike @[belongs_to].
//!
//! @param other_type
//!   data type name (not the table name) of the type the field references.
//! @param my_name
//!   an optional attribute used to specify the name the object will be available
//!   as in the current object. The default, if not specified, is the pluralized name of the
//!   other type.
//!  @param other_field
//!   the name of the field in the other datatype (not a database field name) that
//!   represents the link to this data type. If you used @[belongs_to] and specified an alternate
//!   value for the my_name attribute, you'll need to provide that value to this parameter as well.
void has_many(.DataModelContext context, string other_type, string|void my_name, string|void other_field)
{
  context->builder->has_many += ({ (["my_name": my_name, "other_type": other_type, "other_field": other_field, "obj": this]) });  
}

//! define a one to many relationship in which the local object is referred to
//! by one or more objects of another datatype. the related objects will be placed in
//! a mapping based on the value of the index field. this method defines (a variation on)
//! the reverse of @[belongs_to]. note that a datatype that uses this method won't have 
//! a field in the corresponding "local" database table that contains the reference 
//! information. as a result, the parameters in this method don't use database
//! field names at all, unlike @[belongs_to].
//!
//! @param other_type
//!   data type name (not the table name) of the type the field references.
//!  @param index_field
//!    the field that supplies the value that the records will be indexed on.
//! @param my_name
//!   an optional attribute used to specify the name the object will be available
//!   as in the current object. The default, if not specified, is the pluralized name of the
//!   other type.
//!  @param other_field
//!   the name of the field in the other datatype (not a database field name) that
//!   represents the link to this data type. If you used @[belongs_to] and specified an alternate
//!   value for the my_name attribute, you'll need to provide that value to this parameter as well.
void has_many_by_index(.DataModelContext context, string other_type, string index_field, string|void my_name, string|void other_field)
{
  context->builder->has_many_index += ({ (["my_name": my_name, "other_type": other_type, "other_field": other_field, "index_field": index_field, "obj": this]) });  
}

//!  define a many to many relationship in which the local object can be linked to many other objects
//!  and vice versa. this requires the use of a join table with two fields: one to contain the id
//!  of each type being linked. Each of the two types will have an attribute that returns the 
//!  result of this many-to-many mapping, which we refer to as "this" and "that".
//!
//!  @param join_table
//!    the name of the table containing the relationship. typically named in the
//!    form of typeas_typebs.
//!  @param that_type
//!    the name of the other type in the relationship (this being the other).
//!  @param this_name
//!    the name of the attribute object to be used. often, this is the name of this type.
//!  @param that_name
//!    the name of the attribute object to be used. often, this is the name of that type.
//!
//!  @example
//!  // assume we have a field called lists_owners that contains a many-to-many
//!  // mapping of shopping lists to their owners. The data type for this type is "List"
//!  // and the type of the other object is "User". The type of entity for each 
//!  // is "owned_list" and "list_owner", respectively. This will result in the List type
//!  // having an attribute called "list_owners" and the "User" type will have one called
//!  // owned_lists.
//!  //
//!  // the table will have 2 fields, called user_id (assuming the primary key of the users
//!  // table is "id" and one called list_id. 
//!  has_many_to_many("lists_owners", "User", "owned_list", "list_owner");
//!
//!  @note
//!   it's only necessary to include a call to this method in one of the types in the relation
//!   though doing so in both (with the appropriate values for each) will not cause harm.
//!
//!  @note
//!   if standard naming practices are employed for table names and field names, use of this
//!   method is typically not necessary, as the auto configuration process will detect this.
//!  
//!   this function is typically most useful if you want to have multiple many-to-many
//!   relationships that have unique table or attribute names in the resulting objects.
void has_many_to_many(.DataModelContext context, string join_table, string that_type, string this_name, string that_name)
{
  context->builder->has_many_many += ({ (["join_table": join_table, "this_type": this, 
                           "that_type": that_type,
                           "this_name": this_name, "that_name": that_name ]) });
}

void add_ref(.DataObjectInstance o)
{
// werror("add_ref(%O)\n", o);
}

//! sets the instance name of this data mapping (typically the class name)
void set_instance_name(string _name)
{
  instance_name = _name;
}

//! @returns
//!  the name of the database table this data type maps to.
string get_table_name()
{
  return table_name;
}

//! sets the name of the database table this data type maps to.
void set_table_name(string _name)
{
  table_name = _name;
}

//! specifies the name of the primary key field, using the Pike-name of the 
//! field, if it differs from that defined in the database.
void set_primary_key(string _key)
{
  if(!fields[_key])
    throw(Error.Generic("Primary key field " + _key + " does not exist.\n"));

  else primary_key = fields[_key];
}


//! sets the alternate key field to be used for this data type. Specify using the Pike-name
//! of the field, if it differs from that defined in the database.
//! 
//! any alternate keys should be deined as UNIQUE key fields in the corresponding database table.
void set_alternate_key(string _key)
{
  if(!fields[_key])
    throw(Error.Generic("Primary key field " + _key + " does not exist.\n"));

  else alternate_key = fields[_key];
}

//! specify that the default value for a given field should be the result of a search
//! for an object of a particular objecttype.
void add_default_value_object(.DataModelContext context, string field, string objecttype, mapping criteria, int unique)
{
   if(unique)
     default_values[field] = lambda(){ return context->old_find(objecttype, criteria)[0];};
   else
     default_values[field] = lambda(){ return context->old_find(objecttype, criteria);};
}

//! specify the default value for a given field. if value is a function, this will be called and the
//! returned value will be used to set the value of the field.
void add_default_value(.DataModelContext context, string field, mixed value)
{
  default_values[field] = value;
}

//! add a mapping of a Pike-name index in the data object to (typically) a
//! field in the database table for this type.
//! 
//! overwrites the field definition if it already exists.
void add_field(.DataModelContext context, .Field f, int|void force)
{
   if(fields[f->name] && !force) 
   {
	 log->info("Ignoring attempt to add existing field " + f->name +".");
     return;	
   }
   f->set_context(context);
   fields[f->name] = f;
   field_order += ({f});

   if(Program.inherits(object_program(f), .Relationship))
   {
     relationships[f->name] = f;
   }

}

mixed gen_inherits(object definition)
{
	// we need to check to see if there are any inherited types.
    foreach(Program.all_inherits(object_program(definition));;program parent)
    {
	  // if the parent class is data object, don't investigate it, as it won't have any fields defined.
	  if(parent == Fins.Model.DataObject) continue;
	
	  
	  mixed r = search(context->repository->program_definitions, parent);
	  if(objectp(r) && Program.inherits(parent))
	  {
	     log->info("%O has %O as a parent.\n", definition, r);
	  }
    }
    
}

 string gen_fields()
{
  string fn;

  _fields = ({});
  _fieldnames = ([]);
  _fieldnames_low = ([]);

   gen_inherits(this);

     foreach(fields;; .Field f)
     {
       string mfn = (f->get_table?f->get_table():table_name) + "__" + f->field_name;
       if(f->field_name)
       {
         _fieldnames[f] = mfn;
         _fields += ({ (f->get_table?f->get_table():table_name) + "." + f->field_name + " AS " + mfn});
         fn = mfn;
       }

      else {
        if(f->get_table)
          fn = f->get_table()  + "." + f->field_name;
        else 
          fn = table_name + "." + f->field_name;
      }

      _fieldnames_low[f->name] = fn;

   }      

  return _fields_string = (_fields * ", ");
}

//! perform a query
//!
//! @note
//!   this method is not normally called by end-user code.
//!
//! @param qualifiers
//!   a mapping containing a series of field -> value pairs.
//!   if the value of a given field -> value pair is a @[Criteria] object,
//!   the criteria object will determine the type of comparison made for 
//!   the field, otherwise the criteria will be an equality comparison on the
//!   value (as in the SQL: field1='value' if the field field1 were a string type)
array find(.DataModelContext context, mapping qualifiers, .Criteria|void criteria, .DataObjectInstance i)
{
  string query;
  array(object(.DataObjectInstance)) results = ({});

  array _where = ({});
  array _tables = ({table_name});

  //werror("%O via %O (%O, %O, %O)", Tools.Function.this_function(), backtrace()[-4][2], qualifiers, criteria, i);

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
    query = sprintf(multi_select_query, _fields_string, 
      (Array.uniq(_tables) * ", "), (_where * default_operator));

  else
    query = sprintf(multi_select_nowhere_query, _fields_string, 
      table_name);

  // criteria always overrides default sorting.
  if(criteria)
  {
     query += " " + criteria->get("", i);
  }
  else if(default_sort_fields)
  {
    if(!_default_sort_order_cached)
      generate_sort_order();	
    query += (" " + _default_sort_order_cached);
  }

  if(context->debug) log->debug("%O: %O\n", Tools.Function.this_function(), query);
  
  array qr = context->sql->query(query);


  mapping objs, objs_by_alt;

  if(context->in_xa)
  {
    objs = context->xa_storage[instance_name];      
    if(!objs) objs = context->xa_storage[instance_name] = ([]);

    objs_by_alt = context->xa_storage[instance_name + "_by_alt"];      
    if(!objs_by_alt) objs_by_alt = context->xa_storage[instance_name + "_by_alt"] = ([]);
  }
  else
  {
    objs_by_alt = _objs_by_alt;
    objs = _objs;
  }

  foreach(qr;; mapping row)
  {
    string fn = table_name + "__" + primary_key->field_name;
    object item = object_program(i)(UNDEFINED, context);
    item->set_id(primary_key->decode(row[fn]));
    item->set_new_object(0);
    low_load(row, item, objs, objs_by_alt);
//    add_ref(item);
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

int(0..1) load(.DataModelContext context, mixed id, .DataObjectInstance i, int|void force)
{
   // NOTE: zero is an invalid id... we use it to refer to a key reference that hasn't been set.

mapping objs, objs_by_alt;

   if(context->debug)
     log->debug("%O: loading object with id=%O, force=%d", Tools.Function.this_function(), id, force);

   if(!id) return 0;

if(context->in_xa)
{
  objs = context->xa_storage[instance_name];      
  if(!objs) objs = context->xa_storage[instance_name] = ([]);

  objs_by_alt = context->xa_storage[instance_name + "_by_alt"];      
  if(!objs_by_alt) objs_by_alt = context->xa_storage[instance_name + "_by_alt"] = ([]);
}
else
{
  objs_by_alt = _objs_by_alt;
  objs = _objs;
}

   if(context->debug)
     log->debug("%O: must ask db? %O\n", Tools.Function.this_function(), force || !(id && objs[id]));

   if(force || !(id  && objs[id])) // not a new object, so there might be an opportunity to load from cache.
   {
     string query = sprintf(single_select_query, (_fields_string), 
       table_name, primary_key->field_name, primary_key->encode(id, i));

     if(context->debug) log->debug("%O: %O", Tools.Function.this_function(), query);

     array result = context->sql->query(query);

     if(!sizeof(result) )
     {
        throw(Fins.Errors.RecordNotFoundError("Unable to load " + instance_name + " id " + id + ".\n"));
     }
     else if(sizeof(result) > 1)
     {
        throw(Fins.Errors.DataIntegrityError("Data Integrity Error: Unable to load unique row for " + instance_name + " id " + id + ".\n"));
     }

//     else
//       if(context->debug) werror("got results from query: %s\n", query);
     if(!result[0]) return 0;

     i->set_id(id);
     i->set_new_object(0);
     i->set_initialized(1);
     low_load(result[0], i, objs, objs_by_alt);
  }
  else // guess we need this here, also.
  {
     i->set_initialized(1);
     i->set_id(primary_key->decode(objs[id][primary_key->field_name]));
     i->set_new_object(0);
     i->object_data_cache = objs[i->get_id()];
  }

  return 1;
}

int(0..1) load_alternate(.DataModelContext context, mixed id, .DataObjectInstance i, int|void force)
{
mapping objs, objs_by_alt;

if(context->in_xa)
{
  objs = context->xa_storage[instance_name];      
  if(!objs) objs = context->xa_storage[instance_name] = ([]);

  objs_by_alt = context->xa_storage[instance_name + "_by_alt"];      
  if(!objs_by_alt) objs_by_alt = context->xa_storage[instance_name + "_by_alt"] = ([]);
}
else
{
  objs_by_alt = _objs_by_alt;
  objs = _objs;
}

   if(force || !(id  && objs_by_alt[id])) // not a new object, so there might be an opportunity to load from cache.
   {
     log->debug("load_alternate(%O, %O): loading from database.", id, i);

     string query = sprintf(single_select_query, (_fields_string), 
       table_name, alternate_key->field_name, alternate_key->encode(id, i));

  if(context->debug) log->debug("%O: %O\n", Tools.Function.this_function(), query);


     array result = context->sql->query(query);

     if(!sizeof(result) )
     {
       	throw(Fins.Errors.RecordNotFoundError("Unable to load " + instance_name + " id " + id + ".\n"));
     }
     else if(sizeof(result) > 1)
     {
       	throw(Fins.Errors.DataIntegrityError("Data Integrity Error: Unable to load unique row for " + instance_name + " id " + id + ".\n"));
     }
//     else
//       if(context->debug) werror("got results from query: %s\n", query);

     //werror("RESULT: %O, %O\n", result[0], _fieldnames);
     if(!result[0]) return 0;

     i->set_id(primary_key->decode(result[0][_fieldnames[primary_key]]));
     i->set_new_object(0);
     i->set_initialized(1);
     low_load(result[0], i, objs, objs_by_alt);
  }
  else // guess we need this here, also.
  {
     i->set_initialized(1);
     i->set_id(primary_key->decode(objs_by_alt[id][primary_key->field_name]));
     i->set_new_object(0);
     i->object_data_cache = objs_by_alt[i->get_id()];
  }

  return 1;
}

static void low_load(mapping row, .DataObjectInstance i, mapping objs, mapping objs_by_alt)
{
  mixed id = i->get_id();
  if(!objs[id]) objs[id] = ([]);
  mapping r = objs[id];
  int n = 0;
    
  foreach(_fieldnames_low; string fn; string fnl)
  {  
     r[fn] = row[fnl];
  }

  i->object_data_cache = r;
  if(alternate_key)
    objs_by_alt[r[alternate_key->name]] = r;
  return;
}

mapping get_atomic(.DataModelContext context, .DataObjectInstance i)
{
  mapping a = ([]);

  foreach(fields;string n; object f )
  {
    a[f->name] = get(context, f->name, i);
  }

  return a;
}

mixed get(.DataModelContext context, string field, .DataObjectInstance i)
{
  mapping objs, objs_by_alt;

  if(context->debug) log->debug("%O(%O, %O, %O)", Tools.Function.this_function(), context, field, i);

  if(field == "_id")
    field = primary_key->name;

  if(!fields[field])
  {
    throw(Error.Generic("Field " + field + " does not exist in " + instance_name + "\n"));
  }

  int id = i->get_id();
//	 if(context->debug) log->debug("%O(): field is %O: %O.", Tools.Function.this_function(), fields[field], objs[id]);	  


  if(context->in_xa)
  {
    objs = context->xa_storage[instance_name];      
    if(!objs) objs = context->xa_storage[instance_name] = ([]);

    objs_by_alt = context->xa_storage[instance_name + "_by_alt"];      
    if(!objs_by_alt) objs_by_alt = context->xa_storage[instance_name + "_by_alt"] = ([]);
  }
  else
  {
    objs_by_alt = _objs_by_alt;
    objs = _objs;
  }

  if(objs[id] && has_index(objs[id], field))
  {
//	 if(context->debug) log->debug("%O: have field in cache: %O.", Tools.Function.this_function(), objs[id][field]);
    return fields[field]->decode(objs[id][field], i);
  }     

  else if(i->is_new_object())
  {
//	 if(context->debug) log->debug("%O(): have field in new object cache.", Tools.Function.this_function());
    return i->object_data[field];
  }

  if(context->debug) log->debug("%O(): loading data from db.", Tools.Function.this_function());
    load(context, id, i, 0);

  if(objs[id])
  {
//	 if(context->debug) log->debug("%O(): have field in cache.", Tools.Function.this_function());
    return fields[field]->decode(objs[id][field], i);
  }     
  else 
  {
    werror("Error finding data for id %O; Here's the cache: %O\n\n %O\n", id, objs, fields);
    throw(Error.Generic("get failed on object without a data cache.\n"));
  }

/*
   string query = sprintf(single_select_query, fields[field]->field_name, table_name, 
     primary_key->field_name, primary_key->encode(id, i));

  if(context->debug) log->debug("%O(): %O\n", Tools.Function.this_function(), query);

   mixed result = context->sql->query(query);

   if(sizeof(result) != 1)
   {
     throw(Error.Generic("Unable to obtain information for " + instance_name + " id " + id + "\n"));
   }
   else 
   {
//	  werror("R: %O, %O\n", result[0], fields[field]->field_name);
     return fields[field]->decode(result[0][fields[field]->field_name], i);
   }
*/
}

int set_atomic(.DataModelContext context, mapping values, int|void no_validation, .DataObjectInstance i)
{
   mapping object_data = ([]);
   multiset fields_set = (<>);

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
      commit_changes(context, fields_set, object_data, no_validation, 0, i);
      key = primary_key->get_id(i);
      if(context->debug)
        log->debug("%O: created new object with id=%O\n", Tools.Function.this_function(), key);
      i->set_id(key);
      i->set_new_object(0);
      i->set_saved(1);
      i->object_data = ([]);
      i->fields_set = (<>);      
      //add_ref(i);
   }
   else
     commit_changes(context, fields_set, object_data, no_validation, i->get_id(), i);
   load(context, i->get_id(), i, 1);
}

int set(.DataModelContext context, string field, mixed value, int|void no_validation, .DataObjectInstance i)
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
     string new_value = fields[field]->encode(value, i);
     string key_value = primary_key->encode(i->get_id(), i);

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
  if(context->debug) log->debug("%O: %O\n", Tools.Function.this_function(), update_query);
     context->sql->query(update_query);
     load(context, i->get_id(), i, 1);   
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
int delete(.DataModelContext context, int|void force, .DataObjectInstance i)
{
mapping objs, objs_by_alt;

   // first, check to see what we link to.
   string key_value = primary_key->encode(i->get_id(), i);

   mixed _id, _alt;

  _id = i->get_id();
  _alt = i->get_alt();

   // we need to check any relationships to see of we're referenced 
   // anywhere. this will be tricky, because we need to maintain
   // data integrity, but we also don't want to delete referenced records
   // inadvertently.   

   foreach(relationships; string n; .Relationship r)
   {
     if(Program.inherits(object_program(r), .InverseForeignKeyReference))
     {
       werror("%O is a link to this table's primary key\n", n);
       mixed m = get(context, n, i);
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
       foreach(get(context, n, i);; object mem)
         i[n]-=mem;
     }
   }
   
//   return 0;

   string delete_query = sprintf(single_delete_query, table_name, primary_key->name, key_value);

  if(context->debug) log->debug("%O: %O\n", Tools.Function.this_function(), delete_query);
   context->sql->query(delete_query);


if(context->in_xa)
{
  objs = context->xa_storage[instance_name];      
  if(!objs) objs = context->xa_storage[instance_name] = ([]);

  objs_by_alt = context->xa_storage[instance_name + "_by_alt"];      
  if(!objs_by_alt) objs_by_alt = context->xa_storage[instance_name + "_by_alt"] = ([]);
}
else
{
  objs_by_alt = _objs_by_alt;
  objs = _objs;
}
   m_delete(objs, _id);
   m_delete(objs_by_alt, _alt);
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

//! performs validation checking on the object without performing any database operations.
//! useful for determining whether a save or update would be successful.
//! 
//! this method does not verify that the changed data would be acceptable outside the scope of
//! the validation functions. for example, this function will not check that dates are used
//! to set date fields and so on.
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

static int commit_changes(.DataModelContext context, multiset fields_set, mapping object_data, int|void no_validation, mixed update_id, object i)
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
         else if(!has_index(fields_set, f->name) && default_values[f->name])
         {
	        //if(context->debug)
			//log->debug("encode field %s using default value %O to %O", f->name, object_data[f->name],f->encode(default_values[f->name](), i));
            mixed ev;
            if(functionp(default_values[f->name]))
              ev = f->encode(default_values[f->name](), i);
            else ev = f->encode(default_values[f->name], i);
  	    if(ev)
	    {
              qfields += ({f->field_name});
              qvalues += ({ev});
	    }
         }
         // have we set nothing, and are allowed to?
         // if we're updating, it's not required.
         else if((!has_index(fields_set, f->name) && f->null) || 
                    (!fields_set[f->name] && update_id))
         {
	     //if(context->debug)
		 //	log->debug("skipping field %s", f->name);
         }
         else if(!has_index(fields_set, f->name) && !f->null)
         {
	     //if(context->debug)
		 //	log->debug("encode field %s zero value %O to %O", f->name, object_data[f->name], f->encode(.Undefined));
		   string ev = f->encode(.Undefined, i);
		   if(ev)
		   {
             qfields += ({f->field_name});
             qvalues += ({ev});
           }
         }
         else
         {
			string ev = f->encode(object_data[f->name], i);
			if(ev)
			{
	      //if(context->debug)
		  //	log->debug("encode field %s value %O to %O\n", f->name, object_data[f->name], f->encode(object_data[f->name]));
              qfields += ({f->field_name});
              qvalues += ({ev});
            }
         }
      }
      
      if(!update_id)
      {
         string fields_clause = "(" + (qfields * ", ") + ")";
         string values_clause = "(" + (qvalues * ", ") + ")";

         query = sprintf(insert_query, table_name, fields_clause, values_clause);

  		 if(context->debug) log->debug("%O: %O\n", Tools.Function.this_function(), query);
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
         
         query = sprintf(multi_update_query, table_name, set_clause, primary_key->field_name, primary_key->encode(update_id, i));
  if(context->debug) log->debug("%O: %O\n", Tools.Function.this_function(), query);
      }
      context->sql->query(query);
}

int save(.DataModelContext context, int|void no_validation, .DataObjectInstance i)
{   
   if(i->is_new_object())
   {
      mixed key;
      commit_changes(context, i->fields_set, i->object_data, no_validation, 0, i);
      key = primary_key->get_id(i);
      if(context->debug)
        log->debug("%O: created new object with id=%O\n", Tools.Function.this_function(), key);

      i->set_id(key);
      i->set_new_object(0);
      i->set_saved(1);
      //add_ref(i);
      i->object_data = ([]);
      i->fields_set = (<>);      
   }
   else if(autosave == 0)
   {
      commit_changes(context, i->fields_set, i->object_data, no_validation, i->get_id(), i);
      i->set_id(primary_key->get_id(i));
      i->set_saved(1);
      i->object_data = ([]);
      i->fields_set = (<>);            
   }
   else
   {
      throw(Error.Generic("Cannot save() when autosave is enabled.\n"));
   }

   load(context, i->get_id(), i, 1);
}
