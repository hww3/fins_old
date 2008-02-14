inherit .Base;

//! args: item, field, orig
//! where format is a Calendar object format type; default is ext_ymd.
string simple_macro_field_editor(Fins.Template.TemplateData data, mapping|void arguments)
{
	object request = data->get_request();
    if(!Program.implements(object_program(request->controller), Fins.ScaffoldController))
	{
		throw(Fins.Errors.Template("Cannot use field_editor macro outside of a Scaffold Controller.\n"));
	}
	
	mixed rd = data->get_data();
	
	mixed item = get_var_value(arguments->item, rd);
	mixed field = get_var_value(arguments->field, rd);
	mixed orig = get_var_value(arguments->orig, rd);
	
	if(!orig)
	{
		throw(Fins.Errors.Template("No original data for field_editor macro in " + arguments->orig + ".\n"));
	}
	  
	string ed = request->controller->make_value_editor(field->name, 
														orig[field->name] || (item?item[field->name]:UNDEFINED), item);
	
	if(ed)
	  return ed;
	else
	  return "N/A";
}
