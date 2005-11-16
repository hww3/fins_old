//! a simple memory cache object
//!

static mapping(string:array) values = ([]);

static void create()
{
  call_out(cleanup, 60);
}

//!
int set(string key, mixed value, int|void timeout)
{
  values[key] = ({timeout + time(), value});
  return 1;
}

//!
mixed get(string key)
{
  if(values[key])
  {
     if(values[key][0] > time()) return values[key][1];

     else
     {
       m_delete(values, key);
       return UNDEFINED;
     }
  }
  else return UNDEFINED;
}

void cleanup()
{
  werror("FinsCache: cleanup()\n");
  call_out(cleanup, 60);
}
