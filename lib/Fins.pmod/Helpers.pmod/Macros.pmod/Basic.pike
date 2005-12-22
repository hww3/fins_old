inherit .Base;

string simple_macro_capitalize(Fins.Template.TemplateData data, mapping|void args)
{
    return String.capitalize(get_var_value(args->var, data->get_data())||"");
}

string simple_macro_flash(Fins.Template.TemplateData data, mapping|void args)
{
    return (get_var_value(args->var, data->get_flash())||"");

}

string simple_macro_sizeof(Fins.Template.TemplateData data, mapping|void args)
{
    return (string)(sizeof(get_var_value(args->var, data->get_data())||({})));

}

