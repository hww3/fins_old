string simple_macro_javascript_includes(Fins.Template.TemplateData data, mapping|void args)
{
  return 
#" <script src=\"/static/javascripts/prototype.js\" type=\"text/javascript\"></script> 
<script src=\"/static/javascripts/scriptaculous.js\" type=\"text/javascript\"></script>
";
}

//!
//! args:
//!
//! method
//! url
//! parameters
//! update
//! updatesuccess
//! updatefailure
//! before
//! after
//! condition
//!
string simple_macro_remote_form(Fins.Template.TemplateData data, mapping|void arguments)
{

  if(arguments["updatesuccess"] || arguments["updatefailure"])
  {
    arguments["update"] = ([]);

    if(arguments["updatefailure"]);
      arguments["update"]["failure"] = arguments["updatefailure"];
    if(arguments["updatesuccess"]);
      arguments["update"]["success"] = arguments["updatesuccess"];
  }  

  return "<form onsubmit=\"" + remote_function(arguments) + "; return false;\"" 
//action=\"" 
//     + arguments["action"] 
+ "\" method=\"" + (arguments["method"]||"post")
     + "\">";
}

string options_for_ajax(mapping options)
{
  string result = "";
  array kvp = ({});

  foreach(options; string name; string value)
  {
    if(has_prefix(name, "on")) name = "on" + String.capitalize(name[2..]);
    kvp += ({ name + ": " + value});
  }

  result = "{" + kvp*", " + "}";

  return result;
}


string remote_function(mapping options)
{
  string javascript_options = options_for_ajax(options);
 
  string update = "";

  if(options->update && mappingp(options->update))
  {
    array u = ({});

    if(options->update->success)
      u += ({"success: '" + options->update->success + "'"});
    if(options->update->failure)
      u += ({"failure: '" + options->update->failure + "'"});
    update = "{" + (u*", ") + "}";
  }
  else
  {
    update = options->update;
  }

  string func = ((!options->update)?
           "new Ajax.Request(":
           ("new Ajax.Updater(" + options->update )) + ", ";
 
         func += options->url;
         func += ", " + javascript_options;


  if(options->before)
    func = options->before + "; " + func;
  if(options->after)
    func = func + "; " + options->after;
  if(options->condition)
    func = "if(" + options->condition + ") { " + func + "; }";

  // we need to provide "confirm option handling.
  func+=")"; 
  return func;
}
