<html>
<head>
<title>{test}</title>
</head>
{include:foo.tpl}
<body>
{foreach:loop}Here's a record: {val}, {loop:blah}<p>
{end:loop}
</body>
</html>
