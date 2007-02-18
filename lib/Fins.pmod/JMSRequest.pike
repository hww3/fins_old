inherit Fins.Request;

constant low_protocol = "JMS";

object low_message;
mapping headers;
string body;

string get_correlation_id()
{
	return (string)low_message->getJMSCorrelationID();
}

string get_message_id()
{
	return (string)low_message->getJMSMessageID();
}

string get_type()
{
	return (string)low_message->getJMSType();
}

int get_timestamp()
{
	return (int)low_message->getJMSTimestamp();
}

int get_delivery_mode()
{
	return (int)low_message->getJMSDeliveryMode();
}

int get_priority()
{
	return (int)low_message->getJMSPriority();
}

int get_redelivered()
{
	return (int)low_message->getJMSRedelivered();
}

Standards.URI get_destination()
{
	object d = low_message->getJMSDestination();

    if(d->getQueueName)
      return Standards.URI("queue://" + (string)d->getQueueName());
    else if(d->getTopicName)
      return Standards.URI("topic://" + (string)d->getTopicName());
	else return 0;
}

Standards.URI get_reply_to()
{
	object d = low_message->getJMSReplyTo();

    if(d && d->getQueueName)
      return Standards.URI("queue://" + (string)d->getQueueName());
    else if(d && d->getTopicName)
      return Standards.URI("topic://" + (string)d->getTopicName());
	else return 0;
}

void acknowledge()
{
	low_message->acknowledge();
}

static void create(object|void message)
{
  if(message)
  {
    low_message = message;

    headers = generate_headers(message);  
    body = (string)message->getText();
  }
  else
  {
    low_message = Java.pkg["javax.jms.Message"]();	
  }
}


mapping generate_headers(object message)
{
	mapping headers = ([]);
	
	object e = message->getPropertyNames();
	for (e ; e->hasMoreElements() ;) 
	{
	   object ne = e->nextElement();
	   headers[(string)ne] = message->getObjectProperty(ne);      
	}
	
	return headers;
}