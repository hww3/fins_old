
.Field primary_key;
.Field alternate_key;

.DataModelContext context;

object my_undef = Fins.Model.Undefined;

mapping objs = ([]);

mapping fields = ([]);

string single_select_query = "SELECT %s FROM %s WHERE %s=%s";
string single_update_query = "UPDATE %s SET %s=%s WHERE %s=%s";
string single_delete_query = "DELETE FROM %s WHERE %s=%s";
string multi_update_query = "UPDATE %s SET %s WHERE %s=%s";
string insert_query = "INSERT INTO %s %s VALUES %s";

int autosave = 1;

string name = "";

void create(.DataModelContext c)
{
   context = c;
}

void set_name(string _name)
{
  name = _name;
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
}

void load(int id, .DataObjectInstance i)
{
   array _fields = ({});
   
   foreach(fields;; .Field f)
     _fields += ({ f->field_name });
     
   string query = sprintf(single_select_query, (_fields * ", "), 
     name, primary_key->field_name, primary_key->encode(id));

   if(context->debug) werror("QUERY: %O\n", query);

   array result = context->sql->query(query);

   if(sizeof(result) != 1)
   {
     throw(Error.Generic("Unable to load " + name + " id " + id + ".\n"));
   }

   else 
   {
     i->set_new_object(0);
     // this is probably bad:
     i->set_id(primary_key->decode(result[0][primary_key->field_name]));
     mapping r = ([]);
     foreach(fields; string fn; .Field f)
     {
        r[f->name] = f->decode(result[0][f->field_name]);
     }
     i->set_cache(r);
   }
}

mapping get_atomic(.DataObjectInstance i)
{
   return ([]);
}

mixed get(string field, .DataObjectInstance i)
{

   if(!fields[field])
   {
     throw(Error.Generic("Field " + field + " does not exist in " + name + "\n"));
   }
   
   if(has_index(i->cached_object_data, field))
     return i->cached_object_data[field];
     
   string query = "SELECT %s FROM %s WHERE %s=%s";

   query = sprintf(query, fields[field]->field_name, name, 
     primary_key->field_name, primary_key->encode(i->get_id()));

      if(context->debug) werror("QUERY: %O\n", query);

   mixed result = context->sql->query(query);

   if(sizeof(result) != 1)
   {
     throw(Error.Generic("Unable to obtain information for " + name + " id " + i->get_id() + "\n"));
   }
   else 
   {
     return fields[field]->decode(result[0][fields[field]->field_name]);
   }
}

int set_atomic(mapping values, .DataObjectInstance i)
{
   mapping object_data = ([]);
   multiset fields_set = (<>);
   mixed key_value;

   foreach(values; string field; string value)
   {
      if(!fields[field])
      {
         throw(Error.Generic("Field " + field + " does not exist in object " + name + ".\n"));   
      }

       object_data[field] = fields[field]->validate(value);
       fields_set[field] = 1;      
   }

   commit_changes(fields_set, object_data, i->get_id());
   load(i->get_id(), i);
}


int set(string field, mixed value, .DataObjectInstance i)
{
   
   if(!fields[field])
   {
      throw(Error.Generic("Field " + field + " does not exist in object " + name + ".\n"));   
   }
   
   if(!i->is_new_object() && fields[field] == primary_key)
   {
      throw(Error.Generic("Cannot modify primary key field " + field + ".\n"));
   }
   
   if(!i->is_new_object() && autosave)
   {
      string new_value = fields[field]->encode(value);
      string key_value = primary_key->encode(i->get_id());
   
      string update_query = sprintf(single_update_query, name, field, new_value, primary_key->name, key_value);
      i->set_saved(1);
      if(context->debug) werror("QUERY: %O\n", update_query);
     context->sql->query(update_query);
     load(i->get_id(), i);   
   }
   
   else
   {
      i->set_saved(0);
      i->object_data[field] = fields[field]->validate(value);
      i->fields_set[field] = 1;
   }
   
   return 1;
}

int delete(.DataObjectInstance i)
{
   // first, check to see what we link to.
   string key_value = primary_key->encode(i->get_id());
   
   string delete_query = sprintf(single_delete_query, name, primary_key->name, key_value);
   
   if(context->debug) werror("QUERY: %O\n", delete_query);
   context->sql->query(delete_query);

   return 1;
}

static int commit_changes(multiset fields_set, mapping object_data, int update_id)
{
   string query;
   array qfields = ({});
   array qvalues = ({});
      foreach(fields;; .Field f)
      {
         if(update_id && fields_set[f->name] && f == primary_key)
         {
            throw(Error.Generic("Changing id for " + name + " not allowed for existing objects.\n"));
         }
         else if(update_id && f == primary_key)
         {
            // we can skip the primary key for existing objects.
         }
         // have we set nothing, and are allowed to?
         else if(!fields_set[f->name] && f->null)
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

         query = sprintf(insert_query, name, fields_clause, values_clause);
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
         
         query = sprintf(multi_update_query, name, set_clause, primary_key->field_name, primary_key->encode(update_id));
         if(context->debug) werror("QUERY: %O\n", query);
      }
      context->sql->query(query);
}

int save(.DataObjectInstance i)
{   
   if(i->is_new_object())
   {
      commit_changes(i->fields_set, i->object_data, 0);
      i->set_id(primary_key->get_id());
      i->set_new_object(0);
      i->set_saved(1);
      i->object_data = ([]);
      i->fields_set = (<>);      
   }
   else if(autosave == 0)
   {
      commit_changes(i->fields_set, i->object_data, i->get_id());
      i->set_saved(1);
      i->object_data = ([]);
      i->fields_set = (<>);            
   }
   else
   {
      throw(Error.Generic("Cannot save() when autosave is enabled.\n"));
   }

   load(i->get_id(), i);

}
