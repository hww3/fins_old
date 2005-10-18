  Fins.Template.Template template;
  Fins.Template.TemplateData template_data;
  
  static mapping response = (["type": "text/html",
                              "error": 200,
                              "extra_heads": ([])
                              ]);

  //!
  public void set_type(string mimetype)
  {
    response->type = mimetype;
  }

  //!
  public void set_template(Fins.Template.Template t, Fins.Template.TemplateData d)
  {
     template = t;
     template_data = d;
  }
  //!
  public void set_error(int error)
  {
     response->error = error;
  }
  
  //!
  public void set_header(string header, string value)
  {
     response->extra_heads[header] = value;
  }

  //!
  public void set_cookie(string name, string value, int expiration)
  {
     response->extra_heads["set-cookie"] = 
                Protocols.HTTP.http_encode_cookie(name)+
                "="+Protocols.HTTP.http_encode_cookie( value )+
                "; expires="+Protocols.HTTP.Server.http_date(expiration)+"; path=/";
  }

  //!
  public void not_found(string filename)
  {
    response->error = 404;
    response->data = "<h1>404: File Not Found</h1>\n"
                     "The file " + filename + " was not found.";
  }
  
  //!
  public void redirect(string to)
  {
    response->error = 302;
    response->extra_heads->location = to;
  }

  //!
  public void set_data(string data, mixed ... args)
  {
    if(args)
      response->data = sprintf(data, @args); 
    else  
      response->data = data;
  }

  //!
  public void set_file(Stdio.File file)
  {
    response->file = file;
    response->data = 0;
  }

  //!
  public mapping get_response()
  {
     if(template)
     {
        response->data = template->render(template_data);
        response->data["extra_heads"]["content-type"] = template->get_type();
        response->file = 0;
     }
    return response;
  }
