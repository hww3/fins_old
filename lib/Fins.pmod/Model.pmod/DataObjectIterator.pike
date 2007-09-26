//	inherit Iterator;
	
	int current_index = 0;
        object dto;
        array order;

int _sizeof()
{
  return sizeof(order);
}

   static void create(object o)
  {
    dto = o;
    order = o->master_object->field_order;
  }

	int(0..1) first()
	{
	  current_index = 0;	
          return sizeof(order)?1:0;
	}
	
	mixed index()
	{
		if(!sizeof(order) || sizeof(order) <= (current_index))
			return UNDEFINED;
		else return order[current_index]->name;
	}
	
	int next()
	{
		if(sizeof(order) <= (current_index +1))
		  return 0;
		else current_index ++;
		
		return 1;
		
	}
	
	mixed value()
	{
mixed x = dto[order[current_index]->name];
return x;
	}
	
static int `!()
{
  if(current_index < sizeof(order)) return 0;
  else return 1;
}	
	static Iterator `+=(int steps)
	{
		current_index += steps;
		return this;
	}

