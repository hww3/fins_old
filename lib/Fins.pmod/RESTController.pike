//! A controller that impliments REST style JSON CRUD functionality
//! for a given Model component.
//!
//! @todo
//!  user authenticated changes
//!  filtering more complex than by-field
//!  search specifications for GET
//!  record set limitations

import Fins;
inherit Fins.MethodController;
import Tools.Logging;

//! this should be the name of your object type and is used to link this
//! controller to the model. For auto-configured models, this is normally
//! a capitalized singular version of your table. For example, if your
//! table is called "users", this would be "User".
protected string model_component = 0;

//! if your application contains multiple model definitions, this should be the 
//! model "id" for the definition containing the component. the default value
//! selects the default model definition.
protected string model_id = "_default";

//! a list of fields to filter from generated JSON for this type.
//! 
//! @note
//!  this filter specification is shared with other JSON generating controllers
//!  running in this app, so that filtering is consistent, should an object of 
//!  this type be present and rendered in another @[RESTController].
protected multiset fields_to_filter = (<>);

protected object model_object;
protected object model_context;
protected object render_context;

protected void start()
{
  if(model_component)
  {
    model_context = Fins.Model.get_context(model_id);
    model_object = model_context->repository->get_object(model_component);
    model_context->repository->set_scaffold_controller("json", model_object, this);
    render_context = model_context->repository->get_json_render_context();
    render_context->set_filter_for_program(model_context->repository->get_instance(model_component), fields_to_filter);    
  }

  ::start();
}

protected void method_head(Fins.Request request, Fins.Response response, mixed ... args)
{
  response->set_data("you really should do a get, you know!");
}

protected void method_get(Fins.Request request, Fins.Response response, mixed ... args)
{
  array|object items;
 werror("args:%O\n", args);
  if(!sizeof(args))
    items = model_context->_find(model_object, request->variables);
  else
  {
    if(args[0][0] == ':')
      items = model_context->find_by_id(model_object, (int)((args*"/")[1..]));
    else
      items = model_context->find_by_alternate(model_object, args*"/");
  }
  response->set_type("text/json");
  response->set_data(Tools.JSON.serialize(items, render_context));
}
