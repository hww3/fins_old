import Fins;
import Tools.Logging;
inherit Processor;

object stomp;

mapping listeners = ([]);
mapping r_listeners = ([]);

array supported_protocols()
{
  return ({"Stomp"});
}

void start()
{
  if(!config["stomp"])
    throw(Error.Generic("No Stomp configuration section.\n"));

  else
  {
     stomp = Public.Protocols.Stomp.Client(config["stomp"]["broker"], 1);
  }
}

void register_subscriber(object to)
{
//  if(listeners[to]) unregister_subscriber(to);

  listeners[to] = to->subscribes_to;
  r_listeners[to->subscribes_to] = to;
  stomp->subscribe(to->subscribes_to, lambda(object frame){ return process_message(frame, to->subscribes_to); });
}

int process_message(object frame, string to)
{
  object e;
  object c;
  int r;

  if((int)(config["controller"]["reload"]))
  {
	app->controller_updated(r_listeners[to], app, "controller");
  }

  c = r_listeners[to];

  e = catch {
    if(c && c->on_message && functionp(c->on_message))
      c->on_message(StompRequest(frame));
  };

  if(e) 
  {
    Log.exception("an error occurred while calling on_message()\n", e);
    return 0;
  }  
  else return 1;
}

mixed handle(Request request)
{
  
}