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

     case "start":
       meth = Fins.AdminTools.FinServe;       
       break;

     default:
       werror("unknown command %s.\n", command);
       return 1;
       break;
   }

   array newargs = ({});
   if(sizeof(argv) > 2) newargs = argv[2..];

   object cmd = meth(newargs);

   return cmd->run();
}
