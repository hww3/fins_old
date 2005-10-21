//
//  Syntax of a simple template:
//
//  {element} : inserts the value of element into the placeholder.
//  {foreach:arr} data {endforeach:arr} : loops over each element of the array arr. each element
//      should be a mapping of data.
//

inherit .Template;

string templatename;
array contents = ({});
RegexReplacer s = RegexReplacer();
object context;

//!
static void create(string template, object|void context_obj)
{
   if(!context_obj)
     context = .TemplateContext();
   else
      context = context_obj;

   templatename = template;
mixed x = gauge{
   contents = compile_template(contents);
};

werror("COMPILE_TIME: %O\n", x);
}

static array compile_template(array contents)
{
   // TODO: we should be more thorough here.

   string template = load_template(templatename);
  
   contents = s->step(template, contents, context);

   return contents;
}

//!
public string render(.TemplateData data)
{
   String.Buffer buf = String.Buffer();  
   
   foreach(contents;;Block b)
   {
      b->render(buf, data->get_data());
   }
     
   return buf->get();
}

static class RegexReplacer{

  static object regexp;
  static function split_fun;
  int max_iterations = 10;
  string match = "(:?{foreach:(?P<loopname>[a-zA-Z\\-_0-9]+)}(?:((?s).*?){end:(?P=loopname)}))"
       "|(:?{include:(?P<file>[a-zA-Z\\-_0-9/\\.]+)})"
       "|(:?{if:(?P<testid>[a-zA-Z0-9_\\-]+):([a-zA-Z+\\-*/_0-9]+)}(?:((?s).*?)({else:(?P=testid)}(?:((?s).*?)))?{endif:(?P=testid)}))"
       "|(:?{(:?(:?(!?[A-Za-z0-9_]+):)?(.*?))})";

  void create() {
    regexp = _Regexp_PCRE(match, Regexp.PCRE.OPTION.MULTILINE);
    split_fun = regexp->split;
  }

  array step(string template, array components, object context)
  {
     string sv;
 //    werror("STEP: %O\n", template);

     int i=0;
     for (;;)
     {
        array substrings = ({});
        array(int)|int v=regexp->exec(template,i);
       
        if (intp(v) && !regexp->handle_exec_error([int]v)) break;

//        if (v[0]>i) buf->add(template[i..v[0]-1]);

         sv = template[i..v[0]-1];

 //        werror("SV: %O\n", sv);

         components += ({ TextString(sv) });

        if(sizeof(v)>2)
        {
          int c = 2;
          do
          {
            substrings += ({ template[v[c]..(v[c+1]-1)] });
            c+=2;
          }
          while(c<= (sizeof(v)-2));
        }

        
  //       werror("got match: %O, subparts: %O", template[v[0]..v[1]-1], substrings);

         // include
         if(sizeof(substrings) == 5)
         {
            if(context->num_includes +1 > context->max_includes)
            {
              throw(Error.Generic("Too many included files; hit limit at include of " + substrings[-1] + ".\n"));
            }
            context->num_includes++;
            components += ({ Include(substrings[-1], context) });
         }

         // replacement
         if(sizeof(substrings)==16)
         {
            // this should be a replacement reference.
            function f;
            if(has_prefix(substrings[-2], "!"))
            {
              f = .get_simple_macro(substrings[-2][1..]);
              if(f)
                components += ({ MacroField(substrings[-2][1..], f, substrings[-1]) });
              else components += ({ TextString("UNKNOWN MACRO " + substrings[-2][1..]) });
            }
            else
              components += ({ ReplaceField(String.trim_whites(substrings[-2]), String.trim_whites(substrings[-1])) });
            
         }
         
         // if
         if(sizeof(substrings)==9)
         {
            werror("GOT IF\n");
         }
         
         // if:else
         if(sizeof(substrings)==9)
         {
            werror("GOT IF_ELSE\n");
         }
         
         // foreach
         if(sizeof(substrings)==3)
         {
            array c = ({});
            components += ({ Foreach(substrings[1], step(substrings[2], c, context)) });
         }
         i=v[1];
     }

     sv = template[i..];
   //  werror("SV: %O\n", sv);
     components += ({ TextString(sv) });

     return components;
     
  }

   void replace(String.Buffer buf, string subject,string|function(String.Buffer,string,array|void:string) with, mixed|void data)
   {
      int i=0;
      for (;;)
      {
         array substrings = ({});
         array(int)|int v=regexp->exec(subject,i);

         if (intp(v) && !regexp->handle_exec_error([int]v)) break;

         if (v[0]>i) buf->add(subject[i..v[0]-1]);

         if(sizeof(v)>2)
         {
           int c = 2;
           do
           {
             substrings += ({ subject[v[c]..(v[c+1]-1)] });
             c+=2;
           }
           while(c<= (sizeof(v)-2));
         }

         if (stringp(with)) buf->add(with);
         else with(buf, subject[v[0]..v[1]-1], substrings, data);

         i=v[1];
      }

      buf->add(subject[i..]);

   }

}



static class Block
{
   
   void render(String.Buffer buf, mapping data)
   {
      
   }
   
}

static class Include
{
   inherit Block;

   string templateName;
   .Template included_template;

   static void create(string template, void|object context)
   {
     templateName = template;
     included_template = .get_template(.Simple, template, context);
   }

   string _sprintf(mixed ... args)
   {
      return "Include(" + templateName + ")";
   }
      
   void render(String.Buffer buf, mapping data)
   {
      .TemplateData d = .TemplateData();
      d->set_data(data);
      buf->add(included_template->render(d));
   }

}

static class TextString(string contents)
{
   inherit Block;

   string _sprintf(mixed ... args)
   {
      return "TextString(" + contents + ")";
   }

      
   void render(String.Buffer buf, mapping data)
   {
      buf->add(contents);
   }
}


static class ReplaceField(string scope, string name)
{
   inherit Block;
   
   string _sprintf(mixed ... args)
   {
      return "ReplaceField(" + scope + "." + name + ")";
   }
   
   
   void render(String.Buffer buf, mapping data)
   {
 //     werror("INSERTING: %s / %s from %O\n", scope, name, data);
      if(scope && strlen(scope) && data[scope] && mappingp(data[scope]))
      {
         if(data[scope][name] || zero_type(data[name]) != 1)
            buf->add(data[scope][name]);
         else
            buf->add("<!-- VALUE " + scope + "." + name + " NOT FOUND -->");
      }
      else if(!data[name] && zero_type(data[name])==1)
         buf->add("<!-- VALUE " + name + " NOT FOUND -->");
      else
         buf->add(data[name]);
   }
}

static class MacroField(string name, function func, string arguments)
{
   inherit Block;
   
   string _sprintf(mixed ... args)
   {
      return "MacroField(" + name + ", " + arguments + ")";
   }
   
   
   void render(String.Buffer buf, mapping data)
   {
      werror("INSERTING: %s / %s from %O\n", name, arguments, data);
        buf->add(func(data, arguments));
   }
}

static class Foreach(string scope, array contents)
{
   inherit Block;
   
   string _sprintf(mixed ... args)
   {
      return "Foreach(" + scope + ")";
   }
      
   void render(String.Buffer buf, mapping data)
   {
 //     werror("RENDERING " + scope + "\n");
      if(!data[scope] && zero_type(data[scope]==1))
      {
         buf->add("<!-- VALUE " + scope + " NOT FOUND -->");
         return;
      }
      else if(data[scope] && ! arrayp(data[scope]))
      {
         buf->add("<!-- VALUE " + scope + " NOT AN ARRAY -->");
         return;
      }
      
      foreach(data[scope]; int num; mapping row)
      {
         foreach(contents;; Block b)
         {
            // we should be able to replace the scope element in data with the row.
            b->render(buf, data + ([scope: row]) );
         }
      }
   }


}
