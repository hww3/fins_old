inherit Fins.FinsBase;
import Protocols.HTTP.Server;

//! methods have this signature:
//!
//!  void func(Fins.Request request, Fins.Response response, 
//!            mixed ... args);
//!

//! set this to zero to avoid session redirects
constant __uses_session = 1;
int __last_load;

//!
static void create(.Application a)
{  
  __last_load = time();
  ::create(a);

  if(functionp(start))
    start();
}

//!
static void start()
{
}

