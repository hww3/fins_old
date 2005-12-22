
string simple_macro_capitalize(Fins.Template.TemplateData data, mapping|void args)
{
    return String.capitalize(data->get_data()[args->var]||"");
}

string simple_macro_flash(Fins.Template.TemplateData data, mapping|void args)
{
    return (data->get_flash()[args->var]||"");

}


