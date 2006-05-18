//! a simple memory cache object
//!

static mapping(string:array) values = ([]);

static void create()
{
  call_out(cleanup, 60);
}

//! remove a cache entry
//!
//! @param key
//!   key of the item we wish to remove
//! @returns
//!   1 on succeful delte of the item, 0 otherwise.
int clear(string key)
{
  if(values[key] || !zero_type(values[key]))
  {
    m_delete(values, key);
    return 1;
  } 
  else return 0;
}

//! add an item in the cache.
//! @param key
//!   the key to identify this cache item by. if an entry identified by key already
//!   exists, we will replace it with this new value.
//! @param value
//!   the value to save in the cache
//! @param timeout
//!   the number of seconds in the future to save the item. If zero, we assume an
//!   infinte lifetime, subject to overall caching strategies.
//! @param sliding
//!   if set, we will keep moving the expiration ahead each time the entry is accessed
//!   via the get() method.
int set(string key, mixed value, int|void timeout, int sliding)
{
  
  values[key] = ({timeout + time(), value, sliding, timeout});
  return 1;
}

//! gets a value from the cache
//! 
//! @param key
//!   the identification key for the value we wish to retrieve
//! @returns
//!   the value, if it existed in the cache, otherwise UNDEFINED.
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
