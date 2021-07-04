

	Declare @StringSQL varchar(max)

	----------------------------------------------------------------EXTRUSION-------------------------------------------------------------------
	IF (LEFT(@Resource,1)='E')
	BEGIN
		Set @StringSQL ='
			SELECT *,
					(SELECT NAME FROM VMFGPN.DBO.CUSTOMER as c where ID =C1.CUSTOMER_ID )AS CLIENTE
			FROM (

				SELECT a.BASE_ID AS WORK_ORDER, CONVERT(VARCHAR(10),CREATE_DATE, 103) AS CREADA,  PART_ID, 
						(SELECT DESCRIPTION FROM VMFGPN.DBO.PART WHERE ID=a.PART_ID)AS DESCRIPTION,
						(SELECT STRING_VAL FROM VMFGPN.DBO.user_def_fields AS ud WHERE ud.DOCUMENT_ID=a.PART_ID AND ID='+'''00038'''+')AS CUSTOMER_ID,
						 CONVERT(VARCHAR(10),DESIRED_RLS_DATE,103)AS F_ENTRADA,CONVERT(VARCHAR(10),DESIRED_WANT_DATE,103)AS F_REQUERIDA, 
						DESIRED_QTY as LIBRAS, b.RUN AS LBSXHR, b.RUN_HRS AS HRS, b.SETUP_HRS AS HRS_SETEO, (b.SETUP_HRS + RUN_HRS) AS TOT_HRS, 
						 a.STATUS, a.USER_1 AS ANCHO, a.USER_2 AS TIPO, a.USER_3 AS ESPESOR, a.USER_4 as PESO_MT
		   
				FROM  
				VMFGPN.DBO.WORK_ORDER AS a
				inner join VMFGPN.DBO.OPERATION AS b on (a.BASE_ID=B.WORKORDER_BASE_ID)	
				WHERE a.TYPE= '+'''W'''+' AND a.STATUS IN ('+'''U'''+', '+'''R'''+') AND NOT  LEFT(a.PART_ID,2)='+'''PT'''+' AND b.RUN > 0  AND b.RESOURCE_ID='+''''+ @Resource+''''+'
				AND a.CREATE_DATE >= '+ ''''+CONVERT(varchar(10), @FechaInicial,103) +''''+'
			)AS C1
			ORDER BY F_REQUERIDA, WORK_ORDER ASC'
	END
	
	----------------------------------------------------------------IMPRENTA-------------------------------------------------------------------
	IF (LEFT(@Resource,1)='I')
	BEGIN
		Set @StringSQL ='
			SELECT *,
					(SELECT NAME FROM VMFGPN.DBO.CUSTOMER as c where ID =C1.CUSTOMER_ID )AS CLIENTE
			FROM (

				SELECT a.BASE_ID AS WORK_ORDER, CONVERT(VARCHAR(10),CREATE_DATE, 103) AS CREADA,  PART_ID, 
						(SELECT DESCRIPTION FROM VMFGPN.DBO.PART WHERE ID=a.PART_ID)AS DESCRIPTION,
						(SELECT STRING_VAL FROM VMFGPN.DBO.user_def_fields AS ud WHERE ud.DOCUMENT_ID=a.PART_ID AND ID='+'''00038'''+')AS CUSTOMER_ID,
						 CONVERT(VARCHAR(10),DESIRED_RLS_DATE,103)AS F_ENTRADA,CONVERT(VARCHAR(10),DESIRED_WANT_DATE,103)AS F_REQUERIDA, 
						DESIRED_QTY as LIBRAS, b.RUN AS LBSXHR, b.RUN_HRS AS HRS, b.SETUP_HRS AS HRS_SETEO, (b.SETUP_HRS + RUN_HRS) AS TOT_HRS, 
						 a.STATUS, a.USER_1 AS ANCHO, a.USER_2 AS TIPO, a.USER_3 AS ESPESOR,
						 (SELECT TOP 1 ISNULL(USER_1,'+'''N/A'''+')  FROM VMFGPN.DBO.OPERATION WHERE WORKORDER_BASE_ID=a.BASE_ID )AS RODILLO,
						 (SELECT Count(PART_ID)  FROM VMFGPN.DBO.REQUIREMENT WHERE WORKORDER_BASE_ID=a.BASE_ID  
						  and User_3 is not null)AS COLORES,
						  a.USER_4 as PESO_MT					 
		   
				FROM  
				VMFGPN.DBO.WORK_ORDER AS a
				inner join VMFGPN.DBO.OPERATION AS b on (a.BASE_ID=B.WORKORDER_BASE_ID)	
				WHERE a.TYPE= '+'''W'''+' AND a.STATUS IN ('+'''U'''+', '+'''R'''+') AND NOT  LEFT(a.PART_ID,2)='+'''PT'''+' AND b.RUN > 0  AND b.RESOURCE_ID='+''''+ @Resource+''''+'
				AND a.CREATE_DATE >= '+ ''''+CONVERT(varchar(10), @FechaInicial,103) +''''+'
			)AS C1
			ORDER BY F_REQUERIDA, WORK_ORDER ASC'
	END
	
	
	
	EXEC sp_sqlexec @StringSQL
	PRINT @StringSQL
	





