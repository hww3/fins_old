static mapping data = ([]);

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
public void set_data(mapping d)
{
   data = d;
}

//!
public mapping get_data()
{
   return data;
}
