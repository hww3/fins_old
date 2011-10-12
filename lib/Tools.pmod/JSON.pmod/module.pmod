
constant __version = "1.0";
constant __author = "Bill Welliver <bill@welliver.org>";

//!
//! serialize an object as a JSON string
//!
string serialize(mapping|array data, object|void filter_context)
{
  if(mappingp(data))
  {
    return (string).JSONObject(data, filter_context);
  }
  else if(arrayp(data))
  {
    return (string).JSONArray(data, filter_context);
  }
  else throw(Error.Generic("invalid dataset to serialize.\n"));

}
function serialise = serialize;

//!
//! deserialize a JSON string into native datatypes (arrays, mappings, etc)
//!
mixed deserialize(string json)
{
  return (mapping).JSONObject(json);
}
function deserialise = deserialize;

object Null = null();

class null
{
  constant JSONNull = 1;

  static string cast(string type)
  {
    if(type == "string")
      return "null";
  }
}

