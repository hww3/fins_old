import Fins;
import Tools.Logging;
inherit Processor;

object jndi_context;

mapping listeners = ([]);
mapping r_listeners = ([]);
mapping processors = ([]);

array supported_protocols()
{
  return ({"JMS"});
}

void start()
{
  if(!config["jms"])
    throw(Error.Generic("No JMS configuration section.\n"));
    object ctx = Java.pkg["javax/naming/Context"];
	object props = Java.pkg["java/util/Properties"]();
	props->setProperty(ctx->INITIAL_CONTEXT_FACTORY, config["jms"]["initial_context_factory"]); // "org.apache.activemq.jndi.ActiveMQInitialContextFactory"
	props->setProperty(ctx->PROVIDER_URL, config["jms"]["provider_url"]); //"tcp://localhost:61616"
	jndi_context = Java.pkg["javax/naming/InitialContext"](props); 
}

void register_subscriber(object to)
{
//  if(listeners[to]) unregister_subscriber(to);

  listeners[to] = to->subscribes_to;
  r_listeners[to->subscribes_to] = to;
  processors[to->subscribes_to] = JMSHandler(to, jndi_context);  
//  stomp->subscribe(to->subscribes_to, lambda(object frame){ return process_message(frame, to->subscribes_to); });
}

mixed handle(Request request)
{
  
}

int publish(string destination, string body, mapping|void headers)
{
   // return stomp->send(destination, body, headers);
}

class JMSHandler
{
  object sub;
  object controller;
	
	static void create(object _controller, object _context)
	{
		controller = _controller;
		object factory = _context->_method("lookup", "(Ljava/lang/String;)Ljava/lang/Object;")(controller->connection_factory); 
		object t = _context->_method("lookup", "(Ljava/lang/String;)Ljava/lang/Object;")(controller->subscribes_to); 
		
		object qc, s;
		
//		Log.debug("%O", indices(factory));
		if(t && t->getQueueName)
		{
          qc = factory->createQueueConnection(); 
          s = qc->createQueueSession(0, 0); 
  		  sub = s->createReceiver(t); 
		}
		else if(t && t->getTopicName)
		{
          qc = factory->createTopicConnection(); 
          s = qc->createTopicSession(0, 0); 			
		  sub = s->createSubscriber(t); 
		}
		//write("getting ready to receive\n"); 
		qc->start(); 
		
		Thread.Thread(run);
	}
	
	void run()
	{
		object e;

		do
		  { 
			object m = sub->receive();
		    if((int)(controller->config["controller"]["reload"]))
		    {
			  controller->app->controller_updated(controller, app, "controller");
		    }

		    if(m) 
		    {  
			  e = catch {
			    if(controller && controller->on_message && functionp(controller->on_message))
			      controller->on_message(JMSRequest(m));
			  };

			  if(e) 
			  {
			    Log.exception("an error occurred while calling on_message()\n", e);
			  }  
			} 
		  } 
		  while(1); 		
	}
	
}