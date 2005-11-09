inherit Fins.FinsBase;
import Protocols.HTTP.Server;

//! methods have this signature:
//!
//!  void func(Fins.Request request, Fins.Response response, 
//!            mixed ... args);
//!

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

