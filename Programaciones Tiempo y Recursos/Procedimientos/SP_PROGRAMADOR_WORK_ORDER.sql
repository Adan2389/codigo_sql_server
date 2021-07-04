
execute PROGRAMADOR_WORK_ORDER 'E-02', '22/01/2018', '10:14', ' REPROG. PRU_E-02_86.35 HRS 3.6 DIAS',0



ALTER PROCEDURE PROGRAMADOR_WORK_ORDER
(
	@prm_Maquina nvarchar(20) , 
	@prm_FechaInicioPrg date,
	@prm_HoraInicio time,
	@prm_ProgramacionID nvarchar(50),
	@prm_IncluirDomingos bit,
	@prm_Horario_TrabajoID varchar(50),
	@prm_Accion varchar(20),
	@prm_CreadoPor varchar(30)
	
)
AS
	
	--execute ADD_WORK_ORDER 1, 'OPR-04020-18'

	--DECLARE @prm_Maquina nvarchar(20) = 'E-02' 
	--DECLARE @prm_FechaInicioPrg date = '05/02/2018'
	--DECLARE @prm_HoraInicio time = '06:00'
	--DECLARE @prm_ProgramacionID nvarchar(50) = 'Prueba'
	--DECLARE @prm_IncluirDomingos bit = 0
	--DECLARE @prm_Horario_TrabajoID varchar(50)='ABCD-[8,7,9]RECS'
	--DECLARE @prm_Accion varchar(20)='PROGRAMACION'
	--DECLARE @prm_CreadoPor varchar(30)='APP_SISTEMAS' 
	
	
	
	--Asigna un Numero de Autoincremento para diferenciar las Programaciones
	
	Declare @Incremento nvarchar(10)
	SELECT @Incremento = CAST(ISNULL(COUNT(*),0)+1 AS VARCHAR(15)) +'__'
	FROM (SELECT DISTINCT PROGRAMACIONID FROM PLANNING_PROGRAMACION )AS C1

	Set @prm_ProgramacionID = @Incremento + @prm_ProgramacionID



--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--||||||||||||||||||||||||||||||||||||||||||||                                            |||||||||||||||||||||||||||||||||||||||||||||||||||||||
--|||||||||||||||||||||||||||||||||||||||||||| INICIALIZACION DE LOS HORARIOS DE TRABAJO  |||||||||||||||||||||||||||||||||||||||||||||||||||||||
--||||||||||||||||||||||||||||||||||||||||||||                                            |||||||||||||||||||||||||||||||||||||||||||||||||||||||
--||||||||||||||||||||||||||||||||||||||||||||  para poder inicializar la programacion    |||||||||||||||||||||||||||||||||||||||||||||||||||||||
--||||||||||||||||||||||||||||||||||||||||||||  o reprogramacion se debe utilizar la      |||||||||||||||||||||||||||||||||||||||||||||||||||||||
--||||||||||||||||||||||||||||||||||||||||||||  tabla "HORARIOS_TRABAJO", de acuerdo      |||||||||||||||||||||||||||||||||||||||||||||||||||||||
--||||||||||||||||||||||||||||||||||||||||||||  a la secuencia y lectura se van asignar   |||||||||||||||||||||||||||||||||||||||||||||||||||||||
--||||||||||||||||||||||||||||||||||||||||||||  los turnos, recesos u otro.               |||||||||||||||||||||||||||||||||||||||||||||||||||||||
--||||||||||||||||||||||||||||||||||||||||||||                                            |||||||||||||||||||||||||||||||||||||||||||||||||||||||
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
						
		
	DECLARE @i numeric(10,2)						--Recorre el total del tiempo de la (orden/item) en base a (100)

	DECLARE @TotalDiaHrs decimal(12,2)				--Límite del día segun el horario de trabajo
	DECLARE @AcumAsingDiaHrs decimal(12,2)			--Acumulador de 0-limiete para completar un dia, segun el horario de trabajo

	DECLARE @TotalTurnoHrs decimal(12,2)			--Limite del Turno segun horario de trabajo
	DECLARE @AcumAsingTurnoHrs decimal(12,2)        --Acumulador para completar un turno 0-Limite 


	DECLARE @i_Item	int								--Indica el número de orden de línea (ítem) en la Programación 
	DECLARE @i_Item_Order_line smallint				--Indica el nuemro de Item en que se fragmenta una Orden de Produccion 
	DECLARE @AsingOrdenHrs decimal(12,2)            --Indica el total de hrs asignadas a un Ítem de la Orden
	DECLARE @FechaPrg date							--Indentifica la fecha del ítem 
	DECLARE @AcumDias	int 						--Acumula los dias Asignados en la Programacion
	
	DECLARE @Turno varchar(2)						--Identifica el Turno 
	Declare @TipoTiempo smallint					--Sirver para difenrenciar el tipo de tiempo de produccion vrs recesos en los diferentes turnos
	Declare @Num_Secuencia smallint					--Obtiene el numero de Lectura del registro que identifica la informacion del turno
	Declare @Max_Secuencia smallint					--Indentifica el ultimo turno del ciclo de dia segun el horario de trabajo  
	Declare @HoraCicloDia time						--Obtiene la Hora del CicloDia para calcular las fechas de inicio y final de cada Item
	Declare @Desc_Tiempo varchar(50)				--Obtiene  la Descripcion del tiempo del Turno
	
	
	SET @FechaPrg = @prm_FechaInicioPrg
	SET @i_Item = 0
	SET @i_Item_Order_line = 0
	Set @AcumDias = 0
			
	Select @TotalDiaHrs  = TotalDiaHrs, 
		   @HoraCicloDia = THora_CicloDia
	from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID AND Secuencia=1
	order by Secuencia asc

	--Obtengo el ultimo numero de secuencia para poder inciar el ciclo de trabajo nuevamente
	SELECT @Max_Secuencia=MAX(Secuencia) from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
	
	--Esta funcion me devulve la hora base_100 a partir de la cual se iniciara la programacion
	--si devulve nulo, quiere decir que la hora esta fuera del horario de trabajo 
	SELECT @AcumAsingDiaHrs = DBO.INICIO_DIA(@prm_HoraInicio, @prm_Horario_TrabajoID) 

	--Obtengo la informacion del turno con el cual voy a inciar la programacion 
	SELECT @Turno=Turno, 
		   @TipoTiempo=TipoTiempo, 
		   @Desc_Tiempo = Descripcion,
		   @TotalTurnoHrs=TotalTurnoHrs,
		   @AcumAsingTurnoHrs=((TInicio_b100-@AcumAsingDiaHrs)*-1), 
		   @Num_Secuencia=Secuencia
	from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
	AND TFinal_b100 > @AcumAsingDiaHrs AND  TInicio_b100 <= @AcumAsingDiaHrs
	


--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||



---VARIABLES DEL CURSOR 
	DECLARE
	@crs_ProgramacionID varchar(100) , 	@crs_MaquinaID varchar(20) ,		@crs_CreadoPor varchar(30) ,		 @crs_FechaCreado datetime ,		
	@crs_Item smallint , 				@crs_Estado smallint ,				@crs_TipoItem smallint ,			 @crs_Descripcion varchar(350) , 
	@crs_FechaItem date ,				@crs_Orden nvarchar(30) ,			@crs_NumOrder smallint ,			 @crs_Turno varchar(2) ,			
	@crs_Horario_TrabajoID varchar(50),	@crs_TipoHorario int ,				@crs_Part_id nvarchar(15) ,			 @crs_CoProducto nvarchar(15) , 
	@crs_Libras Decimal(12,4) ,			@crs_Ancho varchar(50) ,			@crs_Largo varchar(50) ,			 @crs_Espesor varchar(50) ,			
	@crs_PesoMetro float ,				@crs_TotalMetros Decimal(12,2) ,	@crs_Colores smallint ,				 @crs_Rodillo Decimal(12,2),
	@crs_NoPistas smallint ,			@crs_FardosXhora decimal(12,2) , 	@crs_HrsCambio Decimal(12,2) ,	 	 @crs_MetrosMetaMin Decimal(8,2) ,	
	@crs_TSeteo Decimal(12,2) ,			@crs_Por_Desperdicio varchar(10) ,	@crs_Desperdicio Decimal(12,2) ,	 @crs_LibrasXhora Decimal(12,2) ,
	@crs_HorasTrabajo Decimal(12,2) ,	@crs_TInicio datetime ,				@crs_TFinal datetime  ,				 @crs_Observacion varchar(350),
	@crs_FechaReprog datetime ,			@crs_Item_Order_Line smallint ,		@crs_TipoTiempo smallint ,			 @crs_Tot_HrsOrden decimal(12,2)

	--CURSOR PARA RECORRER LAS ORDENES DE TRABAJO SEGUN LA ACCION 
	if (@prm_Accion ='PROGRAMACION')
	begin
		DECLARE crsWorkOrder CURSOR FOR 

			SELECT @prm_ProgramacionID , @prm_Maquina , @prm_CreadoPor, GETDATE() , NULL , 1 , 1 , BASE_ID ,	NULL , BASE_ID , NUMORDER ,	NULL ,
			@prm_Horario_TrabajoID ,	1 , PART_ID , CO_PRODUCTO ,  NULL , 	Ancho ,  NULL , Espesor , 	Peso_Metro, 	NULL , Colores , Rodillo ,
			NULL , NULL , NULL , NULL , T_SETEO , 	NULL , NULL,  LibrasXHora, 	TOT_HRSTRABAJO ,	NULL , NULL , 	NULL , NULL , NULL, NULL ,
			TOT_HRSTRABAJO
			FROM PLANNING_PRG_TEMP_ORDER 
			ORDER BY NUMORDER ASC
	end
	if (@prm_Accion ='REPROGRAMACION')
	begin
		DECLARE crsWorkOrder CURSOR FOR						
						
			SELECT ProgramacionID , MaquinaID , CreadoPor, FechaCreado , Item , Estado , TipoItem , Descripcion ,	FechaItem , Orden , NumOrder ,	Turno ,
			Horario_TrabajoID ,	TipoHorario , Part_id , CoProducto ,  Libras , 	Ancho ,  Largo , Espesor , 	PesoMetro, 	TotalMetros , Colores , Rodillo ,
			NoPistas , FardosXhora ,  HrsCambio , MetrosMetaMin , TSeteo , 	Por_Desperdicio , Desperdicio ,  LibrasXhora , 	HorasTrabajo ,
			TInicio , TFinal , 	Observacion, FechaReprog , Item_Order_Line , TipoTiempo, Tot_HrsOrden 
			FROM PLANNING_PRG_TEMP_ITEM AS a
			ORDER BY Item ASC
	end


OPEN crsWorkOrder
FETCH NEXT FROM crsWorkOrder INTO @crs_ProgramacionID , @crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @crs_Item , @crs_Estado ,	@crs_TipoItem ,	
								  @crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_Horario_TrabajoID , @crs_TipoHorario , 
								  @crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
								  @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
								  @crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo ,   @crs_TInicio , @crs_TFinal , @crs_Observacion , 
								  @crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo , @crs_Tot_HrsOrden
WHILE (@@FETCH_STATUS = 0)
BEGIN
	Set @AsingOrdenHrs = 0.00
	Set @i	= 0.0
	Set @i_Item_Order_line = 0
	IF (@crs_Turno IS  NULL)
	BEGIN
		
		PRINT 'LEYENDO ORDEN: ' + @crs_Descripcion + ' Horas Tranajo: ' + cast(@crs_HorasTrabajo as varchar(15))
		
		WHILE (@i < (@crs_HorasTrabajo * 100) )
		BEGIN

			-- *** EL ACUMULADOR DE LA ORDEN SOLO INCREMENTA SI EL TIEMPO ES DE PRODUCCION Y SI ES UNA ORDEN DE UN PROCESO DE PRODUCCION
			IF (@crs_TipoItem=1)
			begin
				if (@TipoTiempo=1)
					Set @i = @i + 1.0
			end
			else
			begin
				Set @i = @i + 1.0
			end
			
			 PRINT ' RUN: ' + CAST(@i AS VARCHAR(15))
			
--------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------   GUARDANDO TURNOS COMPLETOS    -----------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
			if (@AcumAsingTurnoHrs = @TotalTurnoHrs)
			begin
				
				--Indentifico la informacion del Turno Actual desde la Tabla de configuracion de horarios
				SELECT @Turno=Turno, 
				       @TotalTurnoHrs=TotalHrsSigTurno,
				       @TipoTiempo= TipoTiempo
				from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
				AND Secuencia= @Num_Secuencia

				Set @crs_TipoTiempo = @TipoTiempo
											
				--Enumero los Item de las Ordenes de Produccion en la primera programacion
				if (@prm_Accion='PROGRAMACION' and @TipoTiempo=1 and @crs_TipoItem=1)
				begin
					SET @i_Item_Order_line = @i_Item_Order_line + 1
					Set @crs_Item_Order_Line = @i_Item_Order_line
				end
					
				---Enumero los Item de las Ordenes de Produccion Cuando vienen en una insersion con reprogramacion
				if (@prm_Accion='REPROGRAMACION' AND @crs_TipoItem=1 and @crs_Estado=1)
				begin
					SET @i_Item_Order_line = @i_Item_Order_line + 1
					Set @crs_Item_Order_Line = @i_Item_Order_line
				end
				
								
				--MANDO A CALCULAR Y GUARDAR EL ITEM
				SET @i_Item = @i_Item + 1
				
				PRINT 'ASIGNACION DE TURNO COMPLETO: ' + CAST(@AsingOrdenHrs AS VARCHAR(15))
				PRINT ' TURNO: ' + @Turno + ' ACUMULADO DEL TURNO: ' + CAST(@AcumAsingTurnoHrs AS VARCHAR(15)) + ' LIMITE DEL SIG. TURNO: ' +   CAST(@TotalTurnoHrs AS VARCHAR(15))
				PRINT 'TIPO TIEMPO: ' + CAST(@TipoTiempo AS VARCHAR(15))+ ' DESCRIPCION: '+ @Desc_Tiempo +'-'+ @crs_Descripcion

				EXECUTE SP_GUARDAR_ITEM NULL, @prm_Accion ,	@FechaPrg , @AcumDias , @AsingOrdenHrs , @AcumAsingDiaHrs , @crs_LibrasXhora , @HoraCicloDia ,

				@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @i_Item , @crs_Estado ,	@crs_TipoItem ,	
				@crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @Turno , @prm_Horario_TrabajoID , @crs_TipoHorario , 
				@crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
				@crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
				@crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion ,
				@crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo , @crs_Tot_HrsOrden
							
				--Paso la siguiente Secuencia
				Set  @Num_Secuencia = @Num_Secuencia + 1
												
				--si el nuemro de secuencia llego al final vuelvo a iniciar el horario de trabajo
				if (@Num_Secuencia > @Max_Secuencia )
				begin
					set @Num_Secuencia = 1
				end

				--Obtengo el Tipo de Tiempo 
				SELECT @TipoTiempo= TipoTiempo
				from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
				AND Secuencia= @Num_Secuencia

				
				--ACUMULO P/ OTRO TURNO, ITEM 
				Set @AcumAsingTurnoHrs = 0
				Set @AsingOrdenHrs = 0
			end
	
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%% IMPORTANTE: EN ESTA SECCION SE PUEDEN MODIFICAR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%% LA EJECUCION DEL HORARIO DE TRABAJO, CREANDO    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%% HORARIOS ESPECIALES EN DETERMIANDOS DIAS.       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
					
			--*** AVANZA DE DIA EN DIA SEGUN LA HORA CICLO DIA ***
			if (@AcumAsingDiaHrs = @TotalDiaHrs)
			begin
				
				Set @AcumDias = @AcumDias +1 

				--Para volver acumular hrs para otra fecha 
				Set @AcumAsingDiaHrs = 0
											
				--SI NO SE TRABAJAN LOS DOMINGOS  
				IF (@prm_IncluirDomingos = 0)
				begin
					--Tomo 6 Hrs del dia Domingo para cerrar el Sabado
					IF ( (SELECT DATEPART(DW,DATEADD(DAY,@AcumDias,@FechaPrg)))=7 )
					begin
						Set @TotalDiaHrs = 600.00
						 
					end
					else
					begin
						Set @TotalDiaHrs = 2400.00
					end

					--Y corro 6 hrs del DIA Lunes para Empezar a la 6:00 de la mañana
					IF ( (SELECT DATEPART(DW,DATEADD(DAY,@AcumDias,@FechaPrg)))=1 )
						Set @AcumAsingDiaHrs = 600.00
				end

				
			end
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			--*** INCREMENTO DE LOS ACUMULADORES EN BASE 100 ***
			Set @AcumAsingDiaHrs = @AcumAsingDiaHrs + 1      
			set @AcumAsingTurnoHrs = @AcumAsingTurnoHrs + 1  
			Set @AsingOrdenHrs = @AsingOrdenHrs + 1		
				
		
		END--FIN DEL CILCLO DE HRS

	
--------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------   GUARDANDO HORAS SOBRANTES     -----------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

		--VERIFICO EL TURNO Y GARDO EL ITEM DE LAS HRS SOBRANTES DE LA ORDEN
		if (@AcumAsingTurnoHrs <= @TotalTurnoHrs )
		begin
			
			SELECT @Turno=Turno,
				   @TipoTiempo = TipoTiempo					
			from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
			AND Secuencia= @Num_Secuencia

			Set @crs_TipoTiempo =@TipoTiempo

			--Enumero los Item de las Ordenes de Produccion en la primera programacion
			if (@prm_Accion='PROGRAMACION' and @TipoTiempo=1 and @crs_TipoItem=1)
			begin
				SET @i_Item_Order_line = @i_Item_Order_line + 1
				Set @crs_Item_Order_Line = @i_Item_Order_line
			end
					
			---Enumero los Item de las Ordenes de Produccion Cuando vienen en una insersion con reprogramacion
			if (@prm_Accion='REPROGRAMACION' AND @crs_TipoItem=1 and @crs_Estado=1)
			begin
				SET @i_Item_Order_line = @i_Item_Order_line + 1
				Set @crs_Item_Order_Line = @i_Item_Order_line
			end

			--GUARDO EL REGISTRO 
			SET @i_Item = @i_Item + 1
			

			PRINT 'ASIGNACION DE TURNO **IN__COMPLETO**: ' + CAST(@AsingOrdenHrs AS VARCHAR(15))
			PRINT ' TURNO: ' + @Turno + ' ACUMULADO DEL TURNO: ' + CAST(@AcumAsingTurnoHrs AS VARCHAR(15)) + 'LIMITE DEL TURNO: ' +   CAST(@TotalTurnoHrs AS VARCHAR(15))
			PRINT 'TIPO TIEMPO: ' + CAST(@TipoTiempo AS VARCHAR(15))+ ' DESCRIPCION: '+ @Desc_Tiempo +'-'+ @crs_Descripcion
			
			EXECUTE SP_GUARDAR_ITEM NULL, @prm_Accion,  @FechaPrg, @AcumDias, @AsingOrdenHrs , @AcumAsingDiaHrs , @crs_LibrasXhora , @HoraCicloDia ,

				@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @i_Item , @crs_Estado ,	@crs_TipoItem ,	
				@crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @Turno , @prm_Horario_TrabajoID , @crs_TipoHorario , 
				@crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
				@crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
				@crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion ,
				@crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo , @crs_Tot_HrsOrden

			--Para esos casos Raros cuando un turno se completa al salir de la Orden
			IF (@AcumAsingTurnoHrs = @TotalTurnoHrs)
			begin
				
				SELECT  @TotalTurnoHrs=TotalHrsSigTurno
				from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
				AND Secuencia= @Num_Secuencia

				Set @Num_Secuencia = @Num_Secuencia + 1 
				
				--si el nuemro de secuencia llego al final vuelvo a iniciar el horario de trabajo
				if (@Num_Secuencia > @Max_Secuencia )
					set @Num_Secuencia = 1
				
				SELECT @TipoTiempo= TipoTiempo				
				from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
				AND Secuencia= @Num_Secuencia

				Set @AcumAsingTurnoHrs = 0
				Set @AsingOrdenHrs = 0
			end	
			
			PRINT ''
			PRINT '************************************************************'
			PRINT  'LIMITE NEXT TURNO: ' +   CAST(@TotalTurnoHrs AS VARCHAR(15))
			PRINT '************************************************************'
			PRINT ''
			PRINT ''
			PRINT '************************************************************'
			PRINT  'TIPO TIEMPO: ' +   CAST(@TipoTiempo AS VARCHAR(15))
			PRINT '************************************************************'
			PRINT ''

		end
	END

	  ELSE

	BEGIN
		--------------------------------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------    GUARDANDO UNA RE-PORGRAMACION   -------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------

		--EN CASO DE QUE SEA UNA REPROGRAMACION Y EL TURNO ESTE ASIGNADO SOLAMENTE SE GUARDARA EL REGISTRO SIN REALIZAR NINGUN CALCULO
		SET @i_Item = @i_Item + 1
				
		EXECUTE SP_GUARDAR_ITEM NULL, NULL,	NULL, NULL, NULL , NULL , NULL , NULL ,

				@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @i_Item , @crs_Estado ,	@crs_TipoItem ,	
				@crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_Horario_TrabajoID , @crs_TipoHorario , 
				@crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
				@crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
				@crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion ,
				@crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo , @crs_Tot_HrsOrden

	END
			
FETCH NEXT FROM crsWorkOrder INTO @crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @crs_Item , @crs_Estado ,	@crs_TipoItem ,	
								  @crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_Horario_TrabajoID , @crs_TipoHorario , 
								  @crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
								  @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
								  @crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo ,  @crs_TInicio , @crs_TFinal , @crs_Observacion , 
								  @crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo , @crs_Tot_HrsOrden
END
CLOSE crsWorkOrder
DEALLOCATE crsWorkOrder


--Elimino los registros de las tablas teporales que alimentan el Programador de Trabajo
DELETE FROM PLANNING_PRG_TEMP_ITEM
DELETE FROM PLANNING_PRG_TEMP_ORDER


GO






