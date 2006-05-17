import Tools.Logging;
import Fins;

string real_deflate(string _data, string _name)
{
  int level = 9;
   _data = Gz.deflate(level)->deflate(_data);

  return _data;
}

string deflate(string data, object id)
{
  data = real_deflate(data, "cache disable, no name");
  return data[2..sizeof(data)-5];
}

string gzip_PrintFourChars(int val)
{
  string result = "";
  for (int i = 0; i < 4; i ++)
  {
    result += sprintf("%c", val % 256);
    val /= 256;
  }
  return result;
}

string gzip(string data, object id)
{
  string deflated = deflate(data, id);
  // transform deflate data into gzip one
  // see RFC1952 for the format
  data = "\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\x03" + deflated 
   + gzip_PrintFourChars(Gz.crc32(data))
   + gzip_PrintFourChars(strlen(data));
  return data;
}

int filter(object request, object response, mixed ... args)
{ 
  string type = request->get_compress_encoding(); // does the browser support it ?

  if(type && !response->get_header("Content-Encoding")) // don't encode on already encoded
  {
      string nd = response->get_data();
      if(!nd || sizeof(nd) < 256) return 1;
      if(type=="deflate")
      {
        nd = deflate(response->get_data(), request);
        Log.debug("Deflating " + sizeof(response->get_data()) + " to " + sizeof(nd)); 
        response->set_header("Content-Encoding", "deflate");
	response->set_data(nd);
      }
      else if(type=="gzip")
      {
        nd = gzip(response->get_data(), request);
        Log.debug("Gzipping " + sizeof(response->get_data()) + " to " + sizeof(nd)); 
        response->set_data(nd);
	response->set_header("Content-Encoding", "gzip");
      }
  }

  return 1;
}
