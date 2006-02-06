inherit .Personality;


string quote_binary(string s)
{
  return sql->quote(s);
}

string unquote_binary(string s)
{
  return s;
}

