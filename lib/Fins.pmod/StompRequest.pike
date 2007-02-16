inherit Fins.Request;

constant low_protocol = "Stomp";

object low_frame;
mapping headers;
string body;

static void create(Public.Protocols.Stomp.Client.Frame frame)
{
  low_frame = frame;

  headers = frame->get_headers();  
  body = frame->get_body();
}