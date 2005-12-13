import Fins.Model;

object repo;

int main()
{
   object s = Sql.Sql("mysql://hww3:f00bar@localhost/hww3");
   object d = Fins.Model.DataModelContext(); 

   d->sql = s;

   // we can use Fins.Model as the repository if we're willing to have a shared model
   // definition repository. otherwise, we should create our own instance of 
   // Fins.Model.Repository; most likely as a module.
   d->repository = Fins.Model;
   d->debug = 1;
   Fins.Model.add_object_type(Name_object(d), Name);   
   Fins.Model.add_object_type(Author_object(d), Author);
   Fins.Model.add_object_type(Comment_object(d), Comment);   



   object author;
   if(catch(author = Author(1)))
   {
     author = Author(UNDEFINED);
     author["Name"] = "Bubba";
     author["UserName"] = "bub";
     author->save();
   }     


   object a = Name(UNDEFINED);
   a->set("First_Name", "Bill");
   a->set("Last_Name", "Welliver");
   a["Cards_Received"] = 24;
   a["updated"] = Calendar.Day()-10;
   a["author"] = author;
   a->save();

   object c = Comment(UNDEFINED);

   c["Description"] = "now is the time for all good men to come to the aid of their country.\n";
   c["name"] = a;
   c->save();

   object z = a["comments"][0];

   werror("COMMENTS: %d, %O\n", sizeof(a["comments"]),z);

   werror("A: %O\n", mkmapping(indices(a), values(a)));

   write("!Last Name: " + a->get("Last_Name") + "\n");
   a["Last_Name"] = "Lupart";

   write("Last Name: " + a["Last_Name"] + "\n");
   werror("Cards Received: %O\n", a["Cards_Received"]);
   object b = Name(a->get_id());
   b->set_atomic((["Last_Name":"Welliver", "First_Name": "Jennifer", "Cards_Received": 42]));
   write("from b: " + b["id"] +"\n");
   write("from b: " + b["First_Name"] +"\n");
   write("from b: " + b["Last_Name"] + "\n");
   write("from b: " + b["Cards_Received"] + "\n");
   write("from b: " +sprintf("%O", b["updated3"]) + "\n");
   write("from b: " + sprintf("%O" , b["author"]["Name"]) + "\n");   
}

class Name_object
{
   inherit DataObject;

   static void create(DataModelContext c)
   {  
      ::create(c);
      set_table_name("names");
      set_instance_name("name");
      add_field(PrimaryKeyField("id"));
      add_field(StringField("First_Name", 32, 0));
      add_field(StringField("Last_Name", 32, 0));
      add_field(IntField("Cards_Received", 0, 1));
      add_field(DateField("updated", 0, foo));
      add_field(TimeField("updated2", 0, foo2));
      add_field(DateTimeField("updated3", 0, foo2));
      add_field(KeyReference("author", "author_id", "author"));
      add_field(InverseForeignKeyReference("comments", "comment", "name"));
      set_primary_key("id");
   }

   static object foo()
   {
     return Calendar.Day();
   }

   static object foo2()
   {
     return Calendar.Second();
   }
   
}

class Name
{
  inherit DirectAccessInstance;

  string type_name = "name";

  // note that if you want a shared model repository, you don't have to overwrite anything,
  // otherwise, you need to set the value of "repository" to a class that impliments
  // Fins.Model.Repository.
}

class Author
{
  inherit DirectAccessInstance;

  string type_name = "author";

  // note that if you want a shared model repository, you don't have to overwrite anything,
  // otherwise, you need to set the value of "repository" to a class that impliments
  // Fins.Model.Repository.
}

class Comment
{
  inherit DirectAccessInstance;

  string type_name = "comment";

  // note that if you want a shared model repository, you don't have to overwrite anything,
  // otherwise, you need to set the value of "repository" to a class that impliments
  // Fins.Model.Repository.
}

class Author_object
{
   inherit DataObject;

   static void create(DataModelContext c)
   {  
      ::create(c);
      set_table_name("authors");
      set_instance_name("author");
      add_field(PrimaryKeyField("id"));
      add_field(StringField("Name", 24, 0));
      add_field(StringField("UserName", 16, 0));
      set_primary_key("id");
   }

}


class Comment_object
{
   inherit DataObject;

   static void create(DataModelContext c)
   {  
      ::create(c);
      set_table_name("my_comments");
      set_instance_name("comment");
      add_field(PrimaryKeyField("id"));
      add_field(KeyReference("name", "name_id", "name"));
      add_field(StringField("Description", 1024, 0));
      set_primary_key("id");
   }

}
