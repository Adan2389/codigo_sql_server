
--ESTA  FUNCION DEVULVE LA HORA DE INCIO DEL DIA EN BASE A 100 SEGUN LA CONFIGURACION 
--DEL HORARIO DE TRABAJO. PARA DETERMINAR EN QUE HORA DEBE INICIAR LA PROGRAMACION 
--EN EL TUNRO QUE CORRESPONDA



CREATE FUNCTION INICIO_DIA (@HORA_INICIO TIME, @HORARIO_TRABAJOID varchar(50) ) returns Decimal(12,2)  
as 
BEGIN
	
	DECLARE @Hora_CicloDia time =null
	DECLARE @TotalDiaHrs decimal(12,2) = null
	DECLARE @TInicio_CicloDia datetime = null
	DECLARE @HrInicioDia decimal(12,2)= null
	
	SELECT  @Hora_CicloDia =THora_CicloDia,
			@TotalDiaHrs = TotalDiaHrs 
	from HORARIOS_TRABAJO where @HORARIO_TRABAJOID=@HORARIO_TRABAJOID AND Secuencia=1
	Set @TInicio_CicloDia ='01-01-1900 ' + cast(@Hora_CicloDia as varchar(5)) 

	--Recorro minuto a minuto a partir de la Hora Ciclo Dia
	DECLARE @i int = 0
	WHILE (NOT (CONVERT (TIME,@TInicio_CicloDia,108) = @HORA_INICIO))
	BEGIN
		SELECT @TInicio_CicloDia = DATEADD(MINUTE,1,@TInicio_CicloDia)
		
		SET  @i = @i + 1
	END

	SET @HrInicioDia=round(((@i/60.00)*100.00),0)

	--Si la hora de incio excede el total de horas de trabajo del dia 
	IF (@i > @TotalDiaHrs )
	begin
		SET @HrInicioDia= NULL
	end

	RETURN @HrInicioDia
END

GO 



