inherit .TransformField;

constant type = "MetaData";

static mapping metadata = ([]);
static string _metadata;

//!  provides a field that stores a mapping of data in another field 
//!
//!  data is stored and retrieved from the field in the row as it is accessed.
//!
//!  @example
//!
//!  in AppName.Model.Object:
//!    void post_define(
//!       add_field(Fins.Model.MetaDataField("newfieldname", "srcfield"));
//!    }

object get_md(mixed md, object i)
{
  if(!metadata[i->get_id()] || !metadata[i->get_id()] || _metadata != md)
  {
    _metadata = md;
    object lmd = MetaData(md, i, transformfield);
    metadata[i->get_id()] = lmd;
    return lmd;
  }
  else return metadata[i->get_id()];
}

static void create(string _name, string _transformfield, mixed ... args)
{
  ::create(_name, _transformfield, get_md, @args);
}


   class MetaData
   {
     string fieldname;
     mapping metadata = ([]);
     object obj;

     static mixed cast(string tn)
     {
       if(tn == "mapping")
        return metadata + ([]);
     }

     static int(0..1) _is_type(string tn)
     {
        if(tn =="mapping")
          return 1;
        else
          return 0;
     }

     static void create(mixed data, object i, string transformfield)
     {
       obj = i;
       fieldname = transformfield;

       if(data && strlen(data))
       {
         catch {
           metadata = decode_value(MIME.decode_base64(data));
         };
       }
     }

    Iterator _get_iterator()
    {
      return Mapping.Iterator(metadata);
    }

    array _indices()
     {
       return indices(metadata);
     }

     array _values()
     {
       return values(metadata);
     }

     static mixed _m_delete(mixed arg)
     {
       if(metadata[arg] && !zero_type(metadata[arg]))
       {
         m_delete(metadata, arg);
         save();
       }
     }


     mixed `[](mixed a)
     {
       return `->(a);
     }

     mixed `[]=(mixed a, mixed b)
     {
       return `->=(a,b);
     }

     mixed `->(mixed a)
     {
       if(a == "dump")
         return dump;
       if(a == "save")
         return save;

       if(metadata)
         return metadata[a];
       else return 0;
     }

     mixed `->=(mixed a, mixed b)
     {
       metadata[a] = b;
       save();
     }

   int save()
   {
      obj[fieldname] = dump();
      return 1;
   }

   string dump()
   {
     return MIME.encode_base64(encode_value(metadata));
   }

 }

