inherit Tools.Standalone.extract_locale;

void update_xml_sourcefiles(array filelist) {
  // Extracts strings from html/xml files in filelist
  // Updates ids, r_ids, id_xml_order with ids and strings
  // If new ids, updates the sourcefile or a copy
  foreach(filelist, string filename) {
    Stdio.File file = Stdio.FILE();
    if(!file->open(filename, "r")) {
      werror("* Error: Could not open sourcefile %s.\n", filename);
      exit(1);
    }
    write("Reading %s", filename);
    string line = file->gets();
    string data = file->read();
    file->close();
    if(!data && !line)
      continue;

    // Check encoding
    if(!line)
      line = data;
    string encoding;
    sscanf(line, "%*sencoding=\"%s\"", encoding);
    if(encoding && encoding!="") {
      function decode = get_decoder(encoding);
      if(decode && catch( data = decode(data) )) {
	werror("\n* Error: unable to decode from %O in %O\n",
	       encoding, filename);
	exit(1);
      }
    }
    else if(line!=data)
      data = line+"\n"+data;

    write(", parsing...");
    int new = 0;
    int ignoretag = 0;
    int no_of_ids = 0;
    mapping m = copy_value(args);
    Parser.HTML xml_parser = Parser.HTML();
    xml_parser->case_insensitive_tag(1);
    xml_parser->add_quote_tag("!--", lambda() {return 0;}, "--");
    xml_parser->add_quote_tag("%", 
             lambda(object p, string c, mixed ... e)
             {
//werror("have a psp tag: %O\n", c);
               if(c[0] == '@') // we have a declaration.
               {
                 c = String.trim_whites(c[1..]);
                 string cmd;
                 sscanf(c, "%s %s", cmd, c);
                 if(cmd == "project")
                 {
                   string project;
                   if(sscanf(c, "%*sname=\"%s\"%*s", project) != 3)
                   {
                     exit(1, "Project declaration must include project name.\n");
                   }
                   if(m->project && (project != m->project))
                   {
                     ignoretag = 1;
                   }
                   else
                   {
                     ignoretag = 0;
                   }
                 } 
               }
               else if(c[0]!='!') // ok, we have a regular template construct.
               {
                 c = String.trim_whites(c[0..]);
                 string cmd;
//werror("cmd: %O\n", c);
                 sscanf(c, "%s %s", cmd, c);
                 if(cmd == "LOCALE")
                 {
                   if(ignoretag) 
                   {
                     werror("skipping tag as it's out of our project.\n");
                     return 0;
                   }
//werror("have a LOCALE command\n");
		   foreach((<"id", "string">); string k;)
                   {
                     string before,after,v;
                     if(sscanf(c, "%s" + k + "=\"%s\"%s", before, v, after) == 3)
                     {
                       m[k] = v;
                       c = before + after;
                     }
                   }
//werror("m: %O\n", m);
                   if(!m->string) { werror("malformed LOCALE string.\n"); return 0; }
		      string|int id = m->id;
		      if((int)id) id = (int)id;
		      string fstr = m["string"];
		      int updated = 0;
		      if (String.trim_whites(fstr)=="")
			return 0;         // No need to store empty strings
		      no_of_ids++;
		      if(!id || id=="") {
			if (r_ids[fstr])
			  id = r_ids[fstr];   // Re-use old id with same string
			else
			  id = make_id();     // New string --> Get new id
			// Mark that we have a new id here
//werror("new localizaion\n");
			updated = ++new;
		      } else {
			// Verify old id
			if(!ids[id] || (ids[id] && !ids[id]->origin)) {
			  // Remove preread string in r_ids, might be updated
			  m_delete(r_ids, ids[id]);
			} else {
			  if(ids[id] && ids[id]->original!=fstr) {
			    werror("\n* Error: inconsistant use of id.\n");
			    werror("    In file:%{ %s%}\n", ids[id]->origin);
			    werror("     id %O -> string %O\n",
				   id, ids[id]->original);
			    werror("    In file: %s\n", filename);
			    werror("     id %O -> string %O\n", id, fstr);
			    exit(1);
			  }
			}
			if(r_ids[fstr] && r_ids[fstr]!=id &&
			   ids[r_ids[fstr]]->origin)
			  werror("\n* Warning: %O has id %O in%{ %s%}, "
				 "id %O in %s", fstr, r_ids[fstr],
				 ids[r_ids[fstr]]->origin, id, filename);
		      }
		      if(!has_value(id_xml_order, id))
			// Id not in xml-structure, add to list
			id_xml_order += ({ id });
		      if(!ids[id])
			ids[id] = ([]);
		      ids[id]->original = fstr;         // Store id:text
		      ids[id]->origin += ({filename});  // Add  origin
		      if(String.trim_whites(fstr)!="")
			r_ids[fstr] = id;               // Store text:id
		      if(updated) {
			string ret="<%LOCALE id=\""+id+"\"";
/*			foreach(indices(m)-({"id"}), string param)
			  ret+=" "+param+"=\""+m[param]+"\"";
*/
		        return ({ ret+" string=\""+m->string+"\"%>" });
		      }
		      // Not updated, do not change
		      return 0;
                 }
               }
               return 0;
             },
        "%");


    xml_parser->feed(data)->finish();

    // Done parsing, rebuild sourcefile if needed
    write(" (%d localization%s)\n", no_of_ids, no_of_ids==1?"":"s");
    if(!new) {
      continue;
    }
    data = xml_parser->read();
    if(encoding && encoding!="") {
      function encode = get_encoder(encoding);
      if(encode && catch( data = encode(data) )) {
	werror("\n* Error: unable to encode data in %O\n", encoding);
	exit(1);
      }
    }

    if(!args->nocopy)
      filename += ".new"; // Create new file instead of overwriting
    write("-> Writing %s (%d new)", filename, new);
    if(!file->open(filename, "cw")) {
      werror("\n* Error: Could not open %s for writing\n", filename);
      exit(1);
    }

    file->write( data );
    file->truncate( file->tell() );
    file->close();
    write("\n");
  }
}



// ------------------------ The main program --------------------------

void create(array(string) argv) {
  // Parse arguments
  argv=argv[..sizeof(argv)-1];
  for(int i=0; i<sizeof(argv); i++) {
    if(argv[i][0]!='-') {
      files += ({argv[i]});
      continue;
    }
    string key, val = "";
    if(sscanf(argv[i], "--%s", key)) {
      sscanf(key, "%s=%s", key, val);
      args[key] = val;
      continue;
    }
    args[argv[i][1..]] = 1;
  }
}

int run()
{
  // Get name of outfile (something like project_eng.xml)
// werror("args: %O\n", args);
  string xml_name=args->out;

  // Read configfile
  string configname = args->config;
  if(!configname && args->project)
    configname = args->project+".xml";
  string filename = parse_config(configname);
  if(!xml_name || xml_name=="")
    if(filename!="")
      xml_name = filename;
    else if(args->xmlpath && args->baselang)
      xml_name = replace(args->xmlpath, "%L", args->baselang);

  if( (!(xml_name && args->sync && args->xmlpath && args->baselang)) &&
      (!sizeof(files) || args->help) ) {
    sscanf("$Revision: 1.18 $", "$"+"Revision: %s $", string v);
    werror("\n  Fins/Pike Locale Extractor Utility "+v+"\n\n");
    werror("  Syntax: pike -x fins extract_locale [arguments] infile(s)\n\n");
    werror("  Arguments: --project=name  default: first found in infile\n");
    werror("             --config=file   default: [project].xml\n");
    werror("             --out=file      default: [project]_eng.xml\n");
    werror("             --nocopy        update infile instead of infile.new\n");
    werror("             --notime        don't include dump time in xml files\n");
    werror("             --wipe          remove unused ids from xml\n");
    werror("             --sync          synchronize all locale projects\n");
    werror("             --encoding=enc  default: ISO-8859-1\n");
    werror("             --verbose       more informative text in xml\n");
    werror("\n");
    return 1;
  }

  // Try to read and parse xml-file
  mapping xml_data;
  xml_data = parse_xml_file(xml_name, args->baselang);
  write("\n");

  // Read, parse and (if necessary) update the sourcefiles
  object R = Regexp("(\.pike|\.pmod)$");
  foreach(files, string filename)
    if(R->match(filename))
      update_pike_sourcefiles( ({ filename }) );
    else
      update_xml_sourcefiles( ({ filename }) );

  // Save all strings to outfile xml
//werror("args: %O\n", args);
  if(!xml_name)
    if(args->project && args->project!="")
      xml_name = args->project+"_eng.xml";
    else {
      xml_name = files[0];
      sscanf(xml_name, "%s.pike", xml_name);
      xml_name += "_eng.xml";
    }
  write("\n");
  write_xml_file( xml_name, args->baselang,
		  args->encoding || xml_data->encoding, xml_data->data);

  // Synchronize xmls in other languages
  if (args->sync) {
    write("\n");
    mapping base_ids = ids;
    array base_order = id_xml_order;
    foreach(languagefiles(args->xmlpath, args->baselang), mapping file) {
      ids = ([]);
      string enc = parse_xml_file(file->name, file->lang)->encoding;
      id_xml_order = base_order;
      mapping old_ids = ids;
      ids = base_ids;
      write_xml_file(file->name, file->lang,
		     args->encoding || enc, xml_data->data, old_ids);
    }
  }

  write("\n");
  return 0;
}
