



Declare @StringSQL varchar(max) 

--select TOP 1 @cad= '''E-02''' +','+ '''15-01-2018''' +','+ ''''+BASE_ID+'''' from VMFGPN.DBO. work_order WHERE BASE_ID='OPR-04265-18'
select TOP 1 @cad= '''E-01''' +','+ '''10-01-2018''' from VMFGPN.DBO. work_order WHERE BASE_ID='OPR-04265-18'

set @cad = 'execute GET_ORDER_RESOURCE ' + @cad 
set @cad = @cad

print  @cad 

EXECUTE SP_sqlexec  @cad
