inherit .Simple.pike;

string template_string;

//!
static void create(string _templatename, string _templatestring,
         .TemplateContext|void context_obj, int|void _is_layout)
{
   ::create(_templatename, context_obj, _is_layout);

   template_string = _templatestring;

   reload_template();
}


static void reload_template()
{
   last_update = time();

   string psp = parse_psp(template_string, templatename);
   script = psp;

   mixed x = gauge{
     compiled_template = compile_string(template, templatename);
   };

}

