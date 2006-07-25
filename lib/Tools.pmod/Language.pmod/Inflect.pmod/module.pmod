//! turn a lower case and underscored word into something a little
//! prettier and easier to understand.
string humanize(string word)
{
  word = Regexp.SimpleRegexp("_id$")->replace(word, "");
  word = String.capitalize(replace(word, "_", " "));

  return word;
}

//!
string pluralize(string word)
{
  foreach(.PluralizeRules.rules;; object r)
  {
    if(r->match(word))
    {
#if INFLECTION_DEBUG
      werror("INFLECTION: %s matched rule %O.\n", word, r);
#endif /* INFLECTION_DEBUG */
      return r->apply(word);
    }
  }
}

//!
string singularize(string word)
{
  foreach(.SingularizeRules.rules;; object r)
  {
    if(r->match(word))
    {
#if INFLECTION_DEBUG
      werror("INFLECTION: %s matched rule %O.\n", word, r);
#endif /* INFLECTION_DEBUG */
      return r->apply(word);
    }
  }
}

