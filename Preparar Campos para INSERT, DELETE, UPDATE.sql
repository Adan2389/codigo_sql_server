

	

	

	--Variable para Obtener los campos del Pivot
	Declare @Compos varchar(2000)
	Declare @Tabla varchar(100)
	Declare @SQL  varchar(2000)
	Declare @Separacion varchar(100)
	
	
	Set @Tabla = 'DET_PRODUCCION'
	Set @Separacion = ', :prm'
	
	

	--Conla Funcion STTUF Obtengo el listado de ITEMS de forma de Registros a un solo campo separado por [],[] ... 
	Select @Compos = 						 
	STUFF((Select @Separacion +  SC.NAME FROM sys.objects SO INNER JOIN sys.columns SC  ON SO.OBJECT_ID = SC.OBJECT_ID 
								   WHERE SO.TYPE = 'u' and SO.NAME =@Tabla
								   FOR XML PATH('')),1,2,'') +  + ' '
			
	
	SET @SQL =  'INSERT INTO ' + @Tabla + 'VALUES (' + @Compos + ' )'	
	PRINT @SQL
			
		
		
								 
