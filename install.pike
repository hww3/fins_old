#!/usr/local/bin/pike

int main(int argc, array argv) {
  string cmd_dir = dirname(argv[0]);
  if (sizeof(cmd_dir) > 0 &&
      (cmd_dir != ".") &&
      (cmd_dir != getcwd()))
    cd(cmd_dir);
  add_module_path("lib");
  program p = compile_string("inherit Fins.PackageInstaller;");
  return p()->main(argc, argv);
}
