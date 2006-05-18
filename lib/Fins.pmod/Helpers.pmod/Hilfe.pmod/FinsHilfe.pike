import Tools.Hilfe;

constant my_version = "0.4";

  inherit Tools.Hilfe.StdinHilfe;

   void print_version()
   {
     safe_write("Fins " + my_version + " running " + version() +
              " / Hilfe v3.5 (Incremental Pike Frontend)\n");
   }

