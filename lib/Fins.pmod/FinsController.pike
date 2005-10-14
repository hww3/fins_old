import Protocols.HTTP.Server;

.Configuration config;

static void create(.Configuration _config)
{
  config = _config;

  if(functionp(start))
    start();
}

void start()
{
}

//! methods have this signature:
//!
//!  void func(Fins.Request request, Fins.Response response, 
//!            mixed ... args);
//!
