inherit .Criteria;


//!
string get(string|void name, object datao)
{
   return sprintf("%s LIKE '%s'", name, criteria);
}
