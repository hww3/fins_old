  import Standards;

  Fins.Template.Template template;
  Fins.Template.TemplateData template_data;

  static Fins.Request request;  
  static int low_response = 0;
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
			      "_type": "text/html",
                              "error": 0,
                              "extra_heads": ([])
                              ]);

  static mapping cookies = ([ "__expiration__" : 0 ]);

  //!
  public void set_type(string mimetype)
  {
    response->_type = mimetype;
    if(response->_charset) response->type = response->_type + 
      "; charset=" + response->_charset;
    else response->type = response->_type;
  }
 
  //!
  public void set_charset(string charset)
  {
    response->_charset = charset;
    if(response->_charset) response->type = response->_type + 
      "; charset=" + response->_charset;
    else response->type = response->_type;
  }

  //!
  public void|string get_type() {
    return response->_type;
  }

  //!
  public void|string get_charset() {
    return response->_charset;
  }

  //! when only one argument is provided, name is presumed to be "msg".
  public int flash(string name, mixed|void data)
  {
    if(!request) return 0;

    if(!data) { data = name; name = "msg"; }

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
    object e = request->fins_app->view->low_get_view(Fins.Template.Simple, "internal:error_404");

    e->add("filename", filename);
    set_view(e);
    response->error = 404;
  }

  //!
  public void not_modified()
  {
    response->error = 304;
  }

  //! generate our "best guess" url based on the request.
  public Standards.URI divine_url(Fins.Request req)
  {
    string host, prot;

    prot = "http";

    // are we Caudium/Roxen?
    if(req->conf)
      return Standards.URI(req->conf->query("MyWorldLocation"));

    if(req["request_headers"]["host"])
    {
      host = req["request_headers"]["host"];
    }
    else
    {
      string port = "";
      if(req->server_port)
      {
	int p = req->server_port->portno;
        if(p != 80) port = ":" + p;
        if(object_program(req->server_port->port) == Protocols.HTTP.Server.SSLPort)
          prot = "https";
      }
      host = gethostname() + port;
    }

    return Standards.URI(prot + "://" + host + "/");
  }

  public string get_redirect_url(string|URI|function|Fins.FinsController to, array|void args, mapping|void vars)
  {
    string dest;
    if(arrayp(to)) to = to[0];
    if(functionp(to) || (objectp(to) && (object_program(to) != Standards.URI)))
    {
	  dest = request->fins_app->url_for_action(to, args, vars);
          dest = absolutify_url(dest);
    }
    else
    {
      if(stringp(to))
      {
        dest = absolutify_url(to, args);
      }
      else
      {
        if(args && sizeof(args))
          to = Standards.URI(combine_path(to->path, args*"/"), to);
        if(to)
          dest = (string)to;
      }


      if(vars)
        dest = request->fins_app->add_variables_to_path(dest, vars);
    }
    return dest;
  }

  string absolutify_url(string to, array|void args)
  {
    if(to[0] == '/')
    {
      object u;
      u = request->fins_app->get_my_url();
      if(!u)
      {
        u = divine_url(request);
      }
      u->path = combine_path(u->path, to);
      if(args && sizeof(args))
        u = Standards.URI(combine_path(u->path, args*"/"), to);
        to = (string)u;
    }

    return to;
  }

  //! perform a redirection
  //!
  //! in the event a relative url is passed as the to argument, 
  //! this method will attempt to convert it to an absolute url
  //! using the following algorithm:
  //!
  //! - if using Caudium or Roxen as the host container, MyWorldLocation
  //!    from the current virtual server will be used
  //! - if the web->url attribute has been provided in the application
  //!    configuration file, this url will be used as the base.
  //! - if the request is HTTP/1.1, the current host header will be
  //!    used
  //! - if FinServe is used, the protocol will be determined based on
  //!    the protocol of the responding port.
  //! - if all else fails, a relative url will be passed (not complying 
  //!    with the HTTP specification).
  //!
  //! @param to
  //!   a string, Standards.URI object or an action (event or controller)
  //!   that will be redirected to
  //!
  //! @param args
  //!    an optional array of arguments that will be appended to the request url
  //!
  public void redirect(string|URI|function|Fins.FinsController to, array|void args, mapping|void vars)
  {
	string dest;
    response->error = 301;

    dest = get_redirect_url(to, args, vars);

    response->extra_heads->location = dest;
  }

  //! perform a temporary redirection
  //!
  //!  see @[redirect] for details of the technique used to generate
  //!   absolute URLs.
  //! 
  //! @param to
  //!   a string, Standards.URI object or an action (event or controller)
  //!   that will be redirected to
  //!
  //! @param args
  //!    an optional array of arguments that will be appended to the request url
  //!
  public void redirect_temp(string|URI|function|Fins.FinsController to, array|void args, mapping|void vars)
  {
	string dest;
    response->error = 302;

    dest = get_redirect_url(to, args, vars);
    response->extra_heads->location = dest;
  }


  //! sets the response value for this request
  //!
  //! if an HTTP response code has been set, this method will not alter it,
  //! if one has not been set, this method will default the response code to 200 (Response OK).
  //!
  //! using this method will clear any template set.
  //! 
  //! @param args
  //!   if provided, data will be assumed to be a @[sprintf]() format string, and will be used
  //!   to format @[args].
  public void set_data(string|String.Buffer data, mixed ... args)
  {
    if(objectp(data)) data = (string)data;
    if(args && sizeof(args))
      response->data = sprintf(data, @args); 
    else  
      response->data = data;
    if(!response->error) response->error = 200;
    template = 0;
    response->file = 0;
  }

  //! sets the response value for this request
  //!
  //! if an HTTP response code has been set, this method will not alter it,
  //! if one has not been set, this method will default the response code to 200 (Response OK).
  //!
  //! using this method will clear any template set.
  //! 
  public void set_file(Stdio.File file)
  {
    response->file = file;
    if(!response->error)
      response->error = 200;
    response->data = 0;
    template = 0;
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

       template_data->add("session", request->misc->session_variables);
       template_data->set_flash(f);
       template_data->set_request(request);

        response->data = template->render(template_data);
        if(stringp(response->data) && String.width(response->data) > 8)
        {
			// TODO: we need to figure out how to encode things. Is utf8 sufficient?
			response->data = string_to_utf8(response->data);
            response["extra_heads"]["content-type"] = template->get_type() + "; charset=utf-8";
		}
		else
//            response["extra_heads"]["content-type"] = template->get_type() + "; charset=utf-8";
          response["extra_heads"]["content-type"] = template->get_type();
        response->file = 0;
        __rendered = 1;
     }

  }

  public void set_low_response(mapping resp)
  {
    low_response = 1;
    response = resp;
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
     if(low_response) return response;
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
 
    response->request = request;

    return response;
  }
