import Fins;
import Tools.Logging;
inherit Processor;

//! A processor for handling incoming messages via SMTP.
//!
//! configuration data:
//!
//! [processors]
//! processor=my_smtp_processor
//! 
//! [smtp]
//! port=portnum
//! host=bindhost
//! domain=relaydomain1
//! domain=relaydomainn

object smtp;

program server = Protocols.SMTP.Server;

array supported_protocols()
{
  return ({"SMTP"});
}

void start()
{
  if(!config["smtp"])
    throw(Error.Generic("No SMTP configuration section.\n"));

  else
  {
    int port = (int)(config["smtp"]["port"]);
    string host = config["smtp"]["host"];
    array|string domains = config["smtp"]["domain"];
    if(stringp(domains)) domains = ({ domains });
    smtp = server(domains, port, host, _cb_mailfrom, _cb_rcptto, _cb_data);
  }
}

int|array _cb_mailfrom(string email)
{
  return 250;
}

int|array _cb_rcptto(string email)
{
  return 250;
}

int|array _cb_data(object mime, string sender, array(string) recipient, 
                     void|string raw)
{
  return 250;
}


