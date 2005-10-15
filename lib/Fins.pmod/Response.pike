  Fins.Template.Template template;
  
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
  public void set_template(Fins.Template.Template t)
  {
     template = t;
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
        response->data = template->render();
        response->file = 0;
     }
    return response;
  }
