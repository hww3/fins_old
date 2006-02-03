
constant __version = "1.0";
constant __author = "Bill Welliver <bill@welliver.org>";

string serialize(mixed data)
{
  if(mappingp(data))
  {
    return (string).JSONObject(data);
  }
  else if(arrayp(data))
  {
    return (string).JSONArray(data);
  }
  else throw(Error.Generic("invalid dataset to serialize.\n"));

}

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

