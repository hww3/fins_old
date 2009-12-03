
static Fins.Model.DataModelContext `[](mixed model_id)
{
   return Fins.Model.get_context((string)model_id);
}

static object `->(mixed model_id)
{
  return get(model_id);
}

object get(mixed model_id)
{
werror("**** get(%O)\n", model_id);
werror("fds: %O\n", fds);
  if(fds)
    return fds((string)model_id);
  else
  {
     fds = master()->resolv("Fins.Model.module.get_context_quiet");
     return fds(model_id);
  }

}

function fds;

//! The DataSource module provides access to any @[Fins.Model.ModelDataContext] objects defined 
//! by the application's configuration file. The default model definition is always available
//! as Fins.DataSource._default, and Fins.Model.find operates on the default model definition.
//! 
//! Any other models defined for an application can be accessed via Fins.DataSource.id where
//! id is the value of the id configuration parameter in the model's configuration section.
