//!
constant DEBUG = 1;

//!
constant INFO = 2;

//!
constant WARN = 4;

//!
constant ERROR = 8;

//!
constant CRITICAL = 16;

//!
static array appenders = ({});

int loglevel = DEBUG|INFO|WARN|ERROR|CRITICAL;

mapping log_strs = ([
  DEBUG: "DEBUG", 
  INFO: "INFO",
  WARN: "WARN",
  ERROR: "ERROR",
  CRITICAL: "CRITICAL"
]);

static void create(mapping|void config)
{
  // NOTE: we probably shouldn't do this...
//  if(!config) werror("Logger.create(%O)\n", backtrace());
  if(!config)
    set_appenders(({ .FileAppender() }));
}

public void set_appenders(array a)
{
//  werror("set_appenders: %O\n", a);
  appenders = a;
}

static void do_msg(int level, string m, mixed|void ... extras)
{
//werror("DEBUG: %s, %O\n", m, extras);
  if(!(loglevel & level))
    return;

  if(extras && sizeof(extras))
  {
    m = sprintf(m, @extras);
  }

  mapping lt = localtime(time());
//throw(Error.Generic("whee!\n"));
  appenders->write("%02d:%02d:%02d %s - %s\n", lt->hour, lt->min, lt->sec, log_strs[level], m);

//  stderr->write("%02d:%02d:%02d %s %s - %s\n", lt->hour, lt->min, lt->sec, log_strs[level], 
//                      function_name(backtrace()[-3][2]), m);
}

//!
void exception(string msg, object|array exception)
{
  msg = msg + "\n%s";
  string e;

  if(objectp(exception))
    e = exception->describe();
  else e = describe_backtrace(exception);
  appenders->write(sprintf("An exception occurred : " + msg + "\n", e));  
}

//!
void debug(string msg, mixed|void ... extras)
{
  do_msg(DEBUG, msg, @extras); 
}


//!
void info(string msg, mixed|void ... extras)
{
  do_msg(INFO, msg, @extras); 
}

//!
void warn(string msg, mixed|void ... extras)
{
  do_msg(WARN, msg, @extras); 
}

//!
void error(string msg, mixed|void ... extras)
{
  do_msg(ERROR, msg, @extras); 
}

//!
void critical(string msg, mixed|void ... extras)
{
  do_msg(CRITICAL, msg, @extras); 
}

//! by default, we start with full logging. use this method to 
//! modify the log level.
void set_level(int level)
{
  loglevel = level;
}

string _sprintf(mixed ... args)
{
  return "logger()";//, appenders);
}
