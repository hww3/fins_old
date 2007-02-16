import Fins;
inherit FinsController;

constant subscribes_to = "";

void start()
{
  object p = app->get_processor("Stomp");

  p->register_subscriber(this);
}