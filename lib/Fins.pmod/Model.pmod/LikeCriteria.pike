inherit .Criteria;



string get(string|void name)
{
   return sprintf("%s LIKE '%s'", name, criteria);
}
