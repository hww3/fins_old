
//!
constant Undefined = .Undefined_Value;

//!
constant OPER_AND = 0;

//!
constant OPER_OR = 1;

//!
constant SORT_DESCENDING = 1;

//!
constant SORT_ASCENDING = 0;

protected mapping contexts = ([]);

private object default_finder;
//object find;

mixed `->find()
{
  if(!default_finder) default_finder = master()->resolv("Fins.Model.find_provider")();
  return default_finder;
}

//! returns the default model context defined for the application
//!
//! @throws
//!  an error if the requested model is not defined.
object get_default_context()
{
  if(contexts["_default"]) return contexts["_default"];
  else throw(Error.Generic("No default model context defined (yet).\n"));
}

object set_context(string model_id, object context)
{
  contexts[model_id] = context;
}

//! get the model context identified by model_id.
//! 
//! @throws
//!  an error if the requested model is not defined.
object get_context(string model_id)
{
  if(contexts[model_id])
  {
  //	werror("context [%s] = %O\n", model_id, contexts[model_id]);
	 return contexts[model_id];
 }
  else throw(Error.Generic("No model context defined for " + model_id + " (yet).\n"));

}
