//
//  Syntax of a simple template:
//
//  {element} : inserts the value of element into the placeholder.
//  {foreach:arr} data {endforeach:arr} : loops over each element of the array arr. each element
//      should be a mapping of data.
//

inherit .Template;

static mapping data = ([]);
string templatename;

RegexReplacer r = RegexReplacer("{([A-Za-z0-9_\-]+)}");
RegexReplacer s = RegexReplacer("{foreach:([a-zA-Z\\-_0-9]+)}(?:((?s).*?){endforeach:\\1})");

static void create(string template)
{
   templatename = template;
}

void replacer_function(String.Buffer buf, string fullmatch, array components, mixed|void d)
{
   werror("have %O\n", components);
   
   if(components && sizeof(components))
   {
      // we're really only interested in the first component.
      if(d[components[0]])
      {
         buf->add(d[components[0]]);
      }
      else
      {
         buf->add(fullmatch);
      }
   }
}

void foreach_replacer_function(String.Buffer buf, string fullmatch, array components, mixed|void d)
{
   string scope = "";
   werror("found a foreach.\n");
   if(components && sizeof(components) > 1)
   {
      // we're really only interested in the first component.
      scope = components[0]; 
      if(d[scope] && arrayp(d[scope]))
      {
         foreach(d[scope];;mixed a)
         {
            r->replace(buf, components[1], replacer_function, a);
         }
      }
      
   }
}

void set_data(mapping d)
{
   data = d;
}

string render()
{
   String.Buffer buf = String.Buffer();

   // TODO: we should be more thorough here.
   string template = Stdio.read_file("templates/" + templatename);
   
  
   r->replace(buf, template, replacer_function, data);
   s->replace(buf, buf->get(), foreach_replacer_function, data);
   
   
   return buf->get();
}

class RegexReplacer{

  static object regexp;
  static function split_fun;
  int max_iterations = 10;

  void create(string match) {
    regexp = _Regexp_PCRE(match, Regexp.PCRE.OPTION.MULTILINE);
    split_fun = regexp->split;
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

