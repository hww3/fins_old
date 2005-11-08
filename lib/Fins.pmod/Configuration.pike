
mapping values;

static void create(string config_file)
{
	string fc = Stdio.read_file(config_file);
	
	// the "spec" says that the file is utf-8 encoded.
	fc=utf8_to_string(fc);
	
	values = Public.Tools.ConfigFiles.Config.read(fc);
}
