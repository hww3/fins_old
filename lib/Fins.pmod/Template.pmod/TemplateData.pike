static mapping data = ([]);

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