<html>
<head>
<title>{test}</title>
</head>
{include:foo.tpl}
<body>
{foreach:loop}Here's a record: {val}, {loop:blah}<p>
{end:loop}
<p>wahoo!
<p>
{if:id:tesbla}  we made the if! {endif:id}
{if:fa:tefksd}  hahaha {else:fa} hehehe {endif:fa}

{!capitalize:val}

</body>
</html>
