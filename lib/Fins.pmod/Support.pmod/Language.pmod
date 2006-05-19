//! turn a lower case and underscored word into something a little
//! prettier and easier to understand.
string humanize(string word)
{
  word = Regexp.SimpleRegexp("_id$")->replace(word, "");
  word = String.capitalize(replace(word, "_", " "));

  return word;
}

