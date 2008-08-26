//! return a friendly string description of a @[Calendar] object.
//!
public string friendly_date(object c)
{
   string howlongago;
   int future;

   if (c < Calendar.now()) {
     c = c->distance(Calendar.now());
   }
   else {
     c = Calendar.now()->distance(c);
     future++;
   }

   if(c->number_of_minutes() < 3)
   {
      howlongago = "Just a moment ago";
   }
   else if(c->number_of_minutes() < 60)
   {
      howlongago = c->number_of_minutes() + " minutes ago";
   }
   else if(c->number_of_hours() < 24)
   {
      howlongago = c->number_of_hours() + " hours ago";
   }
   else
   {
      howlongago = c->number_of_days() + " days ago";
   }

   if (future)
     return replace(howlongago, "ago", "in the future");
   else
     return howlongago;
}

string textify(string html)
{
  object p = Parser.HTML();
  p->_set_tag_callback(lambda(object parser, mixed val){return " ";});

  return p->finish(html)->read();
}

string make_excerpt(string c)
{
        if(sizeof(c)<500)
          return c;
   int loc = search(c, " ", 499);

        // we don't have a space?
   if(loc == -1)
        {
                c = c[0..499] + "...";
        }
        else
        {
                c = c[..loc] + "...";
        }

        return c;
}



inherit .NamedSprintf;
