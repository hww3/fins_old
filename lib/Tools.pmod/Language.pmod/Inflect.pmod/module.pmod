string pluralize(string word)
{
  foreach(.Rules.rules;; object r)
  {
    if(r->match(word))
      return r->apply(word);
  }
}
