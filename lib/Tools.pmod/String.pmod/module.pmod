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

inherit .NamedSprintf;
