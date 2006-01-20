
constant __version = "1.0";
constant __author = "Bill Welliver <bill@welliver.org>";


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
