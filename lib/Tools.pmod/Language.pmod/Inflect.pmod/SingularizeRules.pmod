inherit .Rules;

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
  "alumnae",
  "algae",
  "vertebrae"
>);

multiset classical_nouns_table_a14 = (<
  "codices",
  "murices",
  "silices"
>);

multiset classical_nouns_table_a19 = (<
  "aphelia"
  "hyperbata",
  "perihelia",
  "asyndeta",
  "noumena",
  "phenomena",
  "criteria",
  "organa",
  "prolegomena"
>);

multiset classical_nouns_table_a20 = (<
  "agenda",
  "data",
  "extrema",
  "bacteria",
  "desiderata",
  "strata",
  "candelabra",
  "errata",
  "ova"
>);

multiset classical_nouns_table_a11 = (<
  "abscissas",
  "formulas",
  "medusas",
  "amoebas",
  "hydras",
  "nebulas",
  "antennas",
  "hyperbolas",
  "novas",
  "auroras",
  "lacunas",
  "parabolas"
>);

multiset classical_nouns_table_a12 = (<
  "anathemas",
  "enemas",
  "oedemas",
  "bemas",
  "enigmas",
  "sarcomas",
  "carcinomas",
  "gummas",
  "schemas",
  "charismas",
  "lemmas",
  "somas",
  "diplomas",
  "lymphomas",
  "stigmas",
  "dogmas",
  "magmas",
  "stomas",
  "dramas",
  "melismas",
  "traumas",
  "edemas",
  "miasmas"
>);

multiset classical_nouns_table_a13 = (<
  "stamens", "foramens", "lumens"
>);

multiset classical_nouns_table_a15 = (<
  "apexes", "latexes", "vertexes", "cortexes",
  "pontifexes", "vortexes", "indexes", "simplexes"
>);

multiset classical_nouns_table_a16 = (<
  "irises", "clitorises"
>);

multiset classical_nouns_table_a17 = (<
  "albinos", "generalissimos", "manifestos",
  "archipelagos", "ghettos", "medicos",
  "armadillos", "guanos", "octavos",
  "commandos", "infernos", "photos",
  "dittos", "jumbos", "pros",
  "dynamos", "lingos", "quartos",
  "embryos", "lumbagos", "rhinos",
  "fiascos", "magnetos", "stylos"
>);

multiset classical_nouns_table_a18 = (<
  "altos", "contraltos", "sopranos", "bassos",
  "crescendos", "tempos", "cantos", "solos"
>);

multiset classical_nouns_table_a21 = (<
  "aquariums", "interregnums", "quantums",
  "compendiums", "lustrums", "rostrums",
  "consortiums", "maximums", "spectrums",
  "craniums", "mediums", "speculums",
  "curriculums", "memorandums", "stadiums",
  "dictums", "milleniums", "trapeziums", 
  "emporiums", "minimums", "ultimatums", 
  "enconiums", "momentums", "vacuums",
  "gymnasiums", "optimums", "velums",
  "honorariums", "phylums"
>);

multiset classical_nouns_table_a22 = (<
  "focuses", "nimbuses", "succubuses",
  "funguses", "nucleoluses", "toruses",
  "geniuses", "radiuses", "umbilicuses",
  "incubuses", "styluses", "uteruses"
>);

multiset classical_nouns_table_a23 = (<
  "apparatuses", "impetuses", "prospectuses",
  "cantuses", "nexuses", "sinuses",
  "coituses", "plexuses", "statuses", "hiatuses"
>);

multiset classical_nouns_table_a24 = (<
 "afreeti", "aftriti", "efreeti"
>);

multiset classical_nouns_table_a25 = (<
  "cherubim", "goyim", "seraphim"
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
  add_rule(MappingRule(mkmapping(values(irregular_nouns_local), indices(irregular_nouns_local))));

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
  add_rule(MappingRule(mkmapping(values(irregular_nouns_table_a1), indices(irregular_nouns_table_a1))));

  // irregular inflections for common suffixes
  add_rule(SuffixReplaceRule("men", "man"));
  add_rule(SuffixReplaceRule("ice", "ouse"));
  add_rule(SuffixReplaceRule("teeth", "tooth"));
  add_rule(SuffixReplaceRule("geese", "goose"));
  add_rule(SuffixReplaceRule("feet", "foot"));
  add_rule(SuffixReplaceRule("zoa", "zoon"));
  add_rule(RegexRule("[csx]es$", "es", "is"));

  // fully assimilated classical inflections
  add_rule(CategoryRule(classical_nouns_table_a10, "ae", "a"));
  add_rule(CategoryRule(classical_nouns_table_a14, "ices", "ex"));
  add_rule(CategoryRule(classical_nouns_table_a19, "a", "on"));
  add_rule(CategoryRule(classical_nouns_table_a20, "a", "um"));

  // classical variants of modern inflections
  add_rule(SuffixReplaceRule("trices", "trix"));
  add_rule(SuffixReplaceRule("eaux", "eau"));
  add_rule(SuffixReplaceRule("ieux", "ieu"));
  add_rule(RegexRule("[iay]nges$", "nges", "nx"));
  add_rule(CategoryRule(classical_nouns_table_a11, "as", "a"));
  add_rule(CategoryRule(classical_nouns_table_a12, "as", "a"));
  add_rule(CategoryRule(classical_nouns_table_a13, "ens", "en"));
  add_rule(CategoryRule(classical_nouns_table_a15, "exes", "ex"));
  add_rule(CategoryRule(classical_nouns_table_a16, "ises", "is"));
  add_rule(CategoryRule(classical_nouns_table_a18, "os", "o"));
  add_rule(CategoryRule(classical_nouns_table_a21, "ums", "um"));
  add_rule(CategoryRule(classical_nouns_table_a22, "uses", "us"));
  add_rule(CategoryRule(classical_nouns_table_a23, "uses", "us"));
  add_rule(CategoryRule(classical_nouns_table_a24, "i", ""));
  add_rule(CategoryRule(classical_nouns_table_a25, "im", ""));
  
  // suffixes ch, sh and ss
  add_rule(RegexRule("[cs]hes$", "hes", "h"));
  add_rule(SuffixReplaceRule("sses", "ss"));

  // certain words ending in f or fe
  add_rule(RegexRule("[aeo]ves$", "ves", "f"));
  add_rule(RegexRule("[^d]eaves$", "ves", "f"));
  add_rule(RegexRule("arves$", "ves", "f"));
  add_rule(RegexRule("[nlw]ives$", "ves", "fe"));

  add_rule(RegexRule("[aeiou]ys$", "ys", "y"));
  add_rule(RegexRule("[A-Z].*ys$", "ys", "y"));
//  add_rule(RegexRule("[A-Z].*es$", "es", "es"));
  add_rule(SuffixReplaceRule("ies", "y"));

  add_rule(CategoryRule(classical_nouns_table_a17 + classical_nouns_table_a18, "os", "o"));
  add_rule(RegexRule("[aeiou]os$", "os", "o"));
  add_rule(SuffixReplaceRule("oes", "o"));
  
  add_rule(ReverseDefaultRule());
}

