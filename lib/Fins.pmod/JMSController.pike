import Fins;
inherit FinsController;
inherit JMSMessenger;

constant subscribes_to = "";

void start()
{
  object p = app->get_processor("JMS");

  p->register_subscriber(this);
}

void on_message(Fins.JMSRequest request);