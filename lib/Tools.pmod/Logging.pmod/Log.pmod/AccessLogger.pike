inherit .Logger;

constant months = ({
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul", 
  "Aug",
  "Sep",
  "Oct",
  "Nov", 
  "Dec"
});

void log(object r)
{
  do_msg(r);
}


// TODO: should be optimized.
static void do_msg(object r /*response*/)
{
  mapping lt = localtime(time());
  lt->year += 1900;
  lt->month = months[lt->mon];
  lt->mon += 1;
  lt->timezone = (int)((lt->timezone / 3600.0)* 100);

  lt["remote_host"] = r->request?r->request->get_client_addr():"-";
  lt["protocol"] = r->request->protocol;
  lt["method"] = r->request->request_type;
  lt["request"] = r->request->not_query + (sizeof(r->request->query)?("?" + r->request->query):"");
  lt["user"] = "-";
  lt["code"] = r->error;
  object st;
  if(r->file && (st = r->file->stat()))
  {
    lt["size"] = st->size;
  }
  else if(r->data)
    lt["size"] = sizeof(r->data);

  appenders->write(local_vars + lt);
}

string _sprintf(mixed ... args)
{
  return "logger()";//, appenders);
}
