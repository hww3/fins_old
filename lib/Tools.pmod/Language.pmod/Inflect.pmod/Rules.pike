array rules = ({});

mapping irregular_nouns_local = ([
  "quiz": "quizzes",
  "move": "moves",
  "sex": "sexes",
  "person": "people",
  "bus": "busses"  
]);

mapping irregular_nouns_table_a1 = ([
  "beef": "beefs",
  "brother": "brothers",
  "child" : "children",
  "cow": "cows",
  "ephemeris": "ephemerides",
  "genie": "genies",
  "money": "moneys",
  "mongoose": "mongooses",
  "mythos": "mythoi",
  "octupus": "octopuses",
  "ox": "oxen",
  "soliloquy": "soliloquies",
  "trilby": "trilbys"
]);

multiset invariant_nouns_table_a2 = (<
"equipment", "information", "rice",
"bison", "flounder", "pliers",
"bream", "gallows", "proceedings",
"breeches", "graffiti", "rabies",
"britches", "headquarters", "salmon",
"carp", "herpes", "scissors",
"chassis", "high-jinks", "sea-bass",
"clippers", "homework", "series",
"cod", "innings", "shears",
"contretemps", "jackanapes", "species",
"corps", "mackerel", "swine",
"debris", "measles", "trout",
"diabetes", "mews", "tuna",
"djinn", "mumps", "whiting",
"eland", "news", "wildebeest",
"elk", "pincers" >);

multiset invariant_nouns_table_a3 = (<
"acropolis", "chaos", "lens",
"aegis", "cosmos", "mantis",
"alias", "dais", "marquis",
"asbestos", "digitalis", "metropolis",
"atlas", "epidermis", "pathos",
"bathos", "ethos", "pelvis",
"bias", "gas", "polis",
"caddis", "glottis", "rhinoceros",
"cannabis", "glottis", "sassafras",
"canvas", "ibis", "trellis"
>);

multiset classical_nouns_table_a10 = (<
  "alumna",
  "alga",
  "vertebra"
>);

multiset classical_nouns_table_a14 = (<
  "codex",
  "murex",
  "silex"
>);

multiset classical_nouns_table_a19 = (<
  "aphelion"
  "hyperbaton",
  "perihelion",
  "asyndeton",
  "noumenon",
  "phenomenon",
  "criterion",
  "organon",
  "prolegomenon"
>);

multiset classical_nouns_table_a20 = (<
  "agendum",
  "datum",
  "extremum",
  "bacterium",
  "desideratum",
  "stratum",
  "candelabrum",
  "erratum",
  "ovum"
>);

multiset classical_nouns_table_a11 = (<
  "abscissa",
  "formula",
  "medusa",
  "amoeba",
  "hydra",
  "nebula",
  "antenna",
  "hyperbola",
  "nova",
  "aurora",
  "lacuna",
  "parabola"
>);

multiset classical_nouns_table_a12 = (<
  "anathema",
  "enema",
  "oedema",
  "bema",
  "enigma",
  "sarcoma",
  "carcinoma",
  "gumma",
  "schema",
  "charisma",
  "lemma",
  "soma",
  "diploma",
  "lymphoma",
  "stigma",
  "dogma",
  "magma",
  "stoma",
  "drama",
  "melisma",
  "trauma",
  "edema",
  "miasma"
>);

multiset classical_nouns_table_a13 = (<
  "stamen", "foramen", "lumen"
>);

multiset classical_nouns_table_a15 = (<
  "apex", "latex", "vertex", "cortex",
  "pontifex", "vortex", "index", "simplex"
>);

multiset classical_nouns_table_a16 = (<
  "iris", "clitoris"
>);

multiset classical_nouns_table_a17 = (<
  "albino", "generalissimo", "manifesto",
  "archipelago", "ghetto", "medico",
  "armadillo", "guano", "octavo",
  "commando", "inferno", "photo",
  "ditto", "jumbo", "pro",
  "dynamo", "lingo", "quarto",
  "embryo", "lumbago", "rhino",
  "fiasco", "magneto", "stylo"
>);

multiset classical_nouns_table_a18 = (<
  "alto", "contralto", "soprano", "basso",
  "crescendo", "tempo", "canto", "solo"
>);

multiset classical_nouns_table_a21 = (<
  "aquarium", "interregnum", "quantum",
  "compendium", "lustrum", "rostrum",
  "consortium", "maximum", "spectrum",
  "cranium", "medium", "speculum",
  "curriculum", "memorandum", "stadium",
  "dictum", "millenium", "trapezium", 
  "emporium", "minimum", "ultimatum", 
  "enconium", "momentum", "vacuum",
  "gymnasium", "optimum", "velum",
  "honorarium", "phylum"
>);

multiset classical_nouns_table_a22 = (<
  "focus", "nimbus", "succubus",
  "fungus", "nucleolus", "torus",
  "genius", "radius", "umbilicus",
  "incubus", "stylus", "uterus"
>);

multiset classical_nouns_table_a23 = (<
  "apparatus", "impetus", "prospectus",
  "cantus", "nexus", "sinus",
  "coitus", "plexus", "status", "hiatus"
>);

multiset classical_nouns_table_a24 = (<
 "afreet", "aftrit", "efreet"
>);

multiset classical_nouns_table_a25 = (<
  "cherub", "goy", "seraph"
>);

//
// these rules relect the "Algorithmic Approach to English Pluralization"
// as presented in the following paper:
//
// http://www.csse.monash.edu.au/~damian/papers/HTML/Plurals.html
//

void create()
{
  // rules for which there is a defined one to one mapping
  add_rule(MappingRule(irregular_nouns_local));

  // rules for which the pluralized form is invariant
  add_rule(SuffixReplaceRule("fish", "fish"));
  add_rule(SuffixReplaceRule("ois", "ois"));
  add_rule(SuffixReplaceRule("fish", "sheep"));
  add_rule(SuffixReplaceRule("deer", "deer"));
  add_rule(SuffixReplaceRule("pox", "pox"));
  add_rule(SuffixReplaceRule("itis", "itis"));
  add_rule(RegexRule("[a-z]ese$", "ese", "ese"));
  add_rule(InvariantRule(invariant_nouns_table_a3 + invariant_nouns_table_a2));
  
  // pronouns

  // standard irregular plurals
  add_rule(MappingRule(irregular_nouns_table_a1));

  // irregular inflections for common suffixes
  add_rule(SuffixReplaceRule("man", "men"));
  add_rule(SuffixReplaceRule("ouse", "ice"));
  add_rule(SuffixReplaceRule("tooth", "teeth"));
  add_rule(SuffixReplaceRule("goose", "geese"));
  add_rule(SuffixReplaceRule("foot", "feet"));
  add_rule(SuffixReplaceRule("zoon", "zoa"));
  add_rule(RegexRule("[csx]is$", "is", "es"));

  // fully assimilated classical inflections
  add_rule(CategoryRule(classical_nouns_table_a10, "a", "ae"));
  add_rule(CategoryRule(classical_nouns_table_a14, "ex", "ices"));
  add_rule(CategoryRule(classical_nouns_table_a19, "on", "a"));
  add_rule(CategoryRule(classical_nouns_table_a20, "um", "a"));

  // classical variants of modern inflections
  add_rule(SuffixReplaceRule("trix", "trices"));
  add_rule(SuffixReplaceRule("eau", "eaux"));
  add_rule(SuffixReplaceRule("ieu", "ieux"));
  add_rule(RegexRule("[iay]nx$", "nx", "nges"));
  add_rule(CategoryRule(classical_nouns_table_a11, "a", "as"));
  add_rule(CategoryRule(classical_nouns_table_a12, "a", "as"));
  add_rule(CategoryRule(classical_nouns_table_a13, "en", "ens"));
  add_rule(CategoryRule(classical_nouns_table_a15, "ex", "exes"));
  add_rule(CategoryRule(classical_nouns_table_a16, "is", "ises"));
  add_rule(CategoryRule(classical_nouns_table_a18, "o", "os"));
  add_rule(CategoryRule(classical_nouns_table_a21, "um", "ums"));
  add_rule(CategoryRule(classical_nouns_table_a22, "us", "uses"));
  add_rule(CategoryRule(classical_nouns_table_a23, "us", "uses"));
  add_rule(CategoryRule(classical_nouns_table_a24, "", "i"));
  add_rule(CategoryRule(classical_nouns_table_a25, "", "im"));
  
  // suffixes ch, sh and ss
  add_rule(RegexRule("[cs]h$", "h", "hes"));
  add_rule(SuffixReplaceRule("ss", "sses"));

  // certain words ending in f or fe
  add_rule(RegexRule("[aeo]lf$", "f", "ves"));
  add_rule(RegexRule("[^d]eaf$", "f", "ves"));
  add_rule(RegexRule("arf$", "f", "ves"));
  add_rule(RegexRule("[nlw]ife$", "fe", "ves"));

  add_rule(RegexRule("[aeiou]y$", "y", "ys"));
  add_rule(RegexRule("[A-Z].*y$", "y", "ys"));
//  add_rule(RegexRule("[A-Z].*es$", "es", "es"));
  add_rule(SuffixReplaceRule("y", "ies"));

  add_rule(CategoryRule(classical_nouns_table_a17 + classical_nouns_table_a18, "o", "os"));
  add_rule(RegexRule("[aeiou]o$", "o", "os"));
  add_rule(SuffixReplaceRule("o", "oes"));
  
  add_rule(DefaultRule());
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

class InvariantRule(multiset words)
{
  inherit Rule;

  int match(string word)
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
  
  int match(string word)
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

  int match(string word)
  {
    return (words[word])?1:0;
  }

  string apply(string word)
  {
    return words[word];
  }
}

class RegexRule(string regex, string suffix, string to)
{
  inherit Rule;

  int match(string word)
  {
    return Regexp(regex)->match(word);
  }

  string apply(string word)
  {
    return word[..sizeof(word)-(sizeof(suffix)+1)] + to;
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

class DefaultRule()
{
  inherit Rule;

  int match(string word)
  {
    return 1;
  }

  string apply(string word)
  {
    return word + "s";
  }
}

