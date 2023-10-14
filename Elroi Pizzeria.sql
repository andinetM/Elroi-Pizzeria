/* Queries and views for Elroi's Pizzeria */


--- ORDERs ---
Create view Orders_data as 
SELECT
	o.order_id,
	i.item_price,
	o.quantity,
	i.item_cat,
	i.item_name,
	o.created_at,
	a.delivery_address1,
	a.delivery_address2,
	a.delivery_city,
	a.delivery_zipcode,
	o.delivery 
FROM
	orders o
	LEFT JOIN item i ON o.item_id = i.item_id
	LEFT JOIN address a ON o.add_id = a.add_id
---------------------------------------------------------------------------------------------------------------------------------------

---Inventory Managment ---

/* This will tell us how much inventory we are using and 
also identify inventory that needs to be reordered. inorder to achieve that
we need to use aggregate function, Join, subquery functions */
-----------------------------------------------------------------------------------------------------------
/*Creating a view inorder to use it to get
the percentge of stock remaining per ingrident also to get the list of ingredients 
to re order based on the remaining inventory */

Create view stock1 as
Select 
   x1.item_id,
   x1.item_name,
   x1.ing_id,
   x1.ing_name,
   x1.ing_weight,
   x1.ing_price,
   x1.order_quantity,
   x1.recipe_quantity,
   (x1.order_quantity)*(x1.recipe_quantity) as ordered_weight,
   (x1.ing_price/ing_weight) as unit_price,
   (x1.order_quantity)*(x1.recipe_quantity)*(x1.ing_price/ing_weight) as ingredient_cost

from
(Select 
   o.item_id,
   i.sku,
   i.item_name,
   r.ing_id,
   r.recipe_id,
   ing.ing_name,
   r.quantity as recipe_quantity,
   sum(o.quantity) as order_quantity,
   ing.ing_weight,
   ing.ing_price
from 
    orders o
    left join item i on o.item_id = i.item_id
	left join recipe r on i.sku = r.recipe_id
	left join ingredient ing on ing.ing_id = r.ing_id
group by 
     o.item_id, i.sku, i.item_name,
	  r.recipe_id, r.quantity, ing.ing_name, ing.ing_weight,
      ing.ing_price,r.ing_id) x1


-----------------------------------------------------------------------------------------


Create view stock2 as
SELECT 
  x2.ing_name,
  x2.ordered_weight,
  CAST(ing.ing_weight AS INT) * CAST(inv.quantity AS INT) as total_inventory_weight,
  CAST(ing.ing_weight AS INT) * CAST(inv.quantity AS INT)-x2.ordered_weight as remainig_weight
FROM (
  SELECT
    ing_id,
    ing_name,
    SUM(ordered_weight) as ordered_weight
  FROM
    stock1
  GROUP BY 
    ing_name, ing_id
) x2
LEFT JOIN inventory inv ON inv.item_id = x2.ing_id
LEFT JOIN ingredient ing ON ing.ing_id = x2.ing_id

-----------------------------------------------------------------------------------------------
---- STAFF Managment -----

/* inorder to create this we need the rota, stafdf and shift table. we will
be using Join and datediff function inorder to get the output we are looking for */

Create view Staff_Info as 
SELECT
   r.date,
   s.first_name,
   s.last_name,
   s.hourly_rate,
/* we use CONVERT with the style code 108 to convert the datetime 
   values to a string in the format "hh:mi */
   CONVERT(VARCHAR(5), sh.start_time, 108) as start_time,
   CONVERT(VARCHAR(5), sh.end_time, 108) as end_time,
   DATEDIFF(MINUTE, sh.start_time, sh.end_time) / 60.0 as hours_in_shift,
   (DATEDIFF(MINUTE, sh.start_time, sh.end_time) / 60.0) * s.hourly_rate as staff_cost
FROM 
   rota r
   LEFT JOIN staff s ON r.staff_id = s.staff_id
   LEFT JOIN shift sh ON r.shift_id = sh.shift_id

