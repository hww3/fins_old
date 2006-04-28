#!/usr/local/bin/pike -Mlib/

import Tools.Logging;

int main(int argc, array argv) {
  if (sizeof(argv) < 2)
    return usage(argv);
  string package = argv[1];
  if ((sizeof(package) > 7) && (package[0..6] == "http://")) {
    // Download the package with HTTP.
    write("Downloading packge from %s... ", package);
    array nice = Protocols.HTTP.get_url_nice(package);
    if (arrayp(nice) && sizeof(nice)) {
      write("done (%d bytes).\n", sizeof(nice[1]));
      return install_package(nice[1]);
    }
    else {
      werror("Failed to download package from %s\n", package);
      return 1;
    }
  }
  else if (Stdio.exist(package) && Stdio.is_file(package)) 
    return install_package(Stdio.read_file(package));
  else
    werror("Unknown package, %s.\n\n", package);
    return usage(argv);
}

int usage(array argv) {
  write(
      "Usage: %s [package]\n\n"
      "\tpackage\tEither a path or HTTP URL to a Fins package file.\n\n",
      basename(argv[0])
    );
  return 1;
}

int install_package(string package) {
  program p;
  object ee = ErrorContainer();
  master()->set_inhibit_compile_errors(ee);
  mixed err = catch(p = compile_string(package));
  if (stringp(ee->get()) && sizeof(ee->get())) {
    Log.critical("Error.  Package file corrupt.");
    return 1;
  }
  else if (err) {
    Log.critical("Error.  Package file corrupt.");
    return 1;
  }
  master()->set_inhibit_compile_errors(0);
  return p()->main();
}

static class ErrorContainer() {

  array err = ({});

  string get() {
    string ret = "";
    foreach(err, mixed el) {
      if (arrayp(el)) {
        ret += sprintf("%s:%d:%s\n", basename(el[0]), el[1], el[2]);
      }
      else
        ret += sprintf("%O\n", el);
    }
    return ret;
  }

  void compile_error(string filename, int line, string msg) {
    err += ({ ({ filename, line, msg }) });
  }

  void compile_warning(string filename, int line, string msg) {
    err += ({ ({ filename, line, msg }) });
  }

  void compile_exception(mixed exception) {
    err += ({ exception });
  }

}
