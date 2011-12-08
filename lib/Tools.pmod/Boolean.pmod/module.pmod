

int(0..1) fromString(string bool)
{
  bool = String.trim_whites(bool);
  bool = lower_case(bool);
  switch(bool)
  { 
    case "yes":
    case "true":
    case "1":
      return 1;
    case "no":
    case "false":
    case "0":
      return 0;
  }
}
