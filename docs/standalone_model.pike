/*
  Using Fins.Model in a standalone application

  in this example, we demonstrate the use of the Fins Model framework outside of a Fins Web
  application. you don't ever need to create a full Fins app to use this technique, but 
  it makes it easier to do a "quick start" by creating the model stub classes:

  run pike -Mlib -x fins create MTA (for "my test application")
  edit mta/config/dev.cfg, to define the sql url
  create tables in database
  run pike -Mlib -x fins model MTA scan, which will create stub classes in mta/modules/mta.pmod
  copy MTA/modules/MTA.pmod someplace more convenient for your app, preferably in your module path
  modify this file as needed, then run and enjoy!.
*/

class mymodel
{
  inherit Fins.FinsModel : fm;

  static void create(string sqlurl, int debug, object model_stub_module)
  {
    object o;

    this->config = Fins.Configuration(0, (["model": (["datasource": sqlurl, "debug": debug]) ]));

    Fins.Model.set_model_module(model_stub_module.Model);
    Fins.Model.set_object_module(model_stub_module.Objects);

    fm::load_model();
  }
}


int main(int argc, array argv)
{
  object model = mymodel("mysql://blog:pass@localhost/blog", 1, MTA);

  werror("%O\n", values(MTA.Objects.User(1)));

  return 0;
}
