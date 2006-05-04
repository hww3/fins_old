#!/usr/local/bin/pike -Mlib/

int main(int argc, array argv) {
  if (Stdio.exist("lib") && Stdio.is_dir("lib") && 
      Stdio.exist("lib/Fins.pmod") && Stdio.is_dir("lib/Fins.pmod")) {
    // We can safely assume we're in the fins root dir.
    add_module_path("lib");
    program p = compile_string("inherit Fins.PackageInstaller;");
    return p()->main(argc, argv);
  }
  else {
    werror("This script must be run from within the Fins root directory.\n\n");
    return 1;
  }
}
