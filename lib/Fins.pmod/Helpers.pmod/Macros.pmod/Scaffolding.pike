inherit .Base;


string simple_macro_field_describe(Fins.Template.TemplateData data, mapping|void arguments)
{
	object request = data->get_request();
    if(!Program.implements(object_program(request->controller), Fins.ScaffoldController))
	{
		throw(Fins.Errors.Template("Cannot use field_describe macro outside of a Scaffold Controller.\n"));
	}

	mixed rd = data->get_data();
	
	mixed item = arguments->item;
	mixed field = arguments->field;

	string ed = request->controller->make_value_describer(field->name, 
														 (item?item[field->name]:UNDEFINED), item);
	
	if(ed)
	  return ed;
	else
	  return "N/A";
}

//! args: item, field, orig
string simple_macro_field_editor(Fins.Template.TemplateData data, mapping|void arguments)
{
	object request = data->get_request();
    if(!Program.implements(object_program(request->controller), Fins.ScaffoldController))
	{
		throw(Fins.Errors.Template("Cannot use field_editor macro outside of a Scaffold Controller.\n"));
	}
	
	mixed rd = data->get_data();
	
	mixed item = arguments->item;
	mixed field = arguments->field;
	mixed orig = arguments->orig;
	
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
