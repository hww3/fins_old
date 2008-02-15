constant low_protocol = "NONE";
object fins_app;

string not_args;
string controller_path;
string controller_name;
string event_name;
object controller;
mixed event;

function get_session_by_id = _get_session_by_id;

static mixed cast(string typen)
{
  if(typen == "mapping")
  {
    return mkmapping(indices(this), values(this));
  }
}

//!
static mapping _get_session_by_id(string SessionID)
{
  return ([]);
}

multiset (string) pragma    = (< >);

//!
string get_compress_encoding()
{

  if(this->misc->session_variables && this->misc->session_variables->__encode)
    return this->misc->session_variables->__encode;

  array available = ({"deflate", "gzip"});

  // we need to figure out the encoding supported.
  //  else
  {
    string encode = 0;
    string eh;
    array ae = ({});
    array aq = ({});

    if(this->request_headers["accept-encoding"])
      eh = this->request_headers["accept-encoding"];

    if(!eh || !sizeof(eh)) return 0;

    foreach(eh/",";;string encode)
    {
      array e = encode/";";
      float q = 1.0;
      encode = String.trim_all_whites(e[0]);
      if(sizeof(e)>1)
      {
        e[1] = String.trim_all_whites(e[1]);
        if(has_prefix(e[1], "q="))
          q = (float)e[1][2..];
        else q = 1.0;
      }
      ae += ({encode});
      aq += ({q});
    }
    sort(aq, ae);
    ae = reverse(ae);
     // we prefer gzip.
     if(search(ae, "gzip") != -1)
       encode = "gzip";
     else
      foreach(ae;;string desired)
        if(search(available, desired) != -1)
        {
          encode = desired;
          break;
        }
#ifdef DEBUG
    werror("SELECTED ENCODING: %O\n", encode);
#endif
    if (this->misc->session_variables)
      this->misc->session_variables->__encode = encode;
    return encode;
  }

}

//! allows you to override the detected language.
void set_lang(string lang) {
  if (sizeof(lang) == 2) {
    if (iso639_2[lang])
      this->misc->session_variables->__lang == lang;
  }
  else if (sizeof(lang) == 3) {
    mapping backwards = mkmapping(values(iso639_2), indices(iso639_2));
    if (backwards[lang])
      this->misc->session_variables->__lang == backwards[lang];
  }
}

//! returns a 3 letter iso 639 language code based on accept-language headers
//!
//! @note
//! this value is cached for the life of the session
string get_lang()
{
  if(this->misc->session_variables->__lang)
    return this->misc->session_variables->__lang;

  // we need to figure out the language.
  //  else
  {
    string lang = "eng";
    string lh;
    array al = ({});
    array aq = ({});

    if(this->request_headers["accept-language"])
      lh = this->request_headers["accept-language"];

    foreach(lh/",";;string lang)
    {
      array l = lang/";";
      float q = 1.0;
      lang = String.trim_all_whites(l[0]);
      if(sizeof(l)>1)
      {
	l[1] = String.trim_all_whites(l[1]);
	if(has_prefix(l[1], "q="))
	  q = (float)l[1][2..];
	else q = 1.0;
      }
      al += ({lang});
      aq += ({q});
    }

    sort(aq, al);
    al = reverse(al);

    al = map_languages(al);
    array available = Locale.list_languages(fins_app->config->app_name);

#ifdef DEBUG
    werror("REQUESTED LANGUAGES: %O\n", al);
    werror("AVAILABLE LANGUAGES: %O\n", Locale.list_languages(fins_app->config->app_name));
#endif
    foreach(al;;string desired)
      if(search(available, desired) != -1)
      {
	lang = desired;
	break;
      }
#ifdef DEBUG
    werror("SELECTED LANGUAGE: %O\n", lang);
#endif
    this->misc->session_variables->__lang = lang;
    return lang;
  }
}

//! the purpose of this method is to convert an iso language code
//! to one familiar with the pike locale system.
array map_languages(array languages)
{
  array out = ({}); 

  foreach(languages;;string l)
    if(iso639_2[l])
      out += ({iso639_2[l]});
    else if(sizeof(l)>2 && iso639_2[l[0..1]])
      out += ({iso639_2[l[0..1]]});

  return out;
}

mapping iso639_2 =   
([
 "ab": "abk",
 "aa": "aar",
 "af": "afr",
 "sq": "alb",
 "am": "amh",
 "ar": "ara",
 "hy": "arm",   
 "as": "asm",
 "ay": "aym",
 "az": "aze",  
 "ba": "bak",
 "eu": "baq",
 "bn": "ben",
 "bh": "bih",
 "bi": "bis",
 "be": "bre",
 "bg": "bul",
 "my": "bur",
 "be": "bel",
 "ca": "cat",
 "zh": "chi",
 "co": "cos",
 "hr": "cro", // we made this one up :)
 "cs": "ces",
 "da": "dan",
 "nl": "dut",
 "dz": "dzo",
 "en": "eng",
 "eo": "epo",
 "et": "est", 
 "fo": "fao",
 "fj": "fij",
 "fi": "fin",
 "fr": "fra",
 "fy": "fry",
 "gl": "glg",
 "ka": "geo",
 "de": "deu",
 "el": "ell",
 "kl": "kal",
 "sv": "swe",
 ]);
