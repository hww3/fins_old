constant NAME = "teh_installz0r";
constant PORT = 8080;
constant DEBUG = 0;
constant CONFIG = "dev";
constant SOURCE = "H4sIAC7EUUQAA+3OMQrCQBAF0K09xR5hN66xFkxpkxtY2IgYMEnh7Q2xslEsggjvTfFhZorfNrv9\r\noQmLSpO6lDm39eYlZzmHnEpV1qVKZdrnaeoQ07K1nsZ+ON5iDOfr8Pbv0/1P3bsxXrr+tPp1EQAA\r\nAAAAAAAAAL7yAHbk6HAAKAAA";

constant PROMPT_INT = 1;
constant PROMPT_STRING = 2;
constant PROMPT_DIR = 3;
constant PROMPT_FILE = 4;
constant PROMPT_ENUM = 5;

static object r;

int main() {
  if (!sizeof(SOURCE)) {
    werror("Don't call Fins.FinsPackage.main() directly - inherit it, silly!\n\n");
    return 1;
  }
  if (!r)
    r = Stdio.Readline();
  r->write("Welcome to Fins.\n");
  r->write(sprintf(
      "This program will install a Fins application called "
      "\"%s\" and optionally start it for you.\n", NAME),
      1
    );
  string appdir = prompt("First enter the directory to install the application in\n", PROMPT_DIR, getcwd());
  string fdir = Stdio.append_path(appdir, NAME);
  if (Stdio.exist(fdir)) {
    string skip = prompt("Target directory (" + fdir + ") exists, skip installation?", PROMPT_ENUM, "Y", ({ "Y", "N" }));
    if (skip == "N") {
      r->write(sprintf("Please wait, installing application in %s...\n", fdir));
      if (DEBUG)
	r->newline();
      string data = Gz.File(Stdio.FakeFile(MIME.decode_base64(SOURCE)))->read();
      int c = untar(data, appdir);
      r->write(sprintf(" done (%d files).\n", c));
    }
  }
  else {
    r->write(sprintf("Please wait, installing application in %s...\n", fdir));
    if (DEBUG)
      r->newline();
    string data = Gz.File(Stdio.FakeFile(MIME.decode_base64(SOURCE)))->read();
    int c = untar(data, appdir);
    r->write(sprintf(" done (%d files).\n", c));
  }

  string s = prompt("Would you like me to start the application using the built in standalone server?\n", PROMPT_ENUM, "Y", ({ "Y", "N" }));
  if (s == "Y") {
    // Starting standalone server.
    int port = prompt("Please enter the port you would like the Fins application to listen on for incoming browser connections.\n", PROMPT_INT, PORT);
    object server = Standalone();
    // WARNING:
    //   If your app doesn't untar to the same name as the NAME constant in your module 
    //   then you're screwed.
    return server->main(Stdio.append_path(appdir, NAME), (int)port, CONFIG);
    r->write(sprintf("Connect on port %d to this host with your web browser (probably http://localhost:%d/) to view the application.\n", port, port), 1);
  }
}

void new_source_file(string pmod_filename, string tar_filename) {
  if (!r)
    r = Stdio.Readline();
  string gzip = prompt("Is the tar file gzipped?", PROMPT_ENUM, "Y", ({ "Y", "N" }));
  string data;
  if (gzip == "Y")
    data = Stdio.read_file(tar_filename);
  else {
    object f = Stdio.FakeFile("");
    object gz = Gz.File(f, "wb");
    gz->write(Stdio.read_file(tar_filename));
    f->seek(0);
    data = f->read();
  }
  string pmod = Stdio.read_file(pmod_filename);
  string new_pmod = "";
  foreach(pmod / "\n", string line) {
    if ((sizeof(line) > 18) && (line[0..17] == "constant SOURCE = "))
      new_pmod += sprintf("constant SOURCE = %O;\n", MIME.encode_base64(data));
    else
      new_pmod += line + "\n";
  }
  Stdio.write_file(pmod_filename, new_pmod);
}

static Filesystem.System getfs(string source, string cwd) {
  // This is really nasty - we apprently need to reopen the tar file every time
  // we read from it or it randomly closes it's Fd and throws errors everywhere.
  return Filesystem.Tar(sprintf("%s.tar", NAME), 0, Stdio.FakeFile(source))->cd(cwd);
}

int untar(string source, string path, void|string cwd) {
  if (!cwd)
    cwd = "/";
  array files = getfs(source, cwd)->get_dir();
  int c;
  foreach(sort(files), string fname) {
    // Get the actual filename
    fname = ((fname / "/") - ({""}))[-1];
    object stat = getfs(source, cwd)->stat(fname);
    if (stat->isdir()) { 
      string dir = Stdio.append_path(path, fname);
      c++;
      if (DEBUG)
	write("%O [dir]\n", dir);
      mkdir(dir);
      c += untar(source, dir, Stdio.append_path(cwd, fname));
    }
    else if (stat->isreg()) {
      string file = Stdio.append_path(path, fname);
      object f;
      if (mixed err = catch{
	if (DEBUG)
	  write("%O [file %d bytes]\n", file, stat->size);
	Stdio.write_file(file, getfs(source, cwd)->open(fname, "r")->read());
      }) {
	werror("%O [error in tarfile!]\n\n", file);
	throw(err);
      } 
      c++;
    }
    else {
      werror("Unknown file type for file %O\n", fname);
      continue;
    }
  }
  return c;
}

static mixed prompt(string description, int type, void|mixed defval, void|array options) {
  if (description[-1] != '\n')
    description += "\n";
  r->write(description, 1);
  string _prompt;
  if (defval)
    _prompt = sprintf("[%%s \"%s\"]: ", (string)defval);
  else
    _prompt = "[%s]: ";
  switch(type) {
    case PROMPT_INT:
      int i = (int)r->read(sprintf(_prompt, "integer"));
      if (!i && defval)
	return defval;
      else return i;
      break;	
    case PROMPT_DIR:
      string dir = r->read(sprintf(_prompt, "directory"));
      if (Stdio.exist(dir) && Stdio.is_dir(dir))
	return dir;
      else if ((dir == "") && defval)
	return defval;
      else {
	r->write(sprintf("%s is not a valid directory.\n", dir), 1);
	return prompt(description, type, defval, options);
      }
      break;	
    case PROMPT_FILE:
      string file = r->read(sprintf(_prompt, "filename"));
      if (Stdio.exist(file) && Stdio.is_file(file))
	return file;
      else if ((file == "") && defval)
	return defval;
      else {
	r->write(sprintf("%s is not a valid file.\n", file), 1);
	return prompt(description, type, defval, options);
      }
      break;	
    case PROMPT_ENUM:
      if (arrayp(options) && sizeof(options)) {
	string choice = r->read(sprintf(_prompt, "choice(" + options * "," + ")"));
	multiset test = (multiset)options;
	if (test[choice])
	  return choice;
	else if (defval)
	  return defval;
	else {
	  r->write("Incorrect choice, please try again.\n", 1);
	  return prompt(description, type, defval, options);
	}
      }
      else
	throw(({"options must be an array of options.", backtrace()}));
      break;	
    case PROMPT_STRING:
    default:
      string s = r->read(sprintf(_prompt, "string"));
      if ((s == "") && defval)
	return defval;
      else
	return s;
  }
}

static class Standalone {
  inherit Fins.FinServe;

  int main(string appdir, int port, string config) {

    project = appdir;
    config_name = config;
    my_port = port;
    
    return do_startup();
  }
  
}
