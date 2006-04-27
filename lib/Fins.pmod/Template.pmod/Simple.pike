inherit .Template;

constant TYPE_SCRIPTLET = 1;
constant TYPE_DECLARATION = 2;
constant TYPE_INLINE = 3;
constant TYPE_DIRECTIVE = 4;

string document_root = "";

private int includes = 0;

// should this be configurable?
int max_includes = 100;

static .TemplateContext context;

int auto_reload;
int last_update;

string script;
string templatename;
array contents = ({});
program compiled_template;
multiset macros_used = (<>);

string _sprintf(mixed ... args)
{
  return "SimpleTemplate(" + templatename + ")";
}

//!
static void create(string _templatename, .TemplateContext|void context_obj)
{
   context = context_obj;

   context->type = object_program(this);

   auto_reload = (int)(context->application->config["view"]["reload"]);
   templatename = _templatename + ".phtml";

   reload_template();
}

static void reload_template()
{
   last_update = time();

   string template = load_template(templatename);
   string psp = parse_psp(template, templatename);
   script = psp;

   mixed x = gauge{
     compiled_template = compile_string(template, templatename);
   };

}

//!
public string render(.TemplateData d)
{
   String.Buffer buf = String.Buffer();

   if(auto_reload && template_updated(templatename, last_update))
   {
     reload_template();
   }

    object t = compiled_template(context);
    t->render(buf, d);

   return buf->get();

}

program compile_string(string code, string realfile, object|void compilecontext)
{
  string psp = parse_psp(code, realfile, compilecontext);
//werror("PSP: %O\n", psp);
  return predef::compile_string(psp, realfile);
}


array(Block) psp_to_blocks(string file, string realfile, void|object compilecontext)
{
  int file_len = strlen(file);
  int in_tag = 0;
  int sp = 0;
  int old_sp = 0;
  int start_line = 1;
  array contents = ({});

  do 
  {
#ifdef DEBUG
    werror("starting point: %O, len: %O\n", sp, file_len);
#endif
    sp = search(file, "<%", sp);

    if(sp == -1) 
    {
      sp = file_len; 
      if(old_sp!=sp) 
      {
        string s = file[old_sp..sp-1];
        int l = sizeof(s) - sizeof(s-"\n");
        Block b = TextBlock(s, realfile);
        b->start = start_line;
        b->end = (start_line+=l);
        contents += ({b});
      }
    }// no starting point, skip to the end.

    else if(sp >= 0) // have a starting code.
    {
      int end;
      if(in_tag) { error("invalid format: nested tags!\n"); }
      if(old_sp>=0) 
      {
        string s = file[old_sp..sp-1];
        int l = sizeof(s) - sizeof(s-"\n");
        Block b = TextBlock(s, realfile);
        b->start = start_line;
        b->end = (start_line+=l);
        contents += ({b});
      }
      if((sp == 0) || (sp > 0 && file[sp-1] != '<'))
      {
        in_tag = 1;
        end = find_end(file, sp);
      }
      else { sp = sp + 2; continue; } // the start was escaped.

      if(end == 0) error("invalid format: missing end tag.\n");

      else 
      {
        in_tag = 0;
        string s = file[sp..end];
        Block b = PikeBlock(s, realfile, compilecontext);
        int l = sizeof(s) - sizeof(s-"\n");
        b->start = start_line;
        b->end = (start_line+=l);
        contents += ({b});
        
        sp = end + 1;
        old_sp = sp;
      }
    } 
  }
  while (sp < file_len);

  return contents;
}

string parse_psp(string file, string realname, object|void compilecontext)
{
  // now, let's render some pike!
  string pikescript = "";
  string header = "";
  string initialization = "";

  array(Block) contents = psp_to_blocks(file, realname, compilecontext);
  string ps, h;
 
  [ps, h] = render_psp(contents, "", "", compilecontext);


  foreach(macros_used; string macroname ;)
  {
    header += ("function __macro_" + macroname + ";");
    initialization += ("__macro_" + macroname + " = __context->view->get_simple_macro(\"" + macroname + "\");");
  }

  header += h;
  pikescript+=("object __context; static void create(object context){__context = context; " + initialization + "}\n void render(String.Buffer buf, Fins.Template.TemplateData __d){ mapping data = __d->get_data();\n");
  pikescript += ps;

  return header + "\n\n" + pikescript + "}";
}

array render_psp(array(Block) contents, string pikescript, string header, object|void compilecontext)
{
  foreach(contents, object e)
  {
    if(e->get_type() == TYPE_DECLARATION)
      header += e->render(compilecontext);
    else if(e->get_type() == TYPE_DIRECTIVE)
    {
      mixed ren = e->render(compilecontext);
      if(arrayp(ren))
        [pikescript, header] = render_psp(ren, pikescript, header, compilecontext);
    }
    else
      pikescript += e->render(compilecontext);
  }

  return ({pikescript, header});
}


int main(int argc, array(string) argv)
{

  string file = Stdio.read_file(argv[1]);
  if(!file) { werror("input file %s does not exist.\n", argv[1]); return 1;}

  string pikescript = parse_psp(file, argv[1]);

  write(pikescript);

  return 0;
}

int find_end(string f, int start)
{
  int ret;

  do
  {
    int p = search(f, "%>", start);
#ifdef DEBUG
werror("p: %O", p);
#endif
    if(p == -1) return 0;
    else if(f[p-1] == '%') {
#ifdef DEBUG
werror("escaped!\n"); 
#endif
start = start + 2; continue; } // (escaped!)
    else { 
#ifdef DEBUG
werror("got the end!\n"); 
#endif
ret = p + 1;}
  } while(!ret);
#ifdef DEBUG
werror("returning: %O\n", ret);
#endif
  return ret;
}

class Block(string contents, string filename, object|void compilecontext)
{
  int start;
  int end;

  int get_type()
  {
    return 0;
  }

  string _sprintf(mixed type)
  {
    return "Block(" + contents + ")";
  }

  array(Block) | string render(object|void compilecontext);
}

class TextBlock
{
 inherit Block;

 array in = ({"\\", "\"", "\n"});

 array out = ({"\\\\", "\\\"", "\\n"});

 string render(object|void compilecontext)
 {
   return "{\n" + escape_string(contents)  + "}\n";
 }

 
 string escape_string(string c)
 {
    string retval = "";
    int cl = start;
    int atend=0;
    int current=0;
    retval+="\n buf->add(";
    do
    {
       string line;
       int end = search(c, "\n", current);
       if(end != -1)
       {
         line = c[current..end];
         if(end == (strlen(c) -1))
           atend = 1;
         else current = end + 1;
       }
       if(end == -1)
       {
         line = c[current..];
         atend = 1;
       }
       line = replace(line, in, out);
       if(strlen(line))
       {
         cl++;
       } 
         retval+=("#line " + cl + " \"" + filename + "\"\n\"" + line + "\"\n");
    } while(!atend);

    retval+=");\n";
    return retval;

 }

}

class PikeBlock
{
  inherit Block;

  int get_type()
  {
    if(has_prefix(contents, "<%$")) return TYPE_INLINE;
//    if(has_prefix(contents, "<%!")) return TYPE_DECLARATION;
    if(has_prefix(contents, "<%@")) return TYPE_DIRECTIVE;
    else return TYPE_SCRIPTLET;
  }

  array(Block) | string render(object|void compilecontext)
  {
    if(has_prefix(contents, "<%!"))
    {
      string expr = contents[3..strlen(contents)-3];
      return("// "+ start + " - " + end + "\n#line " + start + " \"" + filename + "\"\n" + expr);
    }

    else if(has_prefix(contents, "<%@"))
    {
      string expr = contents[3..strlen(contents)-3];
      return parse_directive(expr, compilecontext);
    }

    else if(has_prefix(contents, "<%$"))
    {
      string expr = String.trim_all_whites(contents[3..strlen(contents)-3]);
      string i = "catch{";
      string f = "};";
      array e = expr/".";

      expr = "data";

      foreach(e;;string ep)
      {
        expr += "[\"" + ep + "\"]";
      }

      return(i + "\n// "+ start + " - " + end + "\n#line " + start + " \"" + filename + "\"\nbuf->add((string)(" + expr + "));" + f);
    }

    else
    {
      string expr = String.trim_all_whites(contents[2..strlen(contents)-3]);
      return "// "+ start + " - " + end + "\n#line " + start + " \"" + filename + "\"\n" + pikeify(expr) + "\n";
    }
  }

 string pikeify(string expr)
 {
   string cmd = "";
   string arg = "";

  array a = array_sscanf(expr, "%[a-zA-Z0-9_] %s");

  if(sizeof(a)>1) 
    arg = String.trim_all_whites(a[1]);
   cmd = a[0];


   if((<"if", "elseif", "foreach">)[expr])
   {
     if(sizeof(a) !=2)
     {
       throw(Error.Generic(sprintf("PSP format error: invalid command format in %s at line %d.\n", templatename, start)));
     }

   }
/*
   else 
   {
     cmd = expr;
   }
*/
   switch(cmd)
   {
     case "if":
       return " if( " + arg + " ) { \n";
       break;

     case "elseif":
       return " } else if( " + arg + " ) { \n";
       break;

     case "foreach":
       mapping a = p_argify(arg);
       if(!a->var && a->val)
       {
         throw(Error.Generic(sprintf("PSP format error: invalid foreach syntax in %s at line %d.\n", templatename, start)));
       }
       array ac = ({});

       foreach(a->var/".";;string v)
        ac += ({ "[\"" + v + "\"]" }); 
       return " catch { foreach(data" + (ac*"") + ";; mixed __q) {"
         "object __d = __d->clone(); __d->add(\"" + a->val + "\", __q); mapping odata=data; mapping data=odata + ([\"" + a->val + "\":__q]);" ;
       break;

     case "end":
       return " }}; // end \n";
       break;

     case "else":
       return " } else { \n";
       break;


     case "endif":
       return " } // endif \n";
       break;

     default:
       string rx = "";
       function f = context->view->get_simple_macro(cmd);
       if(!f)
         throw(Error.Generic(sprintf("PSP format error: invalid command at line %d.\n", start)));

       macros_used[cmd] ++;

       return ("{catch{ "
              " buf->add(__macro_" + cmd + "(__d, " + argify(arg) + "));};}");
       break;
   }

 }

 string argify(string arg)
 {

   array rv = ({});
   int keepgoing = 0;
   do{
    keepgoing = 0;
    string key, value;
    int r = sscanf(arg,  "%*[ \n\t]%[a-zA-Z0-9_]=\"%s\"%s", key, value, arg);
    if(r>2) keepgoing=1;
    if(r<=2) break;

    if(key && strlen(key))
    {
      rv += ({"\"" + lower_case(key) + "\":\"" + value + "\"" });
     }
   }while(keepgoing);
   return "([" + rv*", " + "])";
 }

 mapping p_argify(string arg)
 {
   mapping rv = ([]);
   int keepgoing = 0;
   do{
    keepgoing = 0;
    string key, value;
    int r = sscanf(arg,  "%*[ \n\t]%[a-zA-Z0-9_]=\"%s\"%s", key, value, arg);
    if(r>2) keepgoing=1;
    if(r<2) break;

    if(key && strlen(key))
      rv += ([lower_case(key): value ]);

   }while(keepgoing);
   return rv;
 }

 string|array(Block) parse_directive(string exp, object|void compilecontext)
 {
   exp = String.trim_all_whites(exp);
 
   if(search(exp, "\n")!=-1)
     throw(Error.Generic("PSP format error: invalid directive format in " + templatename + ".\n"));
 
   // format of a directive is: keyword option="value" ...
 
   string keyword;
 
   int r = sscanf(exp, "%[A-Za-z0-9\-] %s", keyword, exp);
 
   switch(keyword)
   {
     case "include":
       return process_include(exp, compilecontext);
       break;

     default:
       throw(Error.Generic("PSP format error: unknown directive " + keyword + " in " + templatename + ".\n"));
 
   }
 }

 // we don't handle absolute includes yet.
 array(Block) process_include(string exp, object|void compilecontext)
 {
   string file;
   string contents;

   if(includes > max_includes) throw(Error.Generic("PSP Error: too many includes, possible recursion in " + templatename + " !\n")); 

   includes++;

   int r = sscanf(exp, "%*sfile=\"%s\"%*s", file);
 
   if(r != 3) 
     throw(Error.Generic("PSP format error: unknown include format in " + templatename + ".\n"));

   contents = load_template(file, compilecontext);
 
 //werror("contents: %O\n", contents);
 
   if(contents)
   {
     array x = psp_to_blocks(contents, file, compilecontext);
     //werror("blocks: %O\n", x);
     return x;
   }

  }

}




