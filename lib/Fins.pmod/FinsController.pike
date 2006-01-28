inherit Fins.FinsBase;
import Protocols.HTTP.Server;

//! methods have this signature:
//!
//!  void func(Fins.Request request, Fins.Response response, 
//!            mixed ... args);
//!

//! set this to zero to avoid session redirects
int __uses_session = 1;

//!
static void create(.Application a)
{  
  ::create(a);

  if(functionp(start))
    start();
}

//!
static void start()
{
}

