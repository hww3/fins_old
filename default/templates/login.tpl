<html>
<head>
    <link rel="STYLESHEET" type="text/css" href="/static/default.css" />
<title>Login</title>
</head>
<body>
{include:tagline.tpl}
{include:pagebegin.tpl}
   <h3>Login</h3>

   <p>
<form action="" method="post">
<input type="hidden" name="return_to" value="{return_to}"/>
Login: <input type="string" name="UserName" value="{UserName}"/><br/>
Password: <input type="password" name="Password"/>
<p/>
<input type="submit" name="action" value="Login"/>
<input type="submit" name="action" value="Cancel"/>
</form>

{if:preview:data->preview}
Preview:<p>
{preview}
{endif:preview}

{include:footer.tpl}
