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
{if:id:data->val}  we made the if! {endif:id}
{if:fa:!data->val}  hahaha {else:fa} hehehe {endif:fa}

{!capitalize:val}

</body>
</html>
