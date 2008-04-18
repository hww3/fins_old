//! an implementation of a mapping that "forgets" entries after a certain time has elapsed

	int timeout;
	int cleanup_interval;
	
	static mapping(mixed:array) vals = ([]);

//! @param _timeout
//! specify the length of time (in seconds) an entry should be retained after it has
//! been added. the timeout interval is not sliding: that is, accessing an entry will 
//! not cause the timeout counter to be reset for the entry. setting an entry will cause
//! the timeout to be recalculated, though.
//!
//! @param _cleanup_interval	
//! specify how often the mapping should be examined for stale entries. 
//! by default the cleanup period will be twice the timeout. entries will
//! always be removed if accessed after their timeout period; this interval
//! is only used to remove entries which might not be accessed otherwise.
	static void create(int _timeout, void|int _cleanup_interval)
	{
	  timeout = _timeout;
	  cleanup_interval = _cleanup_interval || (_timeout * 2);
	  call_out(cleanup, cleanup_interval);
	}
	
//!
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

//!	
	static mixed `->(string k)
	{
		return `[](k);
	}

//!	
	static mixed `->=(string k, mixed v)
	{
		return `[]=(k, v);
	}

//!	
	static mixed `[]=(mixed k, mixed v)
	{
	  vals[k] = ({time() + timeout, v});
	  return v;
	}

//!	
	static mixed _m_delete(mixed k)
	{
	  mixed v = m_delete(vals, k);
	  if(v) return v[1];
	  else return ([])[0];
	}
	
//!
	static int _sizeof()
	{
		return sizeof(vals);
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
