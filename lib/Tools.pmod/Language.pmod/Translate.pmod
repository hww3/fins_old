//! a simple interface to the Google Translate service
//!
//! based upon code from the Google API project 
//! (http://code.google.com/p/google-api-translate-java/)
//!

string URL_STRING = "http://translate.google.com/translate_t";
string ENCODING = "UTF-8";
string TEXT_VAR = "text";
string LANGPAIR_VAR = "langpair";
string INTERMEDIATE_LANGUAGE = ENGLISH;

//!
constant ARABIC = "ar";

//!
constant CHINESE = "zh";

//!
constant CHINESE_SIMPLIFIED = "zh-CN";

//!
constant CHINESE_TRADITIONAL = "zh-TW";

//!
constant DUTCH = "nl";

//!
constant ENGLISH = "en";

//!
constant FRENCH = "fr";

//!
constant GERMAN = "de";

//!
constant GREEK = "el";

//!
constant ITALIAN = "it";

//!
constant JAPANESE = "ja";

//!
constant KOREAN = "ko";

//!
constant PORTUGESE = "pt";

//!
constant RUSSIAN = "ru";

//!
constant SPANISH = "es";

multiset validLanguages = (<
                             ARABIC,
                             CHINESE,
                             CHINESE_SIMPLIFIED,
                             CHINESE_TRADITIONAL,
                             ENGLISH,
                             FRENCH,
                             GERMAN,
                             ITALIAN,
                             JAPANESE,
                             KOREAN,
                             PORTUGESE,
                             RUSSIAN,
                             SPANISH
                          >);
multiset validLanguagePairs = (<
                        ARABIC + "|" +ENGLISH,
                        CHINESE + "|" +ENGLISH,
                        CHINESE_SIMPLIFIED + "|" +CHINESE_TRADITIONAL,
                        CHINESE_TRADITIONAL + "|" +CHINESE_SIMPLIFIED,
                        DUTCH + "|" +ENGLISH,
                        ENGLISH + "|" +ARABIC,
                        ENGLISH + "|" +CHINESE,
                        ENGLISH + "|" +CHINESE_SIMPLIFIED,
                        ENGLISH + "|" +CHINESE_TRADITIONAL,
                        ENGLISH + "|" +DUTCH,
                        ENGLISH + "|" +FRENCH,
                        ENGLISH + "|" +GERMAN,
                        ENGLISH + "|" +GREEK,
                        ENGLISH + "|" +ITALIAN,
                        ENGLISH + "|" +JAPANESE,
                        ENGLISH + "|" +KOREAN,
                        ENGLISH + "|" +PORTUGESE,
                        ENGLISH + "|" +RUSSIAN,
                        ENGLISH + "|" +SPANISH,
                        FRENCH + "|" +ENGLISH,
                        FRENCH + "|" +GERMAN,
                        GERMAN + "|" +ENGLISH,
                        GERMAN + "|" +FRENCH,
                        GREEK +" |" +ENGLISH,
                        ITALIAN + "|" +ENGLISH,
                        JAPANESE + "|" +ENGLISH,
                        KOREAN + "|" +ENGLISH,
                        PORTUGESE + "|" +ENGLISH,
                        RUSSIAN + "|" +ENGLISH,
                        SPANISH + "|" +ENGLISH
                      >);


//! translates a string
//!
//! @param from
//!   a language to translate from;
//!   valid options are constants contained in this module
//!
//! @param to
//!   a language to translate to;
//!   valid options are constants contained in this module
//!
//! @returns
//!  the translated string
string translate(string text, string from, string to)
{
  if(isValidLanguagePair(from,to))
  {
    return retrieveTranslation(text, from, to);
  }
  else
  {
    return retrieveTranslation(retrieveTranslation(text,from,INTERMEDIATE_LANGUAGE), INTERMEDIATE_LANGUAGE, to);
  }
}


string retrieveTranslation(string text, string from, string to)
{
  string data = Protocols.HTTP.get_url_data(URL_STRING, 
                             ([LANGPAIR_VAR : from + "|" + to, TEXT_VAR : text]), 
                             (["User-Agent" : "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)"]) );

  if(!data) throw(Error.Generic("Unable to connect to translation service\n"));

  int start;

  start = search(data, "<div id=result_box dir=");
  if(start ==-1)
    throw(Error.Generic("Translation service returned no result.\n"));

  data = data[start..];

  string result;
  sscanf(data, "<%*s>%s</div>%*s", result);

  return result;  
}


//!
int isValidLanguage(string lang)
{
  return validLanguages[lang];
}


//!
int isValidLanguagePair(string from, string to)
{
  return validLanguagePairs[from + "|" + to];
}
