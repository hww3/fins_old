import Tools.Logging;

string project;
string config_name = "dev";

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
    )),array opt)
    {
      switch(opt[0])
      {
        case "help":
		print_help();
		return 0;
		break;
	  }
	}

	args-=({0});
	argc = sizeof(args);

  if(argc) project = args[0];
  if(argc>=2) config_name = args[1];
}

int run()
{
  Log.info("ModelBuilder module running.");

  Fins.Application app = Fins.Loader.load_app(project, config_name);  

  Log.debug("Application loaded.");

  if(!app->model) 
  {
	Log.error("You cannot run ModelBuilder without a model.");
	return 1;
  }

  if(!app->model->datatype_instance_module)
  {
	Log.error("No datatype instance module specified.");
	return 1;	
  }

  if(!app->model->datatype_definition_module)
  {
	Log.error("No datatype definition module specified.");
	return 1;	
  }

  return 0;
}

void print_help()
{
	return;
}
