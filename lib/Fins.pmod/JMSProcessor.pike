import Fins;
import Tools.Logging;
inherit Processor;

object jndi_context;

mapping listeners = ([]);
mapping r_listeners = ([]);
mapping processors = ([]);

mapping publishers = ([]);

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
  object handler;
  handler = JMSSubscriber(to, jndi_context);
  listeners[to] = to->subscribes_to;
  r_listeners[to->subscribes_to] = to;
  processors[to->subscribes_to] = handler; 
  handler->start_subscriber();
}

mixed handle(Request request)
{
  
}

void publish(string destination, string body, mapping|void properties)
{
	object p;
	
	if(!publishers[destination])
	{
		p = JMSPublisher(destination, jndi_context);
		publishers[destination] = p;
	}
	else 
	{
		p = publishers[destination];
	}

	p->simple_publish(body, properties);
}

class JMSHandler
{
  object sub;
  object pub;
  object sess;
  object destination;
  object context;

	static void create(string _destination, object _context)
	{
		destination = Standards.URI(_destination);
		context = _context;
	}

	object get_publisher(object destination)
	{
		object pub;
		object t = context->_method("lookup", "(Ljava/lang/String;)Ljava/lang/Object;")(destination->path[1..]); 
		object sess = get_session(destination, t);
		if(sess->createPublisher)
		  pub = sess->createPublisher(t); 
		else
	 	  pub = sess->createSender(t); 
		return pub;		
	}
	
	object get_subscriber(object destination)
	{
		object sub;
		object t = context->_method("lookup", "(Ljava/lang/String;)Ljava/lang/Object;")(destination->path[1..]); 
		object sess = get_session(destination, t);
		if(sess->createSubscriber)
		  sub = sess->createSubscriber(t); 
		else
	 	  sub = sess->createReceiver(t); 
		return sub;
    }

    object get_session(object destination, object t)
	{
		object factory = context->_method("lookup", "(Ljava/lang/String;)Ljava/lang/Object;")(destination->host); 
		object sub;
		object qc, s;

		if(t && t->getQueueName)
		{
		  if(destination->user)
            qc = factory->createQueueConnection(destination->user, destination->password); 	
		  else
	        qc = factory->createQueueConnection(); 
		  qc->start(); 
	      s = qc->createQueueSession(0, 0); 
		}
		else if(t && t->getTopicName)
		{
		  if(destination->user)
	        qc = factory->createTopicConnection(destination->user, destination->password); 
		  else
	        qc = factory->createTopicConnection(); 
		  qc->start(); 
	      s = qc->createTopicSession(0, 0); 			
		}
		sess = s;
		return s;
	}
		
	void destroy()
	{
		if(sub) 
			sub->close();
		if(pub)
			pub->close();
	}
	
}

class JMSSubscriber
{
	inherit JMSHandler;
	
	object controller;
	
	static void create(object _controller, object _context)
	{
		controller = _controller;
		::create(_controller->subscribes_to, _context);
	}

	void start_subscriber()
	{
		if(!controller)
		{
			throw(Error.Generic("cannot start subscriber without controller.\n"));
		}
		
		sub = get_subscriber(destination);
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

class JMSPublisher
{
	inherit JMSHandler;
	
	void simple_publish(string text, mapping|void properties)
	{
		if(!pub)
			pub = get_publisher(destination);

		object msg = sess->createTextMessage(text);

		if(properties && sizeof(properties))
		{
			foreach(properties; string key; mixed value)
			{
				if(floatp(value))
				{
					msg->setFloatProperty(key, value);
				}
				else if(intp(value))
				{
					msg->setIntProperty(key, value);
				}
				else
				{
					msg->setStringProperty(key, value);
				}
			}
		}
			
		pub->send(msg);
	}

	
}

