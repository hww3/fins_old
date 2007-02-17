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
//
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
//! Public Domain 2002 JSON.org
//! @author JSON.org
//! @version 0.1
//!
//! Ported to C# by Are Bjolseth, teleplan.no


//! The ArrayList where the JSONArray's properties are kept.
private array myArrayList;

//! Construct a JSONArray, empty, from a JSON datastream, or a Pike array.
static void create(void|JSONTokener|string|array x)
{
  myArrayList = ({});
  if(stringp(x))
  {
    fromtokener(JSONTokener(x));
  }
  if(objectp(x))
  {
    fromtokener(x);
  }
  if(arrayp(x))
  {
    myArrayList = copy_value(x);
  }
}

//! Construct a JSONArray from a JSONTokener.
//! @param x
//!   A JSONTokener
public void fromtokener(JSONTokener x)
{
  if (x->nextClean() != '[') 
  {
    throw(Error.Generic("A JSONArray must start with '['"));
  }
  if (x->nextClean() == ']') 
  {
    return;
  }
  x->back();
  while (1) 
  {
    mixed obj = x->nextObject();
    if(objectp(obj) && obj->toNative)
      myArrayList+=({obj->toNative()});
    else
      myArrayList+=({obj});
    switch (x->nextClean()) 
    {
      case ',':
	if (x->nextClean() == ']') 
	{
	  return;
	}
	x->back();
	break;
      case ']':
	return;
      default:
	throw(Error.Generic("Expected a ',' or ']'"));
    }
  }
}

//!
static mixed `[](mixed i)
{
  return getValue(i);
}

//!
static void `[]=(mixed key, mixed value)
{
  put(key,value);
}


public mixed getValue(int i)
{
  mixed obj = opt(i);
  if (!obj && zero_type(obj))
  {
    string msg = sprintf("JSONArray[%O] not found", i);
    throw(Error.Generic(msg));
  }
  return obj;
  //return myArrayList[i];
}

//! Get the ArrayList which is holding the elements of the JSONArray.
//! Use the indexer instead!! Added to be true to the orignal Java src
//! 
//! The ArrayList
public array getArrayList()
{
  return myArrayList;
}

//! Get the boolean value associated with an index.
//! The string values "true" and "false" are converted to boolean.
//! @param i
//! index subscript
//!
//! @returns
//! The truth
public int(0..1) getBoolean(int i)
{
  object obj = getValue(i);
  if (intp(obj))
  {
    if(obj) return 1;
    else return 0;
  }
  string msg = sprintf("JSONArray[%O]=%O not a Boolean", i, obj);
  throw(Error.Generic(msg));
}

//! 
//! Get the double value associated with an index.
//! 
//! @param i
//! index subscript
//! @returns
//! A double value
public float getDouble(int i)
{
  mixed o = getValue(i);
  if (floatp(o))
    return o;

  if (stringp(o))
  {
    float f;
    sscanf(o, "%f", f);
    return f;
  }
  string msg = sprintf("JSONArray[%O] is not a double", i);
  throw(Error.Generic(msg));
}

//! 
//! Get the int value associated with an index.
//! 
//! @param i
//! index subscript
//! @returns
//! The int value
public int getInt(int i)
{
  mixed o = getValue(i);
  if (intp(o))
  {
    return (int)o;
  }

  if (stringp(o))
  {
    return (int)(o);
  }
  string msg = sprintf("JSONArray[%O] is not a int", i);
  throw(Error.Generic(msg));

}

//! 
//! Get the JSONArray associated with an index.
//! 
//! @param i
//! index subscript
//! @returns
//! A JSONArray value
public JSONArray getJSONArray(int i)
{
  mixed o = getValue(i);
  if (objectp(o) && Program.implements(object_program(o), JSONArray))
  {
    return o;
  }
  string msg = sprintf("JSONObject[%O] is not a JSONArray", i);
  throw(Error.Generic(msg));
}

//! 
//! Get the JSONObject associated with an index.
//! 
//! @param i
//! index subscript
//! @returns
//! A JSONObject value
public JSONObject getJSONObject(int i)
{
  mixed o = getValue(i);
  if (objectp(o) && Program.implements(object_program(o), JSONObject))
  {
    return o;
  }
  string msg = sprintf("JSONArray[%O] is not a JSONArray", i);
  throw(Error.Generic(msg));

}

//! 
//! Get the string associated with an index.
//! 
//! @param i
//! index subscript
//! @returns
//! A string value.
public string getString(int i)
{
  return (string)getValue(i);
}

//! 
//! Determine if the value is null.
//! 
//! @param i
//! index subscript
//! @returns
//! true if the value at the index is null, or if there is no value.
public int(0..1) isNull(int i)
{
  mixed obj = opt(i);
  return (!obj);
}

//! 
//! Make a string from the contents of this JSONArray. The separator string
//! is inserted between each element.
//! Warning: This method assumes that the data structure is acyclical.
//! 
//! @param separator
//! separator A string that will be inserted between the elements.
//! @returns
//! A string.
public string join(string separator)
{
  mixed obj;
  String.Buffer sb = String.Buffer();
  for (int i=0; i<sizeof(myArrayList); i++)
  {
    if (i > 0)
    {
      sb+=(separator);
    }
    obj = myArrayList[i];

    if (!obj)
    {
      sb+=("");
    }
    else if (stringp(obj))
    {
      sb+=(JSONUtils.Enquote(obj));
    }
    else if(intp(obj) || floatp(obj))
    {
      sb+=(JSONUtils.numberToString(obj));
    }
    else if(arrayp(obj))
    {
      sb+=((string)JSONArray(obj));
    }
    else if(mappingp(obj))
    {

      sb+=((string)JSONObject(obj));
    }
    else
    {
      sb+=((string)obj);
    }
  }
  return sb->get();
}

//! 
//! Get the length of the JSONArray.
//! Added to be true to the original Java implementation
//! 
//! @returns
//! Number of JSONObjects in array
public int Length()
{
  return sizeof(myArrayList);
}

//! 
//! Get the optional object value associated with an index.
//! 
//! @param i
//! index subscript
//! @returns
//! object at that index.
public mixed opt(int i)
{
  if (i < 0 || i >= sizeof(myArrayList))
    throw(Error.Generic("Index out of bounds!"));

  return myArrayList[i];
}


//! 
//! Get the optional boolean value associated with an index.
//! It returns the defaultValue if there is no value at that index or if it is not
//! a Boolean or the String "true" or "false".
//! 
//! @param i
//! index subscript
//! @param defaultValue
//! 
//! @returns
//! The truth.
public int(0..1) optBoolean(int i, int(0..1)|void defaultValue)
{
  mixed obj = opt(i);
  if (obj)
  {
    return 1;
  }
  else return 0;
}

//! 
//! Get the optional double value associated with an index.
//! NaN is returned if the index is not found,
//! or if the value is not a number and cannot be converted to a number.
//! 
//! @param i
//! index subscript
//! @param defaultValue
//! 
//! @returns
//! The double value object
public float optDouble(int i)
{
  mixed obj = opt(i);
  if (obj)
  {
    if (floatp(obj))
      return (float)obj;
    if (stringp(obj))
    {
      return (float)obj;
    }				
    string msg = sprintf("JSONArray[%O]=%O not a double", i, obj);
    throw(Error.Generic(msg));
  }
  return 0;
}

//! 
//! Get the optional int value associated with an index.
//! Zero is returned if the index is not found,
//! or if the value is not a number and cannot be converted to a number.
//! 
//! @param i
//! index subscript
//! @returns
//! The int value object

//! 
//! Get the optional int value associated with an index.
//! The defaultValue is returned if the index is not found,
//! or if the value is not a number and cannot be converted to a number.
//! 
//! @param i
//! index subscript
//! @param defaultValue
//! The default value
//! @returns
//! The int value object
public int optInt(int i)
{
  mixed obj = opt(i);
  if (obj)
  {
    if (intp(obj))
      return obj;
    if (stringp(obj))
      return (int)(obj);			
    string msg = sprintf("JSONArray[%O]=%O not a int", i, obj);
    throw(Error.Generic(msg));
  }
  return UNDEFINED;
}

//! 
//! Get the optional JSONArray associated with an index.
//! 
//! @param i
//! index subscript
//! @returns
//! A JSONArray value, or null if the index has no value, or if the value is not a JSONArray.
public JSONArray optJSONArray(int i)
{
  mixed obj = opt(i);
  if (objectp(obj))
    return obj;
  return UNDEFINED;
}

//! 
//! Get the optional JSONObject associated with an index.
//! Null is returned if the key is not found, or null if the index has
//! no value, or if the value is not a JSONObject.
//! 
//! @param i
//! index subscript
//! @returns
//! A JSONObject value
public JSONObject optJSONObject(int i)
{
  mixed obj = opt(i);
  if (objectp(obj))
  {
    return obj;
  }
  return UNDEFINED;
}

//! 
//! Get the optional string value associated with an index. It returns an
//! empty string if there is no value at that index. If the value
//! is not a string and is not null, then it is coverted to a string.
//! 
//! @param i
//! index subscript
//! @returns
//! A String value

//! 
//! Get the optional string associated with an index.
//! The defaultValue is returned if the key is not found.
//! 
//! @param i
//! index subscript
//! @param defaultValue
//! The default value
//! @returns
//! A string value
public string optString(int i, string|void defaultValue)
{
  mixed obj = opt(i);
  if (obj)
  {
    return (string)obj;
  }
  return defaultValue;
}


/**
 * OMITTED:
 * public JSONArray put(bool val)
 * public JSONArray put(double val)
 * public JSONArray put(int val)		
 */
//! 
//! Append an object value.
//! 
//! @param val
//! An object value.  The value should be a Boolean, Double, Integer, JSONArray, JSObject, or String, or the JSONObject.NULL object
//! @returns
//! this (JSONArray)

/*
 * OMITTED:
 * public JSONArray put(int index, boolean value)
 * public JSONArray put(int index, double value)
 * public JSONArray put(int index, int value)
 */
//! 
//! Put or replace a boolean value in the JSONArray.
//! 
//! @param i
//! The subscript. If the index is greater than the length of
//! the JSONArray, then null elements will be added as necessary to pad it out.
//! 
//! @param val
//! An object value.
//! @returns
//! this (JSONArray)
public JSONArray put(int i, mixed val)
{
  if (i < 0)
  {
    throw(Error.Generic("Negative indexes illegal"));
  }
  else if (!val && zero_type(val))
  {
    throw(Error.Generic("Object cannt be null"));
  }
  else if (i < sizeof(myArrayList))
  {
    myArrayList[i] = val;
  }
  // NOTE! Since i is >= Count, fill null vals before index i, then append new object at i
  else
  {
    while (i != sizeof(myArrayList))
    {
      myArrayList+=({UNDEFINED});
    }
    myArrayList+=({val});
  }
  return this;
}

//! 
//! Produce a JSONObject by combining a JSONArray of names with the values
//! of this JSONArray.
//! 
//! @param names
//! A JSONArray containing a list of key strings. These will be paired with the values.
//! 
//! @returns
//! A JSONObject, or null if there are no names or if this JSONArray
public JSONObject toJSONObject(JSONArray names)
{
  if (!names || sizeof(names) == 0 || sizeof(this) == 0) 
  {
    return 0;
  }
  JSONObject jo = JSONObject();
  for (int i=0; i <sizeof(names); i++)
  {
    jo->put((string)names[i], opt(i));
  }
  return jo;
}

//! 
//! Make an JSON external form string of this JSONArray. For compactness, no
//! unnecessary whitespace is added.
//! 
//! @returns
//! a printable, displayable, transmittable representation of the array.
//!
static mixed cast(string to)
{
  if(to == "string")
    return ToString();
  if(to == "array")
    return copy_value(getArrayList());
}

public string ToString()
{
  return "["+ join(",") + "]";
}

public array toNative()
{
  return (array)this;
}
