import Fins;
inherit FinsController;
inherit JMSMessenger;

constant subscribes_to = "";

void start()
{
  object p = app->get_processor("JMS");
  if(!p)
  {
    throw(Error.Generic("No JMS Processor Started; unable to start JMS Controller.\n"));
  }
  p->register_subscriber(this);
}

void on_message(Fins.JMSRequest request);
