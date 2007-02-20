static object __stomp_processor_object;

int publish(string destination, string contents, void|mapping headers)
{
  if(!__stomp_processor_object)
   __stomp_processor_object = this->app->get_processor("Stomp");

  if(!__stomp_processor_object)
  {
    throw(Error.Generic("no Stomp processor loaded.\n"));
  }

  else
    return __stomp_processor_object->publish(destination, contents, headers);
}