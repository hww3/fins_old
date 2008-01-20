	int timeout;
	int cleanup_interval;
	
	static mapping(mixed:array) vals = ([]);
	
	static void create(int _timeout, void|int _cleanup_interval)
	{
	  timeout = _timeout;
	  cleanup_interval = _cleanup_interval || (_timeout * 2);
	  call_out(cleanup, cleanup_interval);
	}
	
	static mixed `[](mixed k)
	{
	  mixed q;
	
	  if(!has_index(vals, k)) return ([])[0];
	  
	  q = vals[k];
	
	  if(q[0] < time()) // have we overstayed our welcome?
	  {
	     m_delete(vals, k);
	     return ([])[0];
	  } 
	  else
	    return q[1];
	}
	
	static mixed `->(string k)
	{
		return `[](k);
	}
	
	static mixed `->=(string k, mixed v)
	{
		return `[]=(k, v);
	}
	
	static mixed `[]=(mixed k, mixed v)
	{
	  vals[k] = ({time() + timeout, v});
	  return v;
	}
	
	static mixed _m_delete(mixed k)
	{
	  mixed v = m_delete(vals, k);
	  if(v) return v[1];
	  else return ([])[0];
	}
	
	void cleanup()
	{
	  int ct = time();
	
	  foreach(vals; mixed k; mixed v)
	  {
		if(v[0] < ct)
		{
		  m_delete(vals, k);
		}
	  }
	  call_out(cleanup, cleanup_interval);
	}
