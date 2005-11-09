
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

   context->type = object_program(this);

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
      b->render(buf, data);
   }
     
   return buf->get();
}

static class RegexReplacer{

  static object regexp;
  static function split_fun;
  int max_iterations = 10;
  string match = "(:?{foreach:(?P<loopname>[a-zA-Z\\-_0-9]+)}(?:((?s).*?){end:(?P=loopname)}))"
       "|(:?{include:(?P<file>[a-zA-Z\\-_0-9/\\.]+)})"
       "|(:?{if:(?P<testid>[a-zA-Z0-9_\\-]+):(.*?)}(?:((?s).*?)({else:(?P=testid)}(?:((?s).*?)))?{endif:(?P=testid)}))"
       "|(:?{(:?(:?(!?[A-Za-z0-9_]+):)?(.*?))})";

  void create() {
    regexp = _Regexp_PCRE(match, Regexp.PCRE.OPTION.MULTILINE);
    split_fun = regexp->split;
  }

  array step(string template, array components, object context)
  {
     string sv;

     int i=0;
     for (;;)
     {
        array substrings = ({});
        array(int)|int v=regexp->exec(template,i);
       
        if (intp(v) && !regexp->handle_exec_error([int]v)) break;

         sv = template[i..v[0]-1];

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

/*        
         werror("got match: %O, subparts: %O", template[v[0]..v[1]-1], substrings);
*/
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
            components += ({ If(substrings[-2], 
                                  step(substrings[-1], ({}), context),
                                  ({})
                                ) 
                            });
         }
         
         // if:else
         if(sizeof(substrings)==11)
         {

            components += ({ If(substrings[-4], 
                                  step(substrings[-3], ({}), context),
                                  step(substrings[-1], ({}), context)
                                ) 
                            });
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
   
   void render(String.Buffer buf, .TemplateData data)
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
     included_template = .get_template(context->type || .Simple, template, context);
   }

   string _sprintf(mixed ... args)
   {
      return "Include(" + templateName + ")";
   }
      
   void render(String.Buffer buf, .TemplateData data)
   {
      buf->add(included_template->render(data));
   }

}

static class TextString(string contents)
{
   inherit Block;

   string _sprintf(mixed ... args)
   {
      return "TextString(" + contents + ")";
   }

      
   void render(String.Buffer buf, .TemplateData data)
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
   
   
   void render(String.Buffer buf, .TemplateData d)
   {
      mapping data = d->get_data();
      mapping m;
      m=data;
      array e = name/".";
      foreach(e;int i;string elem)
      {
         if(i==(sizeof(e)-1) && mappingp(m[elem]))
         {
				if(data->debug)
           		buf->add("<!-- ERROR: LAST ELEMENT " + elem + " IS A MAPPING.-->");
				else buf->add("");
            return;
         }
         else if(i!=(sizeof(e)-1) && !mappingp(m[elem]))
         {
				if(data->debug)
            	buf->add("<!-- ERROR: NON-FINAL ELEMENT " + elem + " IS NOT A MAPPING.-->");
				else buf->add("");
         }
         else if(i!=(sizeof(e)-1))
         {
            m = m[elem];
         }
         else if(i==(sizeof(e)-1))
         {
            if(!m[elem] && zero_type(m[elem])==1)
					if(data->debug)
               	buf->add("<!-- VALUE " + elem + " NOT FOUND -->");
					else buf->add("");
            else
               buf->add((string)m[elem]);
            
         }
         
      }
   }
}

static class MacroField(string name, function func, string arguments)
{
   inherit Block;
   
   string _sprintf(mixed ... args)
   {
      return "MacroField(" + name + ", " + arguments + ")";
   }
   
   
   void render(String.Buffer buf, .TemplateData data)
   {
//      werror("INSERTING: %s / %s from %O\n", name, arguments, data);
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
      
   void render(String.Buffer buf, .TemplateData data)
   {
      mapping d = data->get_data();
 //     werror("RENDERING " + scope + "\n");
      if(!d[scope] && zero_type(d[scope]==1))
      {
			if(data->debug)
         	buf->add("<!-- VALUE " + scope + " NOT FOUND -->");
			else buf->add("");
         return;
      }
      else if(d[scope] && ! arrayp(d[scope]))
      {
			if(data->debug)
				buf->add("<!-- VALUE " + scope + " NOT AN ARRAY -->");
			else buf->add("");
         return;
      }
      
      foreach(d[scope]; int num; mapping row)
      {
         foreach(contents;; Block b)
         {
            .TemplateData d = data->clone();
            d->add(scope, row);

            // we should be able to replace the scope element in data with the row.
            b->render(buf, d);
         }
      }
   }


}


static class If(string test, array ifval, array|void elseval)
{
   inherit Block;

   function eval_func;   

   string _sprintf(mixed ... args)
   {
      return "If(" + test + ")";
   }

   function compile_func(string test)
   {
     string tf = "int test(Fins.Template.TemplateData d){ mapping data = d->get_data(); if(" + test + ") return 1; else return 0; }";
     program tp = compile_string(tf);
     if(tp) return tp()->test;
     else return true_func;
   }

   int true_func(.TemplateData data)
   {
     return 1;
   }

   int eval(.TemplateData data)
   {
     if(!eval_func)
       eval_func = compile_func(test);
     if(!eval_func) werror("FAILED TO LOAD EVAL FUNC.\n");
     return eval_func(data);
   }
      
   void render(String.Buffer buf, .TemplateData data)
   {
      int testresult = eval(data);
      array resultset = ({});
      if(testresult)
      {
        resultset = ifval;
      }
      else
      {
        resultset = elseval;
      }

      foreach(resultset;; Block b)
      {
        b->render(buf, data );
      }
   }
}

