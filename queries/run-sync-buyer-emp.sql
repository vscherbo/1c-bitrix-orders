SELECT 
  b.email, fn_bx_sync_buyer_emp(b.email)
--b.*
--, o."Дата"
from bx_order o, vwPersonalBuyer b
WHERE 
   o.bx_buyer_id = b.bx_buyer_id AND
   position('@' in b.email) > 0
ORDER BY b.bx_buyer_id
-- o."Дата" Asc
  