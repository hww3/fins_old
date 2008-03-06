constant description = "Administrative Tool for Fins.";

int main(int argc, array argv)
{
   if(!argv || sizeof(argv) < 2)
   {
     werror("invalid arguments. usage: pike -x fins [command]\n");
     return 1;
   }

   program meth;

   string command = argv[1];

   switch(command)
   {
     case "create":
       meth = Fins.AdminTools.CreateApplication;       
       break;

     case "install":
       meth = Fins.AdminTools.InstallApplication;       
       break;

     case "start":
       meth = Fins.AdminTools.FinServe;       
       break;

     case "extract_locale":
       meth = Fins.AdminTools.LocaleExtractor;       
       break;

     case "model":
       meth = Fins.AdminTools.ModelBuilder;       
       break;

     default:
       werror("unknown command \"%s\".\n", command);
       werror("valid commands include: create, install, start, model\n");
       return 1;
       break;
   }

   array newargs = ({});
   if(sizeof(argv) > 2) newargs = argv[2..];

   object cmd = meth(newargs);

   int x = cmd->run();

   return x;
}
