import Fins;
inherit FinsController;

constant subscribes_to = "";
constant connection_factory = "";

void start()
{
  object p = app->get_processor("JMS");

  p->register_subscriber(this);
}