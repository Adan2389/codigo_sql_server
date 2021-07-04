
	
------ Envia un correo electronico como un  mensaje de texto plano 
	EXECUTE msdb.dbo.sp_send_dbmail 
	@profile_name = 'MAIL_SQL_SERVER', 
	@recipients = 'adan.hernandez@plastinova.hn', 
	@body = 'Este es un mensaje enviadeo desde el Sistema Gestor de Base de datos SQL SERVER 2O12', 
	@subject = 'Marcaje [BIOFACE]'



-----Envia un correo electronico en formato HTML, ejecutando una consulta y formateandola con 
----como una table HTML
	
	BEGIN TRY
		DECLARE @tableHTML  NVARCHAR(MAX)
		SET @tableHTML =
		N'<html>'+
		N'<head>'+
		N'<style type="text/css">table{border: solid 1px;border-collapse:collapse;}td{text-align:"center";}.izq{text-align:left}th{text-align:"center";  background:"#808080"; color:"#ffffff";}</style>' +
		N'</head>'+
		N'<body>'+
		N'<h3><center><u>REPORTE DE MONITOREO<u></center></h3>'+
		N'<table border =''1'' align = "center">' +
		N'<tr><th>USUARIO</th>'+
		N'<th>CODIGO APLICACION</th>'+
		N'<th>ACCION</th>'+
		N'<th>VALIDADO</th></tr>'+
		cast (
		(select TOP 100 td = USUARIO, '',
				 td = CODIGO_API, '',
				 td = ACCION, '',
				 td = ACCESO_VALIDADO, ''
		from    GENERAL_LOG_LOGIN
		for xml raw('tr'), elements
		) as nvarchar (max)
		) + N'</table>'+
		N'<body>'+
		N'<html>'

		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'MAIL_SQL_SERVER', 
			@recipients='fddsfsd',  
			@subject = 'Listado de Accesos',  
			@body = @tableHTML,  
			@body_format = 'HTML'

		PRINT 'EXITOSO'
	END TRY
	BEGIN CATCH
		PRINT 'ERROR'
	END CATCH

