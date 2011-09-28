import Tools.Logging;
import Fins;

//! a Controller filter suitable for use with Fins.FinsController.after_filter()
//! that processes a file as though it were a SimpleTemplate.
//!
//! @example
//! // we're in our FinsController
//! static void start() {
//!   after_filter(Fins.Helpers.Filters.TemplateParser());
//! }

//!
int filter(object request, object response, mixed ... args)
{ 

  if(!response->get_header("Content-Encoding")) // don't encode on already encoded
  {
      string nd = response->get_data();
      object f = response->get_file();
      if (!nd && f) {
	object stat = f->stat();
	f->seek(0);
	nd = f->read(stat->size);
	f->seek(0);
      }
      object x = request->fins_app->view->get_string_view(nd);
      x->data->set_request(request);
      response->set_data(x->render());
  }

  return 1;
}
