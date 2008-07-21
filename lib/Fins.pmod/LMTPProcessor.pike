import Fins;
import Tools.Logging;
inherit Processor;

//! A processor for handling incoming messages via LMTP.
//!
//! configuration data:
//!
//! [processors]
//! processor=my_lmtp_processor
//! 
//! [lmtp]
//! port=portnum
//! host=bindhost
//! domain=relaydomain1
//! domain=relaydomainn

object lmtp;

array supported_protocols()
{
  return ({"LMTP"});
}

void start()
{
  if(!config["lmtp"])
    throw(Error.Generic("No LMTP configuration section.\n"));

  else
  {
    int port = (int)(config["lmtp"]["port"]);
    string host = config["lmtp"]["host"];
    array|string domains = config["lmtp"]["domain"];
    if(stringp(domains)) domains = ({ domains });
    lmtp = Protocols.LMTP.Server(domains, port, host, 
	_cb_mailfrom, _cb_rcptto, _cb_data);
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

int|array _cb_data(object mime, string sender, string recipient, 
                     void|string raw)
{
  return 250;
}


