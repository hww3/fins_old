//! This module contains functions of general utility.

//!
string get_path_for_program(program p)
{
	string everythingelse;
	string s = Builtin->program_defined(p);
    
    sscanf(s, "%s:%s", s, everythingelse);
    return s;
}

//!
string get_path_for_module(object o)
{
	// obj->is_resolv_joinnode
	// obj->joined_modules[0]->dirname
	
	if(o->is_resolv_joinnode)
	{
		return o->joined_modules[0]->dirname;
	}
	else
	 return get_path_for_program(object_program(o));
}