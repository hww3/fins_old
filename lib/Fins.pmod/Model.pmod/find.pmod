//!
//! The find module provides methods for working with objects.
//!
//! for each registered object type (for example, User), a number of 
//! methods will be available:
//!
//! users_all()
//! users_by_id( int identifier )
//! users( mapping criteria )
//! users_by_query( string where clause )
//!

object model = Fins.Model.module;

//!
void set_repository(object m)
{
	model = m;
}

static mapping funcs = ([]);

optional mixed `()( mixed ... args )
{
  return model->old_find(@args);
}

static mixed `[](mixed k)
{
  function f;
//  if(k == "_set_model") return set_model;
  if(f=funcs[k]) return f;
  else if(f=get_func(k)) return funcs[k]=f;
  else return 0;
}

static void set_model()
{
	
}

static string string_without_suffix(string k, string s)
{
  return k[0..sizeof(k) - (sizeof(s)+1)];
}


static program get_model_component(string ot)
{
  mixed m = model->get_model_module();

  array x = indices(m);
  array y = values(m);
  
  foreach(x;int i; string v)
    x[i] = lower_case(v);

  m = mkmapping(x,y);

  return m[ot];
}

static object get_object_component(string ot)
{
  mixed m = model->get_object_module();

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

  // we only like strings.
  if(!stringp(k)) return 0;

  if(has_suffix(k, "_by_id"))
  {
    ot = string_without_suffix(k, "_by_id");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(mixed ... args){ return model->find_by_id(p, @args);};
  }
  if(has_suffix(k, "_by_query"))
  {
    ot = string_without_suffix(k, "_by_query");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(mixed ... args){ return model->find_by_query(p, @args);};
  }
  else if(has_suffix(k, "_by_alternate"))
  {
    ot = string_without_suffix(k, "_by_alternate");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(mixed ... args){ return model->find_by_alternate(p, @args);};
  }
  else if(has_suffix(k, "_by_alt"))
  {
    ot = string_without_suffix(k, "_by_alt");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(mixed ... args){ return model->find_by_alternate(p, @args);};
  }
/*
  else if((i = search(k, "_by_")) != -1)
  {
    object q;
    ot = k[0..(i-1)];
    ot = Tools.Language.Inflect.singularize(ot);
werror("ot: %O, %O\n", get_model_component(ot)->master_object, k[(i+4)..]);
    if((p = get_model_component(ot)) && (q = get_object_component(ot))->alternate_key && (k[(i+4) ..] == lower_case(q->alternate_key->name)))
      return lambda(mixed ... args){ return Fins.Model.find_by_alternate(p, @args);};

  }
*/
  else if(has_suffix(k, "_all"))
  {
    ot = string_without_suffix(k, "_all");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(){ return model->old_find(p, ([]));};
  }
  else
  {
    ot = Tools.Language.Inflect.singularize(k);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(mixed ... args){ return model->old_find(p, @args);};
    
  }

  return f;
}

