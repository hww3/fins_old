  import Standards;

  Fins.Template.Template template;
  Fins.Template.TemplateData template_data;

  static Fins.Request request;  

  static int __rendered = 0;

//!
  static void create(Fins.Request|void r)
  {
    request = r;
    
    // this is where we handle the "passing" of flash from request
    // to response... it seems like a goofy place to do it,
    // but it ensures that it's not done until we have an event
    // to pass the flashes to...
    if(request && request->misc->session_variables && 
             request->misc->session_variables->__flash)
    {
       request->misc->flash = request->misc->session_variables->__flash || ([]);
       m_delete(request->misc->session_variables, "__flash");
    }

  }

  static mapping response = (["type": "text/html",
                              "error": 0,
                              "extra_heads": ([])
                              ]);

  static mapping cookies = ([ "__expiration__" : 0 ]);

  //!
  public void set_type(string mimetype)
  {
    response->type = mimetype;
  }

  //!
  public void|string get_type() {
    return response->type;
  }

  //!
  public int flash(string name, mixed data)
  {
    if(!request) return 0;

    if(!request->misc->session_variables->__flash)
      request->misc->session_variables->__flash = ([]);

    request->misc->session_variables->__flash[name] = data;

    return 1;
  }

  public void set_view(Fins.Template.View v)
  {
    set_template(v->template, v->data);	
  }

  //!
  public void set_template(Fins.Template.Template t, Fins.Template.TemplateData d)
  {

     template = t;
     template_data = d;
     if(!response->error) response->error = 200;
  }

  //!
  public void set_error(int error)
  {
     response->error = error;
  }
  
  //!
  public void set_header(string header, string value)
  {
     response->extra_heads[lower_case(header)] = value;
  }

  //!
  public void set_cookie(string name, string value, int expiration)
  {
    cookies[name] = value;
    // Take a punt and set the expiration to the lowest of the expiry values.
    if ((cookies["__expiration__"] == 0) || (expiration < cookies["__expiration__"]))
      cookies["__expiration__"] = expiration;
  }

  //!
  public void not_found(string filename)
  {
    object e = request->fins_app->view->get_view("internal:error_404");

    e->add("filename", filename);
    set_view(e);
    response->error = 404;
  }

  //!
  public void not_modified()
  {
    response->error = 304;
  }
  
  //!
  public void redirect(string|URI|function|Fins.FinsController to, mixed ... args)
  {
	string dest;
    response->error = 301;

    if(stringp(to))
      dest = to;
    else if(functionp(to) || (object_program(to) != Standards.URI))
    {
	  dest = request->fins_app->action_url(to);
    }
    else
    {
	   dest = (string)to;
    }

    if(args)
      dest = combine_path(dest, args*"/");

    response->extra_heads->location = dest;
  }

  //!
  public void redirect_temp(string|URI|function|Fins.FinsController to, mixed ... args)
  {
	string dest;
    response->error = 302;

    if(stringp(to))
      dest = to;
    else if(functionp(to) || (object_program(to) != Standards.URI))
    {
	  dest = request->fins_app->action_url(to);
    }
    else
    {
	   dest = (string)to;
    }

    if(args)
      dest = combine_path(dest, args*"/");


    response->extra_heads->location = dest;
  }


  //! using this method will clear any template set.
  public void set_data(string data, mixed ... args)
  {
    if(args && sizeof(args))
      response->data = sprintf(data, @args); 
    else  
      response->data = data;
    if(!response->error) response->error = 200;
    template = 0;
    response->file = 0;
  }

  //!
  public void set_file(Stdio.File file)
  {
    response->file = file;
    if(!response->error)
      response->error = 200;
    response->data = 0;
  }

  //! 
  public void|Stdio.File get_file() {
    return response->file;
  }

  public void render()
  {
     if(template)
     {
       mapping f = ([]);
       if(request && request->misc->flash)
         f+=(request->misc->flash);
       if(request && request->misc->session_variables->__flash)
         f+=(request->misc->session_variables->__flash);
       template_data->set_flash(f);

        response->data = template->render(template_data);
        response["extra_heads"]["content-type"] = template->get_type();
        response->file = 0;
        __rendered = 1;
     }

  }

  //!
  public string get_data()
  {
    if(!__rendered) render();
    return response->data;
  }

  //!
  public string|array get_header(string headername)
  {
    return response->extra_heads[headername];
  }

  //!
  public mapping get_response()
  {
     if(!__rendered) render();

     if(!response->error) return 0;
     if (sizeof(cookies) > 1) 
     {
       array _cookies = ({});
       foreach(indices(cookies), string name)
	 if (name != "__expiration__")
	   _cookies += ({ sprintf("%s=%s;", Protocols.HTTP.http_encode_cookie(name), Protocols.HTTP.http_encode_cookie(cookies[name])) });
        _cookies += ({ "path=/;" });
	if (cookies["__expiration__"])
	  ({ sprintf("expires=%s", Protocols.HTTP.Server.http_date(cookies["__expiration__"])) });
       response->extra_heads["set-cookie"] = _cookies * " ";
     }

    return response;
  }
