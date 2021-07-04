


	

	--Variable para Obtener los campos del Pivot
	Declare @Compos varchar(2000)

	Declare @SQL  varchar(2000)
	Declare @Separacion varchar(100)
	

	Set @Separacion = ' || '


	--Conla Funcion STTUF Obtengo el listado de ITEMS de forma de Registros a un solo campo separado por [],[] ... 
	Select @Compos = 						 
	STUFF((Select @Separacion + DESCRIPCION  from GENERAL_PROCESOS   FOR XML PATH('')),1,2,'') +  + ' '
			
	
	
SELECT @Compos AS FLEXIBLE

UNION ALL 

SELECT @Compos AS SACOS 