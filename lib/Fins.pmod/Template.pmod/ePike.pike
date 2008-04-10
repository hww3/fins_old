inherit .Simple;

constant TEMPLATE_EXTENSION = ".ep";

private int includes = 0;

string header = "";

string _sprintf(mixed ... args)
{
  return "ePike(" + templatename + ")";
}

//!
static void create(string _templatename, 
         .TemplateContext|void context_obj, int|void _is_layout)
{
	::create(_templatename, context_obj, _is_layout);
}

string parse_psp(string file, string realname, object|void compilecontext)
{
  // now, let's render some pike!

  array(Block) contents = psp_to_blocks(file, realname, compilecontext);
  string ps, h;
 
  [ps, h] = render_psp(contents, "", "", compilecontext);

  header += ("int is_layout = " + is_layout + ";\n");

  header += h;
  pikescript+=(
#"Fins.Template.TemplateContext context; 
  function get_simple_macro;
  static void create(Fins.Template.TemplateContext _context){
	 context = _context; 
	 get_simple_macro = context->view->get_simple_macro;
  }

  void render(String.Buffer buf, Fins.Template.TemplateData __d,object|void __view){
	mapping data = __d->get_data();
	function yield=lambda()
	  { 
		if(is_layout)
		{
			if(__view) __view->render(buf, __d);
		}
  		else throw(Error.Generic(\"invalid yield in non-layout template.\\n\"));
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
    else if(has_prefix(contents, "<%="))
    {
      string expr = String.trim_all_whites(contents[3..strlen(contents)-3]);
      return "// "+ start + " - " + end + "\n#line " + start + " \"" + filename + "\"\ncatch(buf->add((string)" + expr + "));\n";
	}
	else if(has_prefix(contents, "<%#"))
	{
		string keyword, exp = "";
	    string expr = String.trim_all_whites(contents[3..strlen(contents)-3]);
  	    int r = sscanf(expr, "%[A-Za-z0-9_] %s", keyword, exp);
      werror( "// "+ start + " - " + end + "\n#line " + start + " \"" + filename + "\"\ncatch(buf->add(get_simple_macro(\"" + keyword + "\")(__d, ([" + exp + "]) )));\n");
return	 "// "+ start + " - " + end + "\n#line " + start + " \"" + filename + "\"\n(buf->add(get_simple_macro(\"" + keyword + "\")(__d, ([" + exp + "]) )));\n";
	}
    else
    {
      string expr = String.trim_all_whites(contents[2..strlen(contents)-3]);
      return "// "+ start + " - " + end + "\n#line " + start + " \"" + filename + "\"\n" + expr + "\n";
    }
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