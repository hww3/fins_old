//! a simple memory cache object
//!

static mapping(string:array) values = ([]);

static void create()
{
  call_out(cleanup, 60);
}

//!
int clear(string key)
{
  if(values[key] || !zero_type(values[key]))
  {
    m_delete(values, key);
    return 1;
  } 
  else return 0;
}

//!
int set(string key, mixed value, int|void timeout, int sliding)
{
  
  values[key] = ({timeout + time(), value, sliding, timeout});
  return 1;
}

//!
mixed get(string key)
{
  if(values[key])
  {
     if(values[key][0] > time()) 
     {
       if(values[key][2]) // sliding rule
         values[key][0] = values[key][3] + time();  
       return values[key][1];
     }
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
  int t = time();
  int cleaned = 0;
  {
    foreach(values; string key; mixed value)
    {
       if(value[0]<t)
       {
         m_delete(values, key);
         cleaned ++;
       }
    }
  }
  if(cleaned)
    werror("FinsCache(): cleaned " + cleaned + " objects.\n");
  call_out(cleanup, 60);
}
