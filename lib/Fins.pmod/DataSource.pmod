
static Fins.Model.DataModelContext `[](mixed model_id)
{
   return Fins.Model.get_context((string)model_id);
}

//! The DataSource module provides access to any @[Fins.Model.ModelDataContext] objects defined 
//! by the application's configuration file. The default model definition is always available
//! as Fins.DataSource._default, and Fins.Model.find operates on the default model definition.
//! 
//! Any other models defined for an application can be accessed via Fins.DataSource.id where
//! id is the value of the id configuration parameter in the model's configuration section.
