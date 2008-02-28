import Fins;
inherit FinsController;
inherit JMSMessenger;

//! JMS topic or queue this controller processes messages for.
//! this should be a "JMS url", which takes the form of topic://topicname
//! or queue://queuename.
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

//! this method will be called for each message recieved on the subscribed 
//! destination. the message request object received will be passed as the 
//! argument to this method.
void on_message(Fins.JMSRequest request);
