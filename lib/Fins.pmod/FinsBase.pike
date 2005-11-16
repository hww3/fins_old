//! this is a base class for all fins objects.

private object __this_app;

object cache()
{
  if(__this_app)
  {
    return __this_app->cache;
  }

  else return 0;
}

object model()
{
  if(__this_app)
  {
    return __this_app->model;
  }

  else return 0;
}

object view()
{
  if(__this_app)
  {
    return __this_app->view;
  }

  else return 0;
}

object app()
{
  if(__this_app)
    return __this_app;
  else return 0;
}

static void create(object a)
{
  __this_app = a;
}
