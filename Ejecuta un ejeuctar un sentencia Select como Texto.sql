




---PERIMITE EJECUTAR UNA SENTENCIA SELECT COMO TEXTO 

SELECT * FROM OPENQUERY (ION, 'SELECT * FROM VMFGPN.DBO.PART')

--PARA IDENTIFICAR EL IDENTIFICACION DEL SERVIDOR 
SELECT * FROM master.sys.servers

--PERMITE ACTIVAR "DATA ACCES" QUE ES LA CONFIGURACION QUE PERMITE EJECUTAR LAS SENTENCIAS SELECT COMO TEXTOS 
exec sp_serveroption 'ION', 'data access', 'true'