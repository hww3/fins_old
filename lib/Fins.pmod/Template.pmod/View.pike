object data;
object template;

void create(object _template, object _data)
{
	template = _template;
	data = _data;
}

//! sets the layout file for the contained template
void set_layout(string|object path) 
{
  template->set_layout(path);
}

//! adds all values in a mapping as data items
void add_all(mapping vals)
{
	data->add_all(vals);
}

//! adds a data item to this view
void add(string name, mixed var)
{
	data->add(name, var);
}

//! gets the data contained in this view
mixed get_data()
{
	return data->get_data();
}

//! renders the template in this view using data contained in this view object.
string render()
{
	return template->render(data);
}
