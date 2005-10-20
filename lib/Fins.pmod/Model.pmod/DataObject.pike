
.Field primary_key;
.Field alternate_key;

.DataModelContext context;

object my_undef = Fins.Model.Undefined;
mapping fields = ([]);

string single_select_query = "SELECT %s FROM %s WHERE %s=%s";
string single_update_query = "UPDATE %s SET %s=%s WHERE %s=%s";
string single_delete_query = "DELETE FROM %s WHERE %s=%s";
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
   string query = sprintf(single_select_query, primary_key->field_name, 
     name, primary_key->field_name, primary_key->encode(id));

   werror("QUERY: %O\n", query);

   array result = context->sql->query(query);

   if(sizeof(result) != 1)
   {
     throw(Error.Generic("Unable to load " + name + " id " + id + ".\n"));
   }

   else 
   {
     i->set_new_object(0);
     // this is probably bad:
     i->key_value = (int)result[0][primary_key->field_name];
   }
}

mixed get(string field, .DataObjectInstance i)
{

   if(!fields[field])
   {
     throw(Error.Generic("Field " + field + " does not exist in " + name + "\n"));
   }
   string query = "SELECT %s FROM %s WHERE %s = %s";

   query = sprintf(query, fields[field]->field_name, name, 
     primary_key->field_name, primary_key->encode(i->key_value));

   werror("QUERY: %O\n", query);

   mixed result = context->sql->query(query);

   if(sizeof(result) != 1)
   {
     throw(Error.Generic("Unable to obtain information for " + name + " id " + i->key_value + "\n"));
   }

   else 
   {
     return result[0][fields[field]->field_name];
   }
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
      string key_value = primary_key->encode(i->key_value);
   
      string update_query = sprintf(single_update_query, name, field, new_value, primary_key->name, key_value);
      i->set_saved(1);
      werror("QUERY: %O\n", update_query);
     context->sql->query(update_query);
   }
   
   else
   {
     i->set_saved(0);
   
      if(fields[field] == primary_key )
      {
         i->key_value = value;
      }
      i->object_data[field] = fields[field]->validate(value);
      i->fields_set[field] = 1;
   }
   
   return 1;
}

int delete(.DataObjectInstance i)
{
   // first, check to see what we link to.
   string key_value = primary_key->encode(i->key_value);
   
   string delete_query = sprintf(single_delete_query, name, primary_key->name, key_value);
   
   werror("QUERY: %O\n", delete_query);
   context->sql->query(delete_query);

   return 1;
}

int save(.DataObjectInstance i)
{
   array qfields = ({});
   array qvalues = ({});
   if(i->is_new_object() == 1)
   {
      foreach(fields;; .Field f)
      {
         // have we set nothing, and are allowed to?
         if(!i->fields_set[f->name] && f->null)
         {
         }
         else if(!i->fields_set[f->name] && !f->null)
         {
            qfields += ({f->field_name});
            qvalues += ({f->encode(my_undef)});
         }
         else
         {
            qfields += ({f->field_name});
            qvalues += ({f->encode(i->object_data[f->name])});
         }
      }
      
      string fields_clause = "(" + (qfields * ", ") + ")";
      string values_clause = "(" + (qvalues * ", ") + ")";

      string query = sprintf(insert_query, name, fields_clause, values_clause);
      werror("QUERY: %O\n", query);
      context->sql->query(query);
      string key_value;
      i->key_value = primary_key->get_id();
      i->set_new_object(0);
      i->set_saved(1);
      i->object_data = ([]);
      i->fields_set = (<>);
      
   }
   else if(autosave == 0)
   {
      
   }
   else
   {
      throw(Error.Generic("Cannot save() when autosave is enabled.\n"));
   }
   
}
