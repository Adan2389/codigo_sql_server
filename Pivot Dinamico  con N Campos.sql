	
	
	DECLARE @FECHA_INICIO varchar(12) ='01-08-2019'
	DECLARE @FECHA_FINAL varchar(12) ='08-08-2019'
	
	DECLARE @COD_AREA varchar(50) = 'SAC-1-TEL'
	
	Declare @Consulta varchar(max)
	Declare @ComposPivot varchar(2000)

	Select @ComposPivot = STUFF((Select DISTINCT '],[' + 
										CAST(FECHA AS VARCHAR) 
										FROM SMANT_5S_EVALUACION AS A WHERE COD_PREGUNTA IN (
											SELECT COD_PREGUNTA FROM  SMANT_5S_PREGUNTAS 
											WHERE  COD_AREA = @COD_AREA									
										) AND (FECHA >=@FECHA_INICIO AND FECHA <=@FECHA_FINAL) 
								  FOR XML PATH('')),1,2,'') +  + ']'

	Set @Consulta =			
			'SELECT *
			FROM(
                  SELECT FECHA, COD_AREA, SUM(VALOR)AS VALOR
                  FROM(
                        SELECT *,
                                   (SELECT COD_AREA FROM SMANT_5S_PREGUNTAS WHERE COD_PREGUNTA=C1.COD_PREGUNTA)AS COD_AREA,
                                   (SELECT TIPO_5S FROM SMANT_5S_PREGUNTAS WHERE COD_PREGUNTA=C1.COD_PREGUNTA)AS TIPO_5S
                        FROM(
                             SELECT FECHA, COD_PREGUNTA, CAST(VALOR AS INT )AS VALOR
                             FROM SMANT_5S_EVALUACION
                             WHERE FECHA >='''+@FECHA_INICIO+''' AND FECHA <='''+@FECHA_FINAL+'''  
                        )AS C1
                  )AS C2
                  WHERE COD_AREA ='''+@COD_AREA+'''
                  GROUP BY FECHA, COD_AREA
           )AS C1 PIVOT(SUM(VALOR)FOR FECHA IN ('+@ComposPivot+') ) P
           '
           
	exec(@Consulta)
	
	
	
