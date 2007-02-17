import Tools.JSON;
//! 
//! 
//!  A JSONTokener takes a source string and extracts characters and tokens from
//!  it. It is used by the JSONObject and JSONArray constructors to parse
//!  JSON source strings.
//!  
//!  
//!  Public Domain 2002 JSON.org
//!  @author JSON.org
//!  @version 0.1
//!  
//!  Ported to C# by Are Bjolseth, teleplan.no
//!  

//! The index of the next character.
		private int myIndex;
//! The source string being tokenized.
		private string mySource;

//! 
//! Construct a JSONTokener from a string.
//! 
//! @param s
//!  A source string.
		static void create(string s)
		{
			myIndex = 0;
			mySource = s;
		}

//! 
//! Back up one character. This provides a sort of lookahead capability,
//! so that you can test for a digit or letter before attempting to parse
//! the next number or identifier.
//! 
		public void back()
		{
			if (myIndex > 0)
				myIndex -= 1;
		}

//! 
//! Get the hex value of a character (base16).
//! 
//! @param c
//!  
//! A character between '0' and '9' or between 'A' and 'F' or
//! between 'a' and 'f'.
//! 
//! @returns
//!  An int between 0 and 15, or -1 if c was not a hex digit.
		public static int dehexchar(int c)
		{
			if (c >= '0' && c <= '9') 
			{
				return c - '0';
			}
			if (c >= 'A' && c <= 'F') 
			{
				return c + 10 - 'A';
			}
			if (c >= 'a' && c <= 'f') 
			{
				return c + 10 - 'a';
			}
			return -1;
		}

//! 
//! Determine if the source string still contains characters that next() can consume.
//! 
//! @returns
//!  true if not yet at the end of the source.
		public int more()
		{
			return myIndex < sizeof(mySource);
		}

//! 
//! Get the next character in the source string.
//! 
//! @returns
//!  The next character, or 0 if past the end of the source string.
		public int next(int|void x)
		{
                   if(x)
                   {
			int n = next();
			if (n != x)
			{
				string msg = "Expected '" + x + "' and instead saw '" +	n + "'.";
				throw (Error.Generic(msg));
			}
			return n;
		    }
                    else
                    {
			int c = more() ? mySource[myIndex] : 0;
			myIndex +=1;
			return c;
                    }
		}


//! 
//! Get the next n characters.
//! 
//! @param n
//!  The number of characters to take.
//! @returns
//!  A string of n characters.
		public string nextn(int n)
		{
			int i = myIndex;
			int j = i + n;
			if (j >= sizeof(mySource))
			{
				string msg = "Substring bounds error";
				throw (Error.Generic(msg));
			}
			myIndex += n;
			return mySource[i..j];
		}

//! 
//! Get the next char in the string, skipping whitespace
//! and comments (slashslash and slashstar).
//! 
//! @returns
//!  A character, or 0 if there are no more characters.
		public int nextClean()
		{
			while (1) 
			{
				int c = next();
				if (c == '/') 
				{
					switch (next()) 
					{
						case '/':
							do 
							{
								c = next();
							} while (c != '\n' && c != '\r' && c != 0);
							break;
						case '*':
							while (1) 
							{
								c = next();
								if (c == 0) 
								{
									throw (Error.Generic("Unclosed comment."));
								}
								if (c == '*') 
								{
									if (next() == '/') 
									{
										break;
									}
									back();
								}
							}
							break;
						default:
							back();
							return '/';
					}
				} 
				else if (c == 0 || c > ' ') 
				{
					return c;
				}
			}
		}

//! 
//! Return the characters up to the next close quote character.
//! Backslash processing is done. The formal JSON format does not
//! allow strings in single quotes, but an implementation is allowed to
//! accept them.
//! 
//! @param quote
//!  The quoting character, either " or '
//! @returns
//!  A String.
		public string nextString(int quote)
		{
			int c;
			String.Buffer sb = String.Buffer();
			while (1)
			{
				c = next();
				if ((c == 0x00) || (c == 0x0A) || (c == 0x0D)) 
				{
					throw (Error.Generic("Unterminated string"));
				}
				// CTRL chars
				if (c == '\\')
				{
					c = next();
					switch (c)
					{
						case 'b': //Backspace
							sb+=("\b");
							break;
						case 't': //Horizontal tab
							sb+=("\t");
							break;
						case 'n':  //newline
							sb+=("\n");
							break;
						case 'f':  //Form feed
							sb+=("\f");
							break;
						case 'r':  // Carriage return
							sb+=("\r");
							break;
						case 'u':
							int iascii;
                                                        sscanf(nextn(4), "%4x", iascii);
							sb+=String.int2char(iascii);
							break;
						default:
							sb+=String.int2char(c);
							break;
					}
				}
				else
				{
					if (c == quote)
					{
						return sb->get();
					}
					sb+=String.int2char(c);
				}
			}//END-while
		}

//! 
//! Get the text up but not including the specified character or the
//! end of line, whichever comes first.
//! 
//! @param d
//!  A delimiter character.
//! @returns
//!  A string.
		public string nextTo(int|string d)
		{
                 
                     if(intp(d))
                     {
			String.Buffer sb = String.Buffer();
			while (1)
			{
				int c = next();
				if (c == d || c == 0 || c == '\n' || c == '\r') 
				{
					if (c != 0) 
					{
						back();
					}
					return String.trim_whites(sb->get());
				}
				sb+=String.int2char(c);
			}
		     }    

    		     else if(stringp(d))
                     {
			int c;
			String.Buffer sb = String.Buffer();
			while (1)
			{
				c = next();
				if ((d[c] >= 0) || (c == 0 ) || (c == '\n') || (c == '\r'))
				{
					if (c != 0)
					{
						back();
					}
					return String.trim_whites(sb->get());
				}
				sb+=String.int2char(c);
			}
                    }
		}

//! 
//! Get the next value as object. The value can be a Boolean, Double, Integer,
//! JSONArray, JSONObject, or String, or the JSONObject.NULL object.
//! 
//! @returns
//!  An object.
		public mixed nextObject()
		{
			int c = nextClean();
			string s;

			if (c == '"' || c == '\'') 
			{
				return nextString(c);
			}
			// Object
			if (c == '{') 
			{
				back();
				return JSONObject(this);
			}

			// JSON Array
			if (c == '[')
			{
				back();
				return JSONArray(this);
			}

			String.Buffer sb = String.Buffer();

			int b = c;
			while (c >= ' ' && c != ':' && c != ',' && c != ']' && c != '}' && c != '/')
			{
				sb+=String.int2char(c);
				c = next();
			}
			back();

			s = String.trim_whites(sb->get());
			if (s == "true")
				return 1; 
			if (s == "false")
				return 0;
			if (s == "null")
				return UNDEFINED;

			if ((b >= '0' && b <= '9') || b == '.' || b == '-' || b == '+') 
			{
                           int a; float b; string c;
                           [a, c] = array_sscanf(s, "%d%s");
                           if(c && sizeof(c))
                           {
                             [b] = array_sscanf(s, "%f");
			     return b;;
                           }
                           else return a;
			}
			if (s == "")
			{
				throw (Error.Generic("Missing value"));
			}
			return s;
		}

//! 
//! Skip characters until the next character is the requested character.
//! If the requested character is not found, no characters are skipped.
//! 
//! @param to
//!  A character to skip to.
//! @returns
//!  
//! The requested character, or zero if the requested character is not found.
//! 
		public int skipTo(int to)
		{
			int c;
			int i = myIndex;
			do
			{
				c = next();
				if (c == 0)
				{
					myIndex = i;
					return c;
				}
			}while (c != to);

			back();
			return c;
		}

//! 
//! Skip characters until past the requested string.
//! If it is not found, we are left at the end of the source.
//! 
//! @param to
//!  A string to skip past.
		public void skipPast(string to)
		{
			myIndex = search(mySource, to, myIndex);
			if (myIndex < 0)
			{
				myIndex = sizeof(mySource);
			}
			else
			{
				myIndex += sizeof(to);
			}
		}

		// TODO implement exception SyntaxError


//! 
//! Make a printable string of this JSONTokener.
//! 
//! @returns
//!  " at character [myIndex] of [mySource]"
		public string ToString()
		{
			return " at character " + myIndex + " of " + mySource;
		}

//! 
//! Unescape the source text. Convert %hh sequences to single characters,
//! and convert plus to space. There are Web transport systems that insist on
//! doing unnecessary URL encoding. This provides a way to undo it.
//! 
//! 
//! Convert %hh sequences to single characters, and convert plus to space.
//! 
//! @param s
//!  A string that may contain plus and %hh sequences.
//! @returns
//!  The unescaped string.
		public string unescape(string|void s)
		{
                        if(!s) s = mySource;
			int len = sizeof(s);
			String.Buffer sb = String.Buffer();
			for (int i=0; i < len; i++)
			{
				int c = s[i];
				if (c == '+')
				{
					c = ' ';
				}
				else if (c == '%' && (i + 2 < len))
				{
					int d = dehexchar(s[i+1]);
					int e = dehexchar(s[i+2]);
					if (d >= 0 && e >= 0)
					{
						c = (d*16 + e);
						i += 2;
					}
				}
				sb+=String.int2char(c);
			}
			return sb->get();
		}
