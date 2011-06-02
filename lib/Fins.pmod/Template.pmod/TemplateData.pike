 mapping data = ([]);
 mapping flash = ([]);
 object request;

int debug = 0;

//!
void create(mapping|void defaults)
{
  if(defaults)
    data = defaults;
}

//!
public void add(string name, mixed item)
{
   data[name] = item;
}

//! 
public void add_all(mapping items)
{
  data += items;	
}

//!
public void set_data(mapping d)
{
   data = d;
}

//!
public void set_request(object r)
{
   request = r;
}

//!
public void set_flash(mapping d)
{
   flash = d;
}

//!
public mapping get_data()
{
   return data;
}

//!
public object get_request()
{
   return request;
}

//!
public mapping get_flash()
{
   return flash;
}

//!
public .TemplateData clone()
{
  object d = object_program(this)();
  d->set_request(request);
  d->set_data(data + ([]));
  d->set_flash(flash + ([]));
  return d;
}
