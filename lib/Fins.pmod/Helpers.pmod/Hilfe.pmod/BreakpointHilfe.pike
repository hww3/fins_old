import Fins;
import Tools.Logging;

class BreakpointHilfe
{
  inherit Tools.Hilfe.GenericAsyncHilfe;

  Stdio.File client;
  object app;
  mapping request_state;
  object lock;
  array backtrace;

  void print_version()
  {
  }

  class CommandGo
  {
    inherit Tools.Hilfe.Command;
    string help(string what) { return "Resume request."; }

    void exec(Tools.Hilfe.Evaluator e, string line, array(string) words,
            array(string) tokens) {
    e->safe_write("Resuming.\n");
    
    destruct(e);
    }
  }

  class CommandBackTrace
  {
    inherit Tools.Hilfe.Command;
    string help(string what) { return "Display a backtrace that got us here."; }

    void exec(Tools.Hilfe.Evaluator e, string line, array(string) words,
            array(string) tokens) {
    e->safe_write(describe_backtrace(e->backtrace[1..]));
    }
    
  }

  void read_callback(mixed id, string s)
  {
    s = replace(s, "\r\n", "\n");
    inbuffer+=s;
    if(has_suffix(inbuffer, "\n")) inbuffer = inbuffer[0.. sizeof(inbuffer)-2];
    foreach(inbuffer/"\n",string s)
    {
      inbuffer = inbuffer[sizeof(s)+1..];
      add_input_line(s);
      write(state->finishedp() ? "> " : ">> ");
    }
  }



  static void create(Stdio.File client, object app, mapping state, string desc, array bt)
  {
    this->app = app;
    this->request_state = state;
    this->client = client;
    this->backtrace = bt;

    client->write("Breakpoint on " + desc + "\n");
    ::create(client, client);

    foreach(state; string h; mixed v)
    { 
      variables[h] = v;
      types[h] = sprintf("%t", v);

    }

    m_delete(commands, "exit");
    m_delete(commands, "quit");
    commands->go = CommandGo();
    commands->bt = CommandBackTrace();
    commands->backtrace = commands->bt;
  }

static void destroy()
{
  object key = app->bp_lock->lock();
  app->breakpoint_cond->signal();
  key = 0;
}

}

