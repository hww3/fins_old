import Tools.Logging;

object app;
//Fins.Application app;
string project;
string config_name = "dev";
array commands;
int overwrite = 0;
string model_id = "_default";
object context;

// obj->is_resolv_joinnode
// obj->joined_modules[0]->dirname

void create(array args)
{
	int argc;
	
//  Log.set_level(0);
  Log.info("ModelBuilder module loading");

  if(!sizeof(args))
  {
    Log.error("ModelBuilder requires the name of the application to work with.");
    exit(1);
  }

  foreach(Getopt.find_all_options(args,aggregate(
    ({"help",Getopt.NO_ARG,({"--help"}) }),
    ({"config",Getopt.HAS_ARG,({"--config", "-c"}) }),
    ({"model",Getopt.HAS_ARG,({"--model", "-m"}) }),
    ({"force",Getopt.NO_ARG,({"--force", "-f"}) }),
    )),array opt)
    {
      switch(opt[0])
      {
        case "help":
  		  print_help();
		  return 0;
		  break;
        case "config":
          config_name = opt[1];
		  break;
        case "model":
          model_id = opt[1];
		  break;
       case "force":
          overwrite ++;
		  break;
	  }
	}

	args-=({0});
	argc = sizeof(args);

  if(argc) project = args[0];

  if(argc>1)
    commands = args[1..];
}

int run()
{
  object ddm;
  object dim;
  string ddmloc;
  string dimloc;

  Log.info("ModelBuilder module running.");

  project = combine_path(getcwd(), project);

  app = Fins.Loader.load_app(project, config_name);  

  Log.debug("Application loaded.");

  if(!app->model) 
  {
	Log.error("You cannot run ModelBuilder without a model.");
	Log.error("Please add a model section to your configuration");
	Log.error("and specify a database to use.");
	return 1;
  }

  context = Fins.Model.get_context(model_id); 

  if(!context->repository->get_model_module())
  {
	Log.error("No datatype definition module specified.");
	return 1;	
  }
  else
    ddm = context->repository->get_model_module();

  if(!context->repository->get_object_module())
  {
	Log.warn("No datatype instance module specified, so we won't work with that.");
//	return 1;	
  }
  else
    dim = context->repository->get_object_module();

  Log.debug("Model is connected to " + context->sql_url + ".");
  Log.debug("Checking Model module directories.");

  // okay, first, let's see if the two modules are directories.
  ddmloc = Fins.Util.get_path_for_module(ddm);
  if(!ddmloc || !file_stat(ddmloc)->isdir || (ddmloc/"/")[-1] == "module.pmod")
  {
	Log.error("Datatype definition module is not a directory. We can't continue.");
    return 1;
  }
  else Log.debug("Datatype definition classes will be stored in " + ddmloc);

  if(dim)
  {
    dimloc = Fins.Util.get_path_for_module(dim);
    if(!ddmloc || !file_stat(ddmloc)->isdir || (ddmloc/"/")[-1] == "module.pmod")
    {
	  Log.error("Datatype instance module is not a directory. We can't continue.");
      return 1;
    }
    else Log.debug("Datatype instance classes will be stored in " + dimloc);
  }

  if(!commands) 
  {
	Log.error("Error: no command given.");
        print_help();
	return 1;
  }

  if(!(<"add", "scan">)[commands[0]])
  {
	Log.error("Error: bad command " + commands[0] + " given.");
        print_help();
	return 1;
  }

  if(commands[0] != "scan" && sizeof(commands) < 2)
  {
	Log.error("Error: no tables given.");
        print_help();
	return 1;
  }
  
  int errorout;

  array tables_to_add = commands[1..];

  if(commands[0] == "scan")
  {
    tables_to_add = do_scan();
    Log.info("Scan found %d tables to add: %s", sizeof(tables_to_add), tables_to_add * ", ");
  }

  foreach(tables_to_add; int i; string t)
  {
    array x = context->sql->list_tables(t);
    if(!sizeof(x))
    {
	  Log.error("Table \"" + t + "\" does not exist.");
      errorout++;	
    }
  }

  if(errorout)
  {
	Log.error("Aborting due to missing tables.");
	return 1;
  }

  Log.debug("Model ID is " + model_id + ". If you change this, things will break!");

  foreach(tables_to_add; int i; string t)
  {
  // first, we figure out what the object should be called.
    string objname = Tools.Language.Inflect.singularize(t);
    objname = String.capitalize(objname);
    Log.info("Creating objects for data type " + objname + ", sourced from table " + t + ".");

    string ddc = "// auto-generated by Fins.AdminTools.ModelBuilder for table " + t + ".\n\ninherit Fins.Model.DataObject;\n\n"
				 "void post_define(Fins.Model.DataModelContext context)\n{\n// Add any post configuration logic here\n\n// set_alternate_key(\"myalternatekey\");\n\n}\n\n";
    string dic = "// auto-generated by Fins.AdminTools.ModelBuilder.\n\ninherit Fins.Model.DirectAccessInstance;\n"
	             "string context_name = \"" + model_id + "\";\n"
	             "string type_name = \"" + objname + "\";\n\n";

    string fn = combine_path(ddmloc, objname + ".pike");
    if(file_stat(fn) && !overwrite)
      Log.warn("file " + fn + " already exists... skipping.");
    else
    {
      Stdio.write_file(fn, ddc);
      Log.info("Wrote new data definition class " + fn + ".");
    }
	fn = combine_path(dimloc, objname + ".pike");
    if(file_stat(fn) && !overwrite)
      Log.warn("file " + fn + " already exists... skipping.");
	else
    {
      Stdio.write_file(fn, dic);
      Log.info("Wrote new data instance class " + fn + ".");
    }
  }

  return 0;
}

int has_id(string table)
{
  int haveid = 0;
  array f = context->sql->list_fields(table, "id");
  foreach(f;; mapping field)
  {
    if(field->name == "id") haveid++;
  }
  return haveid;
}

array do_scan()
{
  array t;
  array ta = ({});

  t = context->sql->list_tables();

  foreach(t;;string table)
  {
    array components = table / "_";

    if(sizeof(components) == 1)
    {
      if(has_id(table))
        ta += ({ table });
      else
        Log.debug("Table " + table + " has no id field. Skipping.");
    }

    else
    {
      array joinedtables = ({});
      // search for the two possibly joined tables.
      foreach(t;; string pt)
      {
        if(search(table, pt) != -1)
        {
          // found one possible part, see if it has a properly formatted id field.
          string fn = lower_case(Tools.Language.Inflect.singularize(pt)) + "_id";
          array jf = context->sql->list_fields(table, fn);
          int foundit;
          foreach(jf;; mapping jfd) if(jfd->name == fn) foundit++;
          if(foundit)
            joinedtables += ({ pt });
        }
      }

      // if, after searching all of the tables, we find 2 tables 
      // referenced, it's a join-table, and we can ignore it. otherwise,
      // we should ask.
      if(sizeof(joinedtables) != 2 && !has_id(table))
      {
        Log.info("*** We found a table, " + table + ", that looks like it might ");
        Log.info("    be a join-table between two other types. ");
        Log.info("    However, it doesn't seem to have the right fields in it ");
        Log.info("    for its name, or its referenced tables are missing.");
        Log.info("    If this assumption is incorrect, you can fix the schema to resolve the problem");
        Log.info("    and rerun the scan.");
      }
      else if(has_id(table))
      {
        Log.info("*** We found a table, " + table + ", that looks like it might ");
        Log.info("    be a join-table between two other types. ");
        Log.info("    It does have a correct ID field, so we assume it is a type");
        Log.info("    that just happens to have an underbar in it.");
        Log.info("    If that's not correct, you can remove the generated class files ");
        Log.info("    from your application's modules directory.");
        ta+=({table});
       
      }

    }
  }

  return ta;
}

void print_help()
{
	werror("Usage: pike -x fins model [-f|--force] [-c config] [-m modelid] AppDir (scan | [add table [table1... tableN]])\n");
	return;
}
