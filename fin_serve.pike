#!/usr/local/bin/pike 

int main(int argc, array argv) {
  werror("WARNING: this program (%S) is deprecated. Please use 'pike -x fins start' instead.");
  string cmd_dir = dirname(argv[0]);
  if (sizeof(cmd_dir) > 0 &&
      (cmd_dir != ".") &&
      (cmd_dir != getcwd()))
    cd(cmd_dir);
  add_module_path("lib");
  program p = compile_string("inherit Fins.AdminTools.FinServe;");
  return p()->main(argc, argv);
}
