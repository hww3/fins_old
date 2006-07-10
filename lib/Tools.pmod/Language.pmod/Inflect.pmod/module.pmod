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

