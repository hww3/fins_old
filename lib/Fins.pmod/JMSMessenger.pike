

void publish(string destination, string body, mapping|void properties)
{
	object p = this->app->get_processor("JMS");
	p->publish(destination, body, properties);
}