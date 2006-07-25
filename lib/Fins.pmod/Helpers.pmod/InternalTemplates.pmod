constant error_500 =
#"
<html>
<head>
<title>Error 500: <%$title%></title>
</head>
<body>
<h1><%$errorname%></h1>
An error occurred while processing your request:
<p>
<%$backtrace%>
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
