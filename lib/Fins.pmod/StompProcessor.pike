import Fins;
import Tools.Logging;
inherit Processor;

object stomp;

mapping listeners = ([]);

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
     stomp = Public.Protocols.Stomp.Client(config["stomp"]["broker"]);
  }
}

void register_subscriber(object to)
{
//  if(listeners[to]) unregister_subscriber(to);

  listeners[to] = to->subscribes_to;

  stomp->subscribe(to->subscribes_to, lambda(object frame){ return process_message(frame, to); });
}

int process_message(object frame, object to)
{
  object e;
  e = catch {
    if(to->on_message && functionp(to->on_message))
      to->on_message(StompRequest(frame));
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