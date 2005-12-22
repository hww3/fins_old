
.Field primary_key;
.Field alternate_key;

.DataModelContext context;

object my_undef = .Undefined;

mapping objs = ([]);

mapping fields = ([]);
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

void create(.DataModelContext c)
{
   context = c;
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

void generate_from_schema(string table)
{
   foreach(context->sql->list_fields(table);;mapping fieldspec)
   {
      switch(fieldspec->type)
      {
         case "string":
            break;
         case "long":
            break;
         default:
            throw(Error.Generic("Unknown type " + fieldspec->type +" for field " + fieldspec->name + ".\n"));
      }
   }
}

void set_instance_name(string _name)
{
  instance_name = _name;
}

void set_table_name(string _name)
{
  table_name = _name;
}

void set_primary_key(string _key)
{
  if(!fields[_key])
    throw(Error.Generic("Primary key field " + _key + " does not exist.\n"));

  else primary_key = fields[_key];
}

void add_field(.Field f)
{
   f->set_context(context);
   fields[f->name] = f;

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
         _where += ({ q->get(name, q) });
			if(q->get_table)
			  _tables += ({q->get_table(name, q)});
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
      (Array.uniq(_tables) * ", "), (_where * " AND "));

  else
    query = sprintf(multi_select_nowhere_query, (_fields * ", "), 
      table_name);

  if(criteria)
  {
     query += " " + criteria->get();
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
   return ([]);
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

int set_atomic(mapping values, .DataObjectInstance i)
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

   commit_changes(fields_set, object_data, i->get_id());
   load(i->get_id(), i, 1);
}


int set(string field, mixed value, .DataObjectInstance i)
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
   }
   
//   return 0;

   string delete_query = sprintf(single_delete_query, table_name, primary_key->name, key_value);

   if(context->debug) werror("QUERY: %O\n", delete_query);
   context->sql->query(delete_query);
   m_delete(objs, i->get_id());
   destruct(i);
   return 1;
}

static int commit_changes(multiset fields_set, mapping object_data, mixed update_id)
{
   string query;
   array qfields = ({});
   array qvalues = ({});
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

int save(.DataObjectInstance i)
{   
   if(i->is_new_object())
   {
      commit_changes(i->fields_set, i->object_data, 0);
      i->set_id(primary_key->get_id(i));
      i->set_new_object(0);
      i->set_saved(1);
      add_ref(i);
      i->object_data = ([]);
      i->fields_set = (<>);      
   }
   else if(autosave == 0)
   {
      commit_changes(i->fields_set, i->object_data, i->get_id());
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
