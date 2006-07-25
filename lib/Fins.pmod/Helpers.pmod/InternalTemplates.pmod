constant error_500 =
#"
<html>
<head>
<title>Error 500: <%$error_type%></title>
</head>
<body>
<h1><%$message%></h1>
An error occurred while processing your request:
<p>
<%$backtrace%>
</body>
</html>
";

constant error_template = 
#"
<html>
<head>
<title>Fins: Template Error</title>
</head>
<body>
<h1>Fins: Template Error</h1>
An error occured while processing a template:
<p>
<%$message%>
</body>
</html>

";

constant index = 
#"
<html>
<head>
<title>Welcome to Fins!</title>
</head>
<body>
Welcome to the Fins MVC Framework!
<p>
This is application <b><%$appname%></b>.<p>
This is the method <b><%$method%></b> in controller 
<b><%$controller%></b>.
<p>
Details of the request are:
<p>
<PRE>
<%$request%>
</PRE>
</body>
</html>
";
