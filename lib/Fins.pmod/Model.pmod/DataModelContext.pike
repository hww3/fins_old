//!
int debug = 0;

mapping builder = ([ "possible_links" : ({}), "belongs_to" : ({}), "has_many": ({}), "has_many_many": ({}) ]);

//!
object find;

//!
object repository;

//!
object cache;

//! 
object personality;

//!
object app;

//!
object model;

//!
Sql.Sql sql;
string sql_url;

int id = random(time());

string _sprintf(mixed ... args)
{
  return "DataModelContext(" + sql->host_info() + ")";
}

string quote(string s)
{
   return sql->quote(s);
}

string quote_binary(string s)
{
  return personality->quote_binary(s);
}

string unquote_binary(string s)
{
  return personality->unquote_binary(s);
}

string type()
{
  string t;
  catch(t = model->config["model"]["personality"]);
  if(t) return t;
  else return (sprintf("%O", object_program(sql->master_sql))/".")[-1];
}

program get_personality()
{
  if(!sql) throw(Error.Generic("No SQL connection defined.\n"));

  return .Personality[lower_case(type())];
}

int initialize()
{
  program p = get_personality();
  if(!p) throw(Error.Generic("Unknown database type. No personality.\n"));

  personality = p(sql, this);

  personality->initialize();
  find = .find_provider(this);
}

//! copy this DataModelContext object and opens a new sql connection.
object clone()
{
	object d = object_program(this)();
	d->repository = repository;
	d->cache = cache;
	d->app = app;
	d->model = model;
	d->sql_url = sql_url;
	d->sql = Sql.Sql(sql_url);
	d->initialize();
	
	return d;
}

function(string|program|object,mapping,void|.Criteria:array) _find = old_find;

//!
array old_find(string|program|object ot, mapping qualifiers, void|.Criteria criteria)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));

   return repository->get_instance(o->instance_name)(UNDEFINED)->find(qualifiers, criteria, this);
}

//!
array find_all(string|object ot)
{

  return old_find(ot, ([]));
}

// find() is in module.pmod.

//!
.DataObjectInstance find_by_id(string|program|object ot, int id)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return  repository->get_instance(o->instance_name)(id, this);
}

//!
array find_by_query(string|program|object ot, string query)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));

   return old_find(o, (["0": Fins.Model.Criteria(query)]));
}

//!
.DataObjectInstance find_by_alternate(string|program|object ot, mixed id)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   if(!o->alternate_key)
     throw(Error.Generic("Object type " + ot + " does not have an alternate key.\n"));

   return repository->get_instance(o->instance_name)(UNDEFINED)->find_by_alternate(id, this);
}

//!
.DataObjectInstance new(string|program|object ot)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
  if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
  return  repository->get_instance(o->instance_name)(UNDEFINED, this);
}

