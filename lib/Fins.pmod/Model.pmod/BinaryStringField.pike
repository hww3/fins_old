inherit .StringField;

constant type = "BinaryString";

string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value);
  if(value == .Undefined)
    return "NULL";
  else
    return "'" + context->quote_binary(value) + "'";
}

mixed decode(string value, void|.DataObjectInstance i)
{
  return context->unquote_binary(value);
}

