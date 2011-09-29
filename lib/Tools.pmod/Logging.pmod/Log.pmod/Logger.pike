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

mapping strs_log = ([
  "DEBUG": DEBUG, 
  "INFO": INFO,
  "WARN": WARN,
  "ERROR": ERROR,
  "CRITICAL": CRITICAL
]);

mapping local_vars = (["pid": getpid(), "host": gethostname() ]);

static void create(mapping|void config)
{
  // NOTE: we probably shouldn't do this...
//  if(!config) werror("Logger.create(%O)\n", backtrace());

  configure(config||([]));
  local_vars["name"] = config?(config->name):"default";
}

void configure(mapping config)
{
//	werror("Logger.configure: %O\n", config);
  if(config->level)
    set_level(strs_log[config->level]);
  else
    set_level(DEBUG);

  if(!config->appender)
  {
    set_appenders(({ .ConsoleAppender(([])) }));
  }
  else
  {
    array appenders = Tools.Logging["get_appenders"](arrayp(config->appender)?config->appender:({config->appender}));
    set_appenders(appenders);
  }
}

protected public void set_appenders(array a)
{
//  werror("set_appenders: %O\n", a);
  appenders = a;
}

public void low_do_msg(string loggername, int level, string m, mixed|void ... extras)
{
  if(level < loglevel)
    return;

  if(extras && sizeof(extras))
  {
    m = sprintf(m, @extras);
  }

  mapping lt = localtime(time());
  lt->year += 1900;
  lt->mon += 1;
  lt->timezone /= 3600;

  appenders->write(local_vars + lt + (["name": loggername, "level": log_strs[level], "msg": m]));
    
}

//! only use for special occasions.
public void do_msg(int level, string m, mixed|void ... extras)
{
   low_do_msg(local_vars->name, level, m, @extras);
//if(!log_strs[level]) werror(master()->describe_backtrace(backtrace()) + "\n");
//werror("DEBUG: %d, %d\n", level, loglevel);


//  stderr->write("%02d:%02d:%02d %s %s - %s\n", lt->hour, lt->min, lt->sec, log_strs[level], 
//                      function_name(backtrace()[-3][2]), m);
}

//!
void exception(string msg, object|array exception)
{
  msg = "An exception occurred: \n" +  msg + "\n%s";
  string e;

  if(objectp(exception))
    e = exception->describe();
  else e = describe_backtrace(exception);
  do_msg(CRITICAL, sprintf(msg, e));  
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

static string _sprintf(mixed ... args)
{
  return "logger()";//, appenders);
}
