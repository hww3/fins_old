array rules = ({});

void create()
{
  add_rule(MatchRule("person", "people"));
  add_rule(MatchRule("person", "people"));
  add_rule(SuffixReplaceRule("ss", "sses"));
  add_rule(SuffixReplaceRule("y", "ies"));
}

void add_rule(object r)
{
  rules += ({r});
}


class Rule
{
  int match(string word)
  {
    return 0;
  }

  string apply(string word)
  {
    return word;
  }
}

class SuffixAddRule(string suffix, string add)
{
  inherit Rule;

  int match(string word)
  {
    return has_suffix(word, suffix);
  }

  string apply(string word)
  {
    return word + suffix;
  }
}


class SuffixReplaceRule(string suffix, string to)
{
  inherit Rule;

  int match(string word)
  {
    return has_suffix(word, suffix);
  }

  string apply(string word)
  {
    return word[..sizeof(word)-(sizeof(suffix)+1)] + to;
  }
}

class MatchRule(string from, string to)
{
  inherit Rule;

  int match(string word)
  {
    return (word == from);
  }

  string apply(string word)
  {
    return to;
  }
}

