import Tools.JSON;

//! A JSONArray is an ordered sequence of values. Its external form is a string
//! wrapped in square brackets with commas between the values. The internal form
//! is an object having get() and opt() methods for accessing the values by
//! index, and put() methods for adding or replacing values. The values can be
//! any of these types: Boolean, JSONArray, JSONObject, Number, String, or the
//! JSONObject.NULL object.
//! 
//! The constructor can convert a JSON external form string into an
//! internal form Java object. The toString() method creates an external
//! form string.
//! 
//! A get() method returns a value if one can be found, and throws an exception
//! if one cannot be found. An opt() method returns a default value instead of
//! throwing an exception, and so is useful for obtaining optional values.
//! 
//! The generic get() and opt() methods return an object which you can cast or
//! query for type. There are also typed get() and opt() methods that do typing
//! checking and type coersion for you.
//! 
//! The texts produced by the toString() methods are very strict.
//! The constructors are more forgiving in the texts they will accept.
//! 
//! An extra comma may appear just before the closing bracket.
//! Strings may be quoted with single quotes.
//! Strings do not need to be quoted at all if they do not contain leading
//!     or trailing spaces, and if they do not contain any of these characters:
//!     { } [ ] / \ : , 
//! Numbers may have the 0- (octal) or 0x- (hex) prefix.
//! 
//! It is sometimes more convenient and less ambiguous to have a NULL.
//! JSONObject.NULL.toString() returns "null".
//! 
//! 
//! 
//! Public Domain 2002 JSON.org
//!
//! Ported to C# by Are Bjolseth, teleplan.no

private object myCustomRenderObject;

//!The hash map where the JSONObject's properties are kept.
private mapping myHashMap;

//! A shadow list of keys to enable access by sequence of insertion
private array myKeyIndexList;

private void|mixed filter_context;

public void set_filter_context(mixed|void ctx)
{
  filter_context = ctx;
}

//!  Construct a JSONObject, either empty, from a JSON datastream, or a pike mapping.
		static void create(void|string|Tools.JSON.JSONTokener|mapping x, mixed|void filter_context)
		{ 
			myHashMap      = ([]);
			myKeyIndexList = ({});
		     set_filter_context(filter_context);

                     if(objectp(x) && object_program(x) == JSONTokener)
                     {
                       fromtokener(x);
                     }
					 else if (objectp(x) && functionp(x->render_json))
                                         {
                                            myCustomRenderObject = x; 
                                         }
					else if(objectp(x))
					 {
					//werror("object: %O\n", x);
						myHashMap      = (mapping)x;
						myKeyIndexList = indices(myHashMap);
					 }
                     else if(stringp(x))
                     {
                       fromtokener(JSONTokener(x));
                     }
                     else if(mappingp(x))
                     {
					   myHashMap      = copy_value(x);
					   myKeyIndexList = indices(x);
                     }
		}

//! @param x
//!    A JSONTokener object containing the source string.
		private void fromtokener(JSONTokener x)
		{
			int c;
			string key;
			if (x->next() == '%') 
			{
				x->unescape();
			}
			x->back();
			if (x->nextClean() != '{') 
			{
				throw(Error.Generic("A JSONObject must begin with '{'"));
			}
			while (1)
			{
				c = x->nextClean();
				switch (c) 
				{
					case 0:
						throw(Error.Generic("A JSONObject must end with '}'"));
					case '}':
						return;
					default:
						x->back();
						key = (string)x->nextObject();
						break;
				}
				if (x->nextClean() != ':') 
				{
					throw(Error.Generic("Expected a ':' after a key"));
				}
				object obj = x->nextObject();
                                if(objectp(obj) && obj->toNative)
  				  myHashMap[key] = obj->toNative();
                                else
  				  myHashMap[key] = obj;
				myKeyIndexList+=({key});
				switch (x->nextClean()) 
				{
					case ',':
						if (x->nextClean() == '}') 
						{
							return;
						}
						x->back();
						break;
					case '}':
						return;
					default:
						throw(Error.Generic("Expected a ',' or '}'"));
				}
			}
		}


//! 
//! Accumulate values under a key. It is similar to the put method except
//! that if there is already an object stored under the key then a
//! JSONArray is stored under the key to hold all of the accumulated values.
//! If there is already a JSONArray, then the new value is appended to it.
//! In contrast, the put method replaces the previous value.
//! 
//! @param key
//!    A key string.
//! @param val
//!    An object to be accumulated under the key.
//! @returns
//!  this
		public JSONObject accumulate(string key, object val)
		{
			JSONArray a;
			object obj = opt(key);
			if (obj == 0)
			{
				put(key, val);
			}
			else if (Program.implements(object_program(obj), JSONArray))
			{
				a = obj;
				a->put(sizeof(a), val);
			}
			else
			{
				a = JSONArray();
				a->set_filter_context(filter_context);
				a->put(sizeof(a), obj);
				a->put(sizeof(a), val);
				put(key,a);
			}
			return this;
		}


//! 
//! Return the key for the associated index
//! 
//!
static mixed `[](mixed i)
{
  if(intp(i))
    return (string)myKeyIndexList[i];
  else if(stringp(i))
    return getValue(i);
}

//!
static void `[]=(mixed key, mixed value)
{
  put(key,value);
}

//! 
//! Return the number of JSON items in hashtable
//! 
//!
static int _sizeof()
{
  return sizeof(myCustomRenderObject||myHashMap);
}


//! 
//! Alias to Java get method
//! Get the value object associated with a key.
//! 
//! @param key
//!    A key string.
//! @returns
//!  The object associated with the key.
		public object getValue(string key)
		{
			mixed obj;

			//return myHashMap[key];
			if(myCustomRenderObject)
                           obj = myCustomRenderObject[key];
			else
			   obj = opt(key);
			if (!obj && zero_type(obj))
			{
				throw(Error.Generic("No such element"));
			}
			return obj;
		}

//! 
//! Get the boolean value associated with a key.
//! 
//! @param key
//!    A key string.
//! @returns
//!  The truth.
		public int(0..1) getBool(string key)
		{
			mixed o = getValue(key);
			if (intp(o))
			{
                                if(o) return 1;
				else return 0;
			}
			string msg = sprintf("JSONObject[%O] is not a Boolean",JSONUtils.Enquote(key));
			throw(Error.Generic(msg));
		}

//! 
//! Get the double value associated with a key.
//! 
//! @param key
//!    A key string.
//! @returns
//!  The double value
		public float getDouble(string key)
		{
			mixed o = getValue(key);
			if (floatp(o))
				return o;

			if (stringp(o))
			{
                                float f;
                                sscanf(o, "%f", f);
				return f;
			}
			string msg = sprintf("JSONObject[%O] is not a double",JSONUtils.Enquote(key));
			throw(Error.Generic(msg));
		}

//! 
//! Get the int value associated with a key.
//! 
//! @param key
//!    A key string
//! @returns
//!   The integer value.
		public int getInt(string key)
		{
			mixed o = getValue(key);
			if (intp(o))
			{
				return (int)o;
			}

			if (stringp(o))
			{
				return (int)(o);
			}
			string msg = sprintf("JSONObject[%O] is not a int",JSONUtils.Enquote(key));
			throw(Error.Generic(msg));
		}

//! 
//! Get the JSONArray value associated with a key.
//! 
//! @param key
//!    A key string
//! @returns
//!  A JSONArray which is the value
		public JSONArray getJSONArray(string key)
		{
			mixed o = getValue(key);
			if (objectp(o) && Program.implements(object_program(o), JSONArray))
			{
				return o;
			}
			string msg = sprintf("JSONObject[%O] is not a JSONArray",JSONUtils.Enquote(key));
			throw(Error.Generic(msg));
		}

//! 
//! Get the JSONObject value associated with a key.
//! 
//! @param key
//!    A key string.
//! @returns
//!  A JSONObject which is the value.
		public JSONObject getJSONObject(string key)
		{
		        mixed o = getValue(key);
			if (objectp(o) && Program.implements(object_program(o), JSONObject))
			{
				return o;
			}
			string msg = sprintf("JSONObject[%O] is not a JSONArray",JSONUtils.Enquote(key));
			throw(Error.Generic(msg));
		}

//! 
//! Get the string associated with a key.
//! 
//! @param key
//!    A key string.
//! @returns
//!  A string which is the value.
		public string getString(string key)
		{
			return (string)getValue(key);
		}


//! 
//! Determine if the JSONObject contains a specific key.
//! 
//! @param key
//!    A key string.
//! @returns
//!  true if the key exists in the JSONObject.
		public int(0..1) has(string key)
		{
			if(myCustomRenderObject && myCustomRenderObject[key])
                          return 1;
                        if( myHashMap[key])
  			  return 1;
                        else return 0;
		}


//! 
//! Get an enumeration of the keys of the JSONObject.
//! Added to be true to orginal Java implementation
//! Indexers are easier to use
//! 
//! @returns
//!  
//!
		static array _indices()
		{
                        if(myCustomRenderObject) return indices(myCustomRenderObject);
			return indices(myHashMap);
		}

//!
		static array _values()
		{
                        if(myCustomRenderObject) return values(myCustomRenderObject);
			return values(myHashMap);
		}

//! 
//! Determine if the value associated with the key is null or if there is no value.
//! 
//! @param key
//!    A key string
//! @returns
//!  true if there is no value associated with the key or if the valus is the JSONObject.NULL object
		public int(0..1) isNull(string key)
		{
                        if(myCustomRenderObject) return NULLObject.equals(myCustomRenderObject[key]);
			return NULLObject.equals(opt(key));
		}

//! 
//! Get the number of keys stored in the JSONObject.
//! 
//! @returns
//!  The number of keys in the JSONObject.
		public int Length()
		{
                        if(myCustomRenderObject) return sizeof(myCustomRenderObject);
			return sizeof(myHashMap);
		}



//! 
//! Get an optional value associated with a key.
//! 
//! @param key
//!    A key string
//! @returns
//!  An object which is the value, or null if there is no value.
		public mixed opt(string key)
		{
			if (!key)
			{
				throw(Error.Generic("Null key"));
			}
                        if(myCustomRenderObject) return myCustomRenderObject[key];
			return myHashMap[key];
		}


//! 
//! Get an optional value associated with a key.
//! It returns false if there is no such key, or if the value is not
//! Boolean.TRUE or the String "true".
//! 
//! @param key
//!    A key string.
//! @param defaultValue
//!    The preferred return value if conversion fails
//! @returns
//!  bool value object
		public int(0..1) optBoolean(string key, void|int(0..1) defaultValue)
		{
			mixed obj = getValue(key);
			if (obj)
			{
				if (intp(obj))
                                {
                                   if(obj)
                                   {
                                     return 1;
                                   }
                                   else return 0;
                                }
				if (stringp(obj))
				{
                                  if(obj == "true")
                                    return 1;
                                  if(obj == "false")
                                    return 0;
				}
			}
			return defaultValue;
		}


//! 
//! Get an optional double associated with a key,
//! or NaN if there is no such key or if its value is not a number.
//! If the value is a string, an attempt will be made to evaluate it as
//! a number.
//! 
//! @param key
//!    A string which is the key.
//! @param defaultValue
//!    The default
//! @returns
//!  A double value object
		public float optFloat(string key, float|void defaultValue)
		{
			mixed obj = opt(key);
			if (obj)
			{
				if (floatp(obj))
                                  return obj;
                                if(intp(obj))
                                  return (float)obj;
				if (stringp(obj))
				{
					return (float)obj;
				}
			}
			return defaultValue;

		}

//! 
//!  Get an optional double associated with a key, or the
//!  defaultValue if there is no such key or if its value is not a number.
//!  If the value is a string, an attempt will be made to evaluate it as
//!  number.
//! 
//! @param key
//!    A key string.
//! @param defaultValue
//!    The default value
//! @returns
//!  An int object value
		public int optInt(string key, int|void defaultValue)
		{
			mixed obj = opt(key);
			if (obj)
			{
				if (intp(obj))
					return (int)obj;
				if (stringp(obj))
					return (int)obj;
			}
			return defaultValue;
		}

//! 
//! Get an optional JSONArray associated with a key.
//! It returns null if there is no such key, or if its value is not a JSONArray
//! 
//! @param key
//!    A key string
//! @returns
//!  A JSONArray which is the value
		public JSONArray optJSONArray(string key)
		{
			mixed obj = opt(key);
			if (objectp(obj) && Program.implements(object_program(obj), JSONArray))
			{
				return obj;
			}
			return 0;
		}

//! 
//! Get an optional JSONObject associated with a key.
//! It returns null if there is no such key, or if its value is not a JSONObject.
//! 
//! @param key
//!    A key string.
//! @returns
//!  A JSONObject which is the value
		public JSONObject optJSONObject(string key)
		{
			mixed obj = opt(key);
			if (obj && Program.implements(object_program(obj), JSONObject))
			{
				return obj;
			}
			return 0;
		}


//! 
//! Get an optional string associated with a key.
//! It returns the defaultValue if there is no such key.
//! 
//! @param key
//!    A key string.
//! @param defaultValue
//!    The default
//! @returns
//!  A string which is the value.
		public string optString(string key, string|void defaultValue)
		{
			mixed obj = opt(key);
			if (obj)
			{
				return (string)obj;
			}
			return defaultValue ||"";
		}

//! 
//! Put a key/value pair in the JSONObject. If the value is null,
//! then the key will be removed from the JSONObject if it is present.
//! 
//! @param key
//!     A key string.
//! @param val
//!    
//! An object which is the value. It should be of one of these
//! types: Boolean, Double, Integer, JSONArray, JSONObject, String, or the
//! JSONObject.NULL object.
//! 
//! @returns
//!  JSONObject
//!
		public JSONObject put(string key, mixed val)
		{
			if (!key)
			{
				throw(Error.Generic("key cannot be null"));
			}
			if (!val && !zero_type(val))
			{
				if (!myHashMap[key] && !zero_type(myHashMap[key]))
				{
					myHashMap[key]=val;
					myKeyIndexList+=({key});
				}
				else
				{
					myHashMap[key]=val;
				}
			}
			else 
			{
				remove(key);
			}
			return this;
		}

//! 
//! Add a key value pair
//! 
//! @param key
//!    
//! @param val
//!    
//! @returns
//!  
		public JSONObject putOpt(string key, mixed val)
		{
			if (!val && !zero_type(val))
			{
				put(key,val);
			}
			return this;
		}


//! 
//! Remove a object assosiateted with the given key
//! 
//! @param key
//!    
//! @returns
//!  
//!
		public mixed remove(string key)
		{
			if (myHashMap[key] || !zero_type(myHashMap[key]))
			{
				// TODO - does it really work ???
				mixed obj = myHashMap[key];
				m_delete(myHashMap, key);
				myKeyIndexList-=({key});
				return obj;
			}
			return UNDEFINED;
		}

//! 
//! Append an array of JSONObjects to current object
//! 
//! @param names
//!    
//! @returns
//!  
		public JSONArray toJSONArray(JSONArray names)
		{
			if (!names || sizeof(names) == 0)
				return UNDEFINED;

			JSONArray ja = JSONArray();
                        ja->set_filter_context(filter_context);
			for (int i=0; i<sizeof(names); i++)
			{
			  ja->put(sizeof(ja), this->opt(names->getString(i)));
			}
			return ja;
		}

//!
static mixed cast(string to)
{
  if(to =="string")
    return ToString();
  if(to =="mapping")
    return copy_value(myHashMap);
}

//! 
//! Overridden to return a JSON formatted object as a string
//! 
//! @returns
//!  JSON object as formatted string
		public string ToString()
		{
			mixed obj;
			//string s;
			if(myCustomRenderObject)
			{
			  mixed filter_fields;
			  if(filter_context)
			  {
			    filter_fields = filter_context->get_filter_for_program(object_program(myCustomRenderObject));
                          }
			  return myCustomRenderObject->render_json(filter_fields);
			}
			else
                        {
			  mixed filter_fields;

			  if(filter_context)
			  {
			    filter_fields = filter_context->get_default_filter();
                          }
			String.Buffer sb = String.Buffer();

			sb+=("{");
			foreach (myHashMap;string key;mixed val)  //NOTE! Could also use myKeyIndexList !!!
			{
			  mixed filter_fields;
				if(filter_fields && multisetp(filter_fields) && filter_fields[key]) continue;
				else if(filter_fields && functionp(filter_fields) && filter_fields(key, val)) continue;
				if (obj)
					sb+=(",");
				obj = myHashMap[key];
				if (obj)
				{
					sb+=(JSONUtils.Enquote(key));
					sb+=(":");

					if (stringp(obj))
					{
					   sb+=(JSONUtils.Enquote(obj));
					}
					else if (floatp(obj))
					{
						sb+=(JSONUtils.numberToString(obj));
					}
					// boolean is a problem...
                                        else if(arrayp(obj))
                                        {
                                           sb+=((string)JSONArray(obj, filter_context));
                                        }
                                        else if(mappingp(obj))
                                        {
                                           sb+=((string)JSONObject(obj, filter_context));
                                        }
					else
					{
		//			werror("obj: %O\n", obj);
						sb+=((string)obj);
					}
				}
			}
			sb+=("}");
			return sb->get();
			}

		}

mapping toNative()
{
  return (mapping)this;
}
