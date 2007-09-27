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

static mapping funcs = ([]);

optional mixed `()( mixed ... args )
{
  return Fins.Model.old_find(@args);
}

static mixed `[](mixed k)
{
  function f;
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
  mixed m = Fins.Model.get_model_module();

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

  // we only like strings.
  if(!stringp(k)) return 0;

  if(has_suffix(k, "_by_id"))
  {
    ot = string_without_suffix(k, "_by_id");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(mixed ... args){ return Fins.Model.find_by_id(p, @args);};
  }
  if(has_suffix(k, "_by_query"))
  {
    ot = string_without_suffix(k, "_by_query");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(mixed ... args){ return Fins.Model.find_by_query(p, @args);};
  }
  else if(has_suffix(k, "_by_alternate"))
  {
    ot = string_without_suffix(k, "_by_alternate");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(mixed ... args){ return Fins.Model.find_by_alternate(p, @args);};
  }
  else if(has_suffix(k, "_all"))
  {
    ot = string_without_suffix(k, "_all");
    ot = Tools.Language.Inflect.singularize(ot);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(){ return Fins.Model.old_find(p, ([]));};
  }
  else
  {
    ot = Tools.Language.Inflect.singularize(k);
//    ot = String.capitalize(ot);
    if(p=get_model_component(ot))
      return lambda(mixed ... args){ return Fins.Model.old_find(p, @args);};
    
  }

  return f;
}

