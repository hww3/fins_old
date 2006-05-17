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

array __before_filters = ({});
array __after_filters = ({});

//!
static void before_filter(function filter)
{
  __before_filters += ({ filter });
}

//!
static void after_filter(function filter)
{
  __after_filters += ({ filter });
}

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
