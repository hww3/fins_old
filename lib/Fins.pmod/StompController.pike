import Fins;
inherit FinsController;

constant subscribes_to = "";

void start()
{
  object p = app->get_processor("Stomp");
  if(!p)
    throw(Error.Generic("No Stomp Processor found. Unable to start the Stomp Controller.\n"));
  p->register_subscriber(this);
}
