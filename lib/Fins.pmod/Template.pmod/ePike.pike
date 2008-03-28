inherit .Simple;

constant TEMPLATE_EXTENSION = ".ep";

string header = 
#"
void _yield()
{
  if(is_layout)
  {
    if(__view) __view->render(buf, __d);
  }
  else throw(Error.Generic(\"invalid yield in non-layout template.\n\"));
}
";

string _sprintf(mixed ... args)
{
  return "ePike(" + templatename + ")";
}


string parse_psp(string file, string realname, object|void compilecontext)
{
  // now, let's render some pike!

  array(Block) contents = psp_to_blocks(file, realname, compilecontext);
  string ps, h;
 
  [ps, h] = render_psp(contents, "", "", compilecontext);

  header += ("int is_layout = " + is_layout + ";\n");

  foreach(macros_used; string macroname ;)
  {
    header += ("function __macro_" + macroname + ";");
    initialization += ("__macro_" + macroname + " = __context->view->get_simple_macro(\"" + macroname + "\");");
  }

  header += h;
  pikescript+=("object __context; static void create(object context){__context = context; " + initialization + 
#"}
  void render(String.Buffer buf, Fins.Template.TemplateData __d,object|void __view){
	mapping data = __d->get_data();
	function yield=lambda()
	  { 
		if(is_layout)
		{
			if(__view) __view->render(buf, __d);
		}
  		else throw(Error.Generic(\"invalid yield in non-layout template.\n\"));
	};"
	);
  pikescript += ps;

  return header + "\n\n" + pikescript + "}";
}

class PikeBlock
{
  inherit Block;

  int get_type()
  {
    if(has_prefix(contents, "<%$")) return TYPE_INLINE;
    if(has_prefix(contents, "<%!")) return TYPE_DECLARATION;
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
      string i = "catch{ mixed expr; ";
      string f = "};";
      array e = expr/".";

      expr = "data";

      foreach(e;;string ep)
      {
        expr += "[\"" + ep + "\"]";
      }

      return(i + "\n// "+ start + " - " + end + "\n#line " + start + " \"" + filename + "\"\nexpr = " + expr + "; buf->add((string)(!zero_type(expr)?expr:\"\"));" + f);
    }

    else
    {
      string expr = String.trim_all_whites(contents[2..strlen(contents)-3]);
      return "// "+ start + " - " + end + "\n#line " + start + " \"" + filename + "\"\n" + expr + "\n";
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
       string start = "";
       if(a->var[0] == '$')
       {
         foreach((a->var[1..])/".";;string v)
          ac += ({ "[\"" + v + "\"]" });
          start = "data" + (ac * "");
       }    
       else start = "\"" + a->var + "\"";    
       if(!a->ind) a->ind = a->val + "_ind";

       return " catch { foreach(" + start + ";mixed __v; mixed __q) {"
         "object __d = __d->clone(); __d->add(\"" + a->val + "\", __q); __d->add(\"" + a->ind + "\", __v); "
         "mapping data = __d->get_data(); data[\"" + a->val + "\"]=__q; data[\"" + a->ind + "\"] = __v;" ;
       break;

     case "end":
       return " }}; // end \n";
       break;

     case "else":
       return " } else { \n";
       break;

     case "yield":
       if(is_layout)
       {
         return "if(__view) __view->render(buf, __d);";
       }
       else throw(Error.Generic("invalid yield in non-layout template.\n"));
       break;

     case "endif":
       return " } // endif \n";
       break;

     default:
       string rx = "";
       function f = context->view->get_simple_macro(cmd);
       if(!f)
         throw(Error.Generic(sprintf("PSP format error: invalid command at line %d.\n", (int)start)));

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

	 case "project":
	   return process_project(exp, compilecontext);
       break;

     default:
       throw(Error.Generic("PSP format error: unknown directive " + keyword + " in " + templatename + ".\n"));
 
   }
 }

 string|array(Block) process_project(string exp, object|void compilecontext)
 {
	string project;
	
	 int r = sscanf(exp, "%*sname=\"%s\"%*s", project);

	   if(r != 3) 
	     throw(Error.Generic("PSP format error: unknown project format in " + templatename + ".\n"));
//		werror("project is %O\n", backtrace() );
	 return "__d->get_request()->_locale_project = \"" + project + "\";";
	
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