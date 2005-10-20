import Fins.Model;

int main()
{
   object s = Sql.Sql("mysql://hww3:pastram.@localhost/hww3");
   object d = Fins.Model.DataModelContext(); 
   d->sql = s;
   add_object_type(addressbook_object(d));

     
   object a = addressbook();
   a->set("First_Name", "Bill");
   a->set("Last_Name", "Welliver");
   a->save();

   write("!Last Name: " + a->get("Last_Name") + "\n");
   a["Last_Name"] = "Lupart";

   write("Last Name: " + a["Last_Name"] + "\n");

   object b = addressbook(18);

   write("from b: " + b["First_Name"]);

}

class addressbook
{
   inherit DataObjectInstance;
   
   string object_type = "addressbook";  
}

class addressbook_object
{
   inherit DataObject;

   static void create(DataModelContext c)
   {  
      ::create(c);
      set_name("addressbook");
      add_field(PrimaryKeyField("id"));
      add_field(StringField("First_Name", 32, 0, "Bubba"));
      add_field(StringField("Last_Name", 32, 0));
      set_primary_key("id");
   }
   
}
