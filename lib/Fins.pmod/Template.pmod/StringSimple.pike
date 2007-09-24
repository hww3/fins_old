inherit .Simple;

string template_string;

//!
static void create(string _templatestring,
         .TemplateContext|void context_obj, int|void _is_layout)
{
   template_string = _templatestring;
   ::create("template_from_string", context_obj, _is_layout);
}


static void reload_template()
{
   last_update = time();

   mixed x = gauge{
     compiled_template = compile_string(template_string, templatename);
   };

}

