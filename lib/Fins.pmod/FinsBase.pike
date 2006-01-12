 //! this is a base class for all fins objects.

object cache;
object model;
object view;
object app;
object config;

static void create(object a)
{
  app = a;
  model = a->model;
  view = a->view;
  cache = a->cache;
  config = a->config;
}
