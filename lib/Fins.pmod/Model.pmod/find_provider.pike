//!
//! The find module provides methods for working with objects.
//!
//! for each registered object type (for example, User), a number of 
//! methods will be available:
//!
//! users_all([sort_criteria])
//! users_by_id( int identifier, [sort criteria] )
//! users( mapping criteria, [sort criteria])
//! users_by_query( string where clause )
//! users_by_alt(string alternate_id)
//! users_by_alternate(string alternate_id)

object log = Tools.Logging.get_logger("fins.model");

.DataModelContext context;

static void create(void|.DataModelContext c)
{
  context = c;
}

static mapping funcs = ([]);

optional mixed `()( mixed ... args )
{
  return context->old_find(@args);
}

static mixed `->(string k)
{
  return `[](k);
}

static mixed `[](mixed k)
{
  function f;
//  if(k == "_set_model") return set_model;
  if(f=funcs[k]) return f;
  else if(f=get_func(k)) return funcs[k]=f;
  else return 0;
}

static string string_without_suffix(string k, string s)
{
  return k[0..sizeof(k) - (sizeof(s)+1)];
}


static program get_model_component(string ot)
{
  if(!ot)
   {
     throw(Error.Generic("no model component\n"));
//      werror()
   }
//   mixed m = context->repository->get_model_module();
mixed m = context->repository->object_definitions;
  array x = indices(m);
  array y = values(m);
  
  foreach(x;int i; string v)
    x[i] = lower_case(v);

  m = mkmapping(x,y);
 //log->debug("%O: %s in %O", Tools.Function.this_function(), ot, m);

  return m[ot];
}

static object get_object_component(string ot)
{
  mixed m = context->repository->get_object_module();

  array x = indices(m);
  array y = values(m);
  
  foreach(x;int i; string v)
    x[i] = lower_case(v);

  m = mkmapping(x,y);

  return m[ot];
}


static function get_func(mixed k)
{
  function f;
  string ot;
  program p;
  int i;

  if(!context)
  {
	log->debug("initializing %O with default model context.", this);
    context = Fins.Model.get_default_context();
  }

  // we only like strings.
  if(!stringp(k)) return 0;

  if(has_suffix(k, "_by_id"))
  {

    ot = string_without_suffix(k, "_by_id");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
	{
		log->debug("%O found %s component %O", this, k, p);

      return lambda(mixed ... args){ return context->find_by_id(p, @args);};
	}
  }
  if(has_suffix(k, "_by_query"))
  {
    ot = string_without_suffix(k, "_by_query");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
	{
		log->debug("%O found %s component %O", this, k, p);
      return lambda(mixed ... args){ return context->find_by_query(p, @args);};
    }
  }
  else if(has_suffix(k, "_by_alternate"))
  {
    ot = string_without_suffix(k, "_by_alternate");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
	{
	  log->debug("%O found %s component %O", this, k, p);
      return lambda(mixed ... args){ return context->find_by_alternate(p, @args);};
    }
  }
  else if(has_suffix(k, "_by_alt"))
  {
    ot = string_without_suffix(k, "_by_alt");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
	{
   	  log->debug("%O found %s component %O", this, k, p);
      return lambda(mixed ... args){ return context->find_by_alternate(p, @args);};
    }
  }

  else if((i = search(k, "_by_")) != -1)
  {
    ot = k[0..(i-1)];
    ot = Tools.Language.Inflect.singularize(ot);
//werror("ot: %O, %O, %O, %O\n", ot, get_model_component(ot), k[(i+4)..], get_model_component(ot)->alternate_key);
    if((p = get_model_component(ot)) && p->alternate_key && (k[(i+4) ..] == lower_case(p->alternate_key->name)))
      return lambda(mixed ... args){ return context->find_by_alternate(p, @args);};

  }

  else if(has_suffix(k, "_all"))
  {
    ot = string_without_suffix(k, "_all");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
	{
	  log->debug("%O found %s component %O", this, k, p);
      return lambda(mixed ... args){ return context->old_find(p, ([]), @args);};
    }
  }
  else
  {
    ot = Tools.Language.Inflect.singularize(k);
//    ot = String.capitalize(ot);
	if(!ot) return 0;
    if(p=get_model_component(ot))
	{
	  log->debug("%O found %s component %O", this, k, p);
      return lambda(mixed ... args){ return context->old_find(p, @args);};
    }    
  }

  return f;
}

