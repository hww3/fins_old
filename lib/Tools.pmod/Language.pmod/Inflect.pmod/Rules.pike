array rules = ({});

void add_rule(object r)
{
  rules += ({r});
}


class Rule
{
  int match(string word, int(0..1)|void is_proper_noun)
  {
    return 0;
  }

  string apply(string word)
  {
    return word;
  }
}

class InvariantRule(multiset words)
{
  inherit Rule;

  int match(string word, int(0..1)|void is_proper_noun)
  {
    return words[word];
  }

  string apply(string word)
  {
    return word;
  }
}

class CategoryRule(multiset words, string suffix, string to)
{
  inherit Rule;
  
  int match(string word, int(0..1)|void is_proper_noun)
  {
    return words[word];
  }
  
  string apply(string word)
  {
    return word[..sizeof(word)-(sizeof(suffix)+1)] + to;
  }
}

class MappingRule(mapping words)
{
  inherit Rule;

  int match(string word, int(0..1)|void is_proper_noun)
  {
    return (words[word])?1:0;
  }

  string apply(string word)
  {
    return words[word];
  }
}

class RegexRule(string regex, string suffix, string to, int(0..1)|void proper_nouns_only)
{
  inherit Rule;

  int match(string word, int(0..1)|void is_proper_noun)
  {
    if(proper_nouns_only && is_proper_noun)
      return Regexp(regex)->match(word);
    else return 0;
  }

  string apply(string word)
  {
    return word[..sizeof(word)-(sizeof(suffix)+1)] + to;
  }
}


class SuffixAddRule(string suffix, string add)
{
  inherit Rule;

  int match(string word, int(0..1)|void is_proper_noun)
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

  int match(string word, int(0..1)|void is_proper_noun)
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

  int match(string word, int(0..1)|void is_proper_noun)
  {
    return (word == from);
  }

  string apply(string word)
  {
    return to;
  }
}

class DefaultRule()
{
  inherit Rule;

  int match(string word, int(0..1)|void is_proper_noun)
  {
    return 1;
  }

  string apply(string word)
  {
    return word + "s";
  }
}


class ReverseDefaultRule()
{
  inherit Rule;

  int match(string word, int(0..1)|void is_proper_noun)
  {
    return has_suffix(word, "s");
  }

  string apply(string word)
  {
    return word[0..sizeof(word)-2];
  }
}


