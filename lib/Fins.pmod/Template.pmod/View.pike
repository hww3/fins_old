object data;
object template;

void create(object _template, object _data)
{
	template = _template;
	data = _data;
}

void set_layout(string path) 
{
  template->set_layout(path);
}

void add(string name, mixed var)
{
	data->add(name, var);
}

mixed get_data()
{
	return data->get_data();
}

string render()
{
	return template->render(data);
}
