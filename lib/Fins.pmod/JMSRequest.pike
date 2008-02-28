inherit Fins.Request;

constant low_protocol = "JMS";

object low_message;

//! contains all of the properties of this message
mapping headers;

//! contains the contents of the message
string body;

//! returns the JMS correlation ID header
string get_correlation_id()
{
	return (string)low_message->getJMSCorrelationID();
}

//! returns the JMS message ID
string get_message_id()
{
	return (string)low_message->getJMSMessageID();
}

//! returns the JMS message type
string get_type()
{
	return (string)low_message->getJMSType();
}

//! returns the JMS timestamp
int get_timestamp()
{
	return (int)low_message->getJMSTimestamp();
}

//! returns the JMS delivery mode for this message
int get_delivery_mode()
{
	return (int)low_message->getJMSDeliveryMode();
}

//! returns the JMS priority for this message
int get_priority()
{
	return (int)low_message->getJMSPriority();
}

//! returns the JMS redelivery status for this message
int get_redelivered()
{
	return (int)low_message->getJMSRedelivered();
}

//! returns a URI object describing the destination this message was sent to
Standards.URI get_destination()
{
	object d = low_message->getJMSDestination();

    if(d->getQueueName)
      return Standards.URI("queue://" + (string)d->getQueueName());
    else if(d->getTopicName)
      return Standards.URI("topic://" + (string)d->getTopicName());
	else return 0;
}

//! returns a URI object describing the reply-to destination for this message
Standards.URI get_reply_to()
{
	object d = low_message->getJMSReplyTo();

    if(d && d->getQueueName)
      return Standards.URI("queue://" + (string)d->getQueueName());
    else if(d && d->getTopicName)
      return Standards.URI("topic://" + (string)d->getTopicName());
	else return 0;
}

//! acknowledge the message (for situations where this is required)
void acknowledge()
{
	low_message->acknowledge();
}

//!
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

//!
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
