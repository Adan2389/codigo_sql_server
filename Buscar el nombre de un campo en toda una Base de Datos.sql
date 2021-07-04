

USE IQM_App
GO 

SELECT  sysobjects.name AS Tabla, 
	    syscolumns.name AS Campo,  
		systypes.name AS TipoDato, 
		syscolumns.LENGTH AS Tamanio

FROM sysobjects INNER JOIN   syscolumns ON sysobjects.id = syscolumns.id 
	INNER JOIN  systypes ON syscolumns.xtype = systypes.xtype
WHERE  sysobjects.xtype = 'U' 
       and (UPPER(syscolumns.name) like upper('%CUSTOME%'))
ORDER BY sysobjects.name, syscolumns.colid




