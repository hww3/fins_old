import Fins;
inherit FinsBase;

//!
Model.DataObjectInstance find_by_id(Request r, string type, int id)
{
  return Model.find_by_id(type, id);
}

//!
array(Model.DataObjectInstance) find(Request r, string type, mapping 
attrs, void|Model.Criteria criteria)
{
  return Model.find(type, attrs, criteria);
}

