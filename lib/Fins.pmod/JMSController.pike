import Fins;
inherit FinsController;

constant subscribes_to = "";
constant connection_factory = "";
constant connection_user = 0;
constant connection_password = 0;

void start()
{
  object p = app->get_processor("JMS");

  p->register_subscriber(this);
}