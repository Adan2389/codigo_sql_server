USE [APP_SISTEMAS]
GO
/****** Object:  StoredProcedure [dbo].[PROGRAMADOR_WORK_ORDER]    Script Date: 01/02/2018 11:22:20 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[PROGRAMADOR_WORK_ORDER]
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
	
	--execute ADD_WORK_ORDER 1, 'OPR-04542-18'

	--DECLARE @prm_Maquina nvarchar(20) = 'E-02' 
	--DECLARE @prm_FechaInicioPrg date = '26/01/2018'
	--DECLARE @prm_HoraInicio time = '14:00'
	--DECLARE @prm_ProgramacionID nvarchar(50) = 'E-02 25-01-2018  (View Report)'
	--DECLARE @prm_IncluirDomingos bit = 1
	--DECLARE @prm_Horario_TrabajoID varchar(50)='ABC'
	--DECLARE @prm_Accion varchar(20)='REPROGRAMACION'
	--DECLARE @prm_CreadoPor varchar(30)='APP_SISTEMAS' 

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

	DECLARE @Calcular bit 							--Indica al procedimiento de "Guardar_Item" si va a realizar calculos para una orden produccion

	DECLARE @i_Item	int								--Indica el número de orden de línea (ítem) en la Programación 
	DECLARE @i_Item_Order_line smallint					--Indica el nuemro de Item en que se fragmenta una Orden de Produccion 
	DECLARE @AsingOrdenHrs decimal(12,2)            --Indica el total de hrs asignadas a un Ítem de la Orden
	DECLARE @FechaPrg date							--Indica la fecha del ítem 
	DECLARE @AcumDias	int 						--Acumula los dias Asignados en la Programacion
	
	DECLARE @Turno Char(1)							--Identifica el Turno 
--	DECLARE @TipoTurno varchar(10)					--Obttine de los horarios trabajo el tipo de turno
	Declare @TipoTiempo smallint					--Sirver para difenrenciar el tipo de tiempo de produccion vrs recesos en los diferentes turnos
	Declare @Num_Secuencia smallint					--Obtiene el numero de Lectura del registro que identifica la informacion del turno
	Declare @Max_Secuencia smallint					--Indentifica el ultimo turno del ciclo de dia segun el horario de trabajo  
	Declare @HoraCicloDia time						--Obtiene la Hora del CicloDia para calcular las fechas de inicio y final de cada Item
	Declare @Desc_Tiempo varchar(50)				--Obtiene  la Descripcion del tiempo del Turno
	
	
	SET @FechaPrg = @prm_FechaInicioPrg
	set @Calcular = 0
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
	@crs_FechaReprog datetime ,			@crs_Item_Order_Line smallint ,		@crs_TipoTiempo smallint

	--CURSOR PARA RECORRER LAS ORDENES DE TRABAJO SEGUN LA ACCION 
	if (@prm_Accion ='PROGRAMACION')
	begin
		DECLARE crsWorkOrder CURSOR FOR 

			SELECT @prm_ProgramacionID , @prm_Maquina , @prm_CreadoPor, GETDATE() , NULL , 1 , 1 , BASE_ID ,	NULL , BASE_ID , NUMORDER ,	NULL ,
			@prm_Horario_TrabajoID ,	1 , PART_ID , CO_PRODUCTO ,  LIBRAS , 	Ancho ,  NULL , Espesor , 	Peso_Metro, 	NULL , NULL , NULL ,
			NULL , NULL , NULL , NULL , T_SETEO , 	NULL , NULL,  LibrasXHora, 	TOT_HRSTRABAJO ,	NULL , NULL , 	NULL , NULL , NULL, NULL 
			FROM PLANNING_PRG_TEMP_ORDER 
			ORDER BY NUMORDER ASC
	end
	if (@prm_Accion ='REPROGRAMACION')
	begin
		DECLARE crsWorkOrder CURSOR FOR						
						
			SELECT ProgramacionID , MaquinaID , CreadoPor, FechaCreado , Item , Estado , TipoItem , Descripcion ,	FechaItem , Orden , NumOrder ,	Turno ,
			Horario_TrabajoID ,	TipoHorario , Part_id , CoProducto ,  Libras , 	Ancho ,  Largo , Espesor , 	PesoMetro, 	TotalMetros , Colores , Rodillo ,
			NoPistas , FardosXhora ,  HrsCambio , MetrosMetaMin , TSeteo , 	Por_Desperdicio , Desperdicio ,  LibrasXhora , 	HorasTrabajo ,
			TInicio , TFinal , 	Observacion, FechaReprog , Item_Order_Line , TipoTiempo 
			FROM PLANNING_PRG_TEMP_ITEM AS a
			ORDER BY Item ASC
	end


OPEN crsWorkOrder
FETCH NEXT FROM crsWorkOrder INTO @crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @crs_Item , @crs_Estado ,	@crs_TipoItem ,	
								  @crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_Horario_TrabajoID , @crs_TipoHorario , 
								  @crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
								  @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
								  @crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo ,
								  @crs_TInicio , @crs_TFinal , @crs_Observacion , @crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo 
WHILE (@@FETCH_STATUS = 0)
BEGIN
	Set @AsingOrdenHrs = 0.00
	Set @i	= 1.0
	Set @i_Item_Order_line = 0
	IF (@crs_Turno IS  NULL)
	BEGIN
		---------------------------------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------   GUARDANDO TURNOS COMPLETOS    -----------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------
		PRINT 'LEYENDO ORDEN: ' + @crs_Descripcion + ' Horas Tranajo: ' + cast(@crs_HorasTrabajo as varchar(15))
		
		WHILE (@i <= (@crs_HorasTrabajo * 100) )
		BEGIN
			 
			 PRINT 'ITEM: '+ CAST(@crs_Item AS VARCHAR(15))+' RUN: ' + CAST(@i AS VARCHAR(15))
			
			if (@AcumAsingTurnoHrs = @TotalTurnoHrs)
			begin
				
				--Indentifico la informacion del Turno Actual desde la Tabla de configuracion de horarios, y paso a la sig. secuencia 
				SELECT @Turno=Turno, 
				    @Desc_Tiempo = Descripcion, 
				   @TotalTurnoHrs=TotalHrsSigTurno,
				   @Num_Secuencia=Secuencia+1
				from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
				AND Secuencia= @Num_Secuencia

				--Verifico si el Tiempo y el Item del turno actual son de produccion, para realizar los calculos
				if (@TipoTiempo=1 and @crs_TipoItem=1)
				begin
					set @Calcular = 1
					Set @crs_TipoTiempo =@TipoTiempo
					--Enumero los Item de las Ordenes de Produccion en la primera programacion
					if (@prm_Accion='PROGRAMACION')
					begin
						SET @i_Item_Order_line = @i_Item_Order_line + 1
						Set @crs_Item_Order_Line = @i_Item_Order_line
					end
					else
					begin
						---Enumero los Item de las Ordenes de Produccion Cuando vienen en una insersion con reprogramacion
						if (@prm_Accion='REPROGRAMACION' AND @crs_TipoItem=1 and @crs_Estado=1)
						begin
							SET @i_Item_Order_line = @i_Item_Order_line + 1
							Set @crs_Item_Order_Line = @i_Item_Order_line
						end

					end
				end
				else
				begin
					set @Calcular = 0
					Set @crs_Item_Order_Line = NULL
					Set @crs_TipoTiempo =@TipoTiempo
				end
				
								
				--MANDO A CALCULAR Y GUARDAR EL ITEM
				SET @i_Item = @i_Item + 1
				
				PRINT 'ASIGNACION DE TURNO COMPLETO: ' + CAST(@AsingOrdenHrs AS VARCHAR(15))
				PRINT ' TURNO: ' + @Turno + 'HRS DEL TURNO: ' + CAST(@AcumAsingTurnoHrs AS VARCHAR(15)) 

				EXECUTE SP_GUARDAR_ITEM @Calcular ,	@FechaPrg , @AcumDias , @AsingOrdenHrs , @AcumAsingDiaHrs , @crs_LibrasXhora , @HoraCicloDia ,

				@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @i_Item , @crs_Estado ,	@crs_TipoItem ,	
				@crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @Turno , @prm_Horario_TrabajoID , @crs_TipoHorario , 
				@crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
				@crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
				@crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion ,
				@crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo

							
				--Identifico el Tipo de Tiempo del siguiente turno
				SELECT @TipoTiempo=TipoTiempo
				from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
				AND Secuencia= @Num_Secuencia

				--Verifico si Tiempo y el Item del siguiente turno son de produccion, para realizar los calculos
				if (@TipoTiempo=1 and @crs_TipoItem=1)
				begin
					set @Calcular = 1
					Set @crs_TipoTiempo =@TipoTiempo
				end
				else
				begin
					set @Calcular = 0
					Set @crs_TipoTiempo =@TipoTiempo
				end


				--si el nuemro de secuencia llego al final vuelvo a iniciar el horario de trabajo
				if (@Num_Secuencia > @Max_Secuencia )
					set @Num_Secuencia = 1
				--ACUMULO P/ OTRO TURNO, ITEM 
				Set @AcumAsingTurnoHrs = 0
				Set @AsingOrdenHrs = 0
			end
	
			--AVANZA DE DIA EN DIA SEGUN LA HORA CICLO DIA
			if (@AcumAsingDiaHrs = @TotalDiaHrs)
			begin
				Set @AcumDias = @AcumDias +1 
			
				--si NO se trabaja los domingos se saltan!
				IF (@prm_IncluirDomingos = 0)
				begin
					IF ( (SELECT DATEPART(DW,DATEADD(DAY,@AcumDias,@FechaPrg)))=7 )
					begin
						Set @AcumDias = @AcumDias +1 
					end
				end
				--Para volver acumular hrs para otra fecha 
				Set @AcumAsingDiaHrs = 0
			end
			--incremento de los acumuladores en base 100
			Set @AcumAsingDiaHrs = @AcumAsingDiaHrs + 1      
			set @AcumAsingTurnoHrs = @AcumAsingTurnoHrs + 1  
			Set @AsingOrdenHrs = @AsingOrdenHrs + 1			 
			--el acumulador de la order solo incrementa si el tiempo es de produccion
			if (@TipoTiempo=1)
				Set @i = @i + 1.0
		
		END--FIN DEL CILCLO DE HRS

	
		---------------------------------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------   GUARDANDO HORAS SOBRANTES     -----------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------

		--VERIFICO EL TURNO Y GARDO EL ITEM DE LAS HRS SOBRANTES DE LA ORDEN
		if (@AcumAsingTurnoHrs <= @TotalTurnoHrs )
		begin
								
				SELECT @Desc_Tiempo = Descripcion, @Turno=Turno
				from HORARIOS_TRABAJO where Horario_TrabajoID=@prm_Horario_TrabajoID
				AND Secuencia= @Num_Secuencia

				Set @crs_TipoTiempo =@TipoTiempo

				--Enumero los Item de las Ordenes de Produccion 
				IF (@TipoTiempo=1 and @crs_TipoItem=1)
				begin
					--Cuando la es la Primera Programacion
					if (@prm_Accion='PROGRAMACION')

					begin
						SET @i_Item_Order_line = @i_Item_Order_line + 1
						Set @crs_Item_Order_Line = @i_Item_Order_line
					end
					else
					begin
						---Enumero los Item de las Ordenes de Produccion Cuando vienen en una insersion con reprogramacion
						if (@prm_Accion='REPROGRAMACION' AND @crs_TipoItem=1 and @crs_Estado=1)
						begin
							SET @i_Item_Order_line = @i_Item_Order_line + 1
							Set @crs_Item_Order_Line = @i_Item_Order_line
						end

					end
				end
				ELSE
				begin
					Set @crs_Item_Order_Line = NULL
				end

			--GUARDO EL REGISTRO 
			SET @i_Item = @i_Item + 1
			
			PRINT 'ASIGNACION DE TURNO IN_COMPLETO: ' + CAST(@AsingOrdenHrs AS VARCHAR(15))
			PRINT ' TURNO: ' + @Turno + 'HRS DEL TURNO: ' + CAST(@AcumAsingTurnoHrs AS VARCHAR(15)) 
			
			EXECUTE SP_GUARDAR_ITEM @Calcular,	@FechaPrg, @AcumDias, @AsingOrdenHrs , @AcumAsingDiaHrs , @crs_LibrasXhora , @HoraCicloDia ,

				@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @i_Item , @crs_Estado ,	@crs_TipoItem ,	
				@crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @Turno , @prm_Horario_TrabajoID , @crs_TipoHorario , 
				@crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
				@crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
				@crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion ,
				@crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo

		   --Para esos casos Raros cuando un turno se completa al salir de la Orden
			IF (@AcumAsingTurnoHrs = @TotalTurnoHrs)
			begin
				SELECT @Turno=Turno,
						@TotalTurnoHrs = TotalHrsSigTurno,
				        @Num_Secuencia=Secuencia+1
				from HORARIOS_TRABAJO 
				where Horario_TrabajoID=@prm_Horario_TrabajoID 	AND Secuencia= @Num_Secuencia

				Select @TipoTiempo = TipoTiempo from HORARIOS_TRABAJO 
				where Horario_TrabajoID=@prm_Horario_TrabajoID 	AND Secuencia= @Num_Secuencia 

				--Verifico si Tiempo y el Item del siguiente turno son de produccion, para realizar los calculos
				if (@TipoTiempo=1 and @crs_TipoItem=1)
				begin
					set @Calcular = 1
					Set @crs_TipoTiempo =@TipoTiempo
				end
				else
				begin
					set @Calcular = 0
					Set @crs_TipoTiempo =@TipoTiempo
				end
				
				--si el nuemro de secuencia llego al final vuelvo a iniciar el horario de trabajo
				if (@Num_Secuencia > @Max_Secuencia )
					set @Num_Secuencia = 1

				Set @AcumAsingTurnoHrs = 0
				Set @AsingOrdenHrs = 0
			end
		end

	END

	  ELSE

	BEGIN
		--------------------------------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------    GUARDANDO UNA RE-PORGRAMACION   -------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------

		--EN CASO DE QUE SEA UNA REPROGRAMACION Y EL TURNO ESTE ASIGNADO SOLAMENTE SE GUARDARA EL REGISTRO SIN REALIZAR NINGUN CALCULO
		SET @i_Item = @i_Item + 1
				
		EXECUTE SP_GUARDAR_ITEM NULL,	NULL, NULL, NULL , NULL , NULL , NULL ,

				@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @i_Item , @crs_Estado ,	@crs_TipoItem ,	
				@crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @prm_Horario_TrabajoID , @crs_TipoHorario , 
				@crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
				@crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
				@crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion ,
				@crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo

	END
			
FETCH NEXT FROM crsWorkOrder INTO @crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @crs_Item , @crs_Estado ,	@crs_TipoItem ,	
								  @crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_Horario_TrabajoID , @crs_TipoHorario , 
								  @crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
								  @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
								  @crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo ,
								  @crs_TInicio , @crs_TFinal , @crs_Observacion , @crs_FechaReprog , @crs_Item_Order_Line , @crs_TipoTiempo
END
CLOSE crsWorkOrder
DEALLOCATE crsWorkOrder


--Elimino los registros de las tablas teporales que alimentan el Programador de Trabajo
DELETE FROM PLANNING_PRG_TEMP_ITEM
DELETE FROM PLANNING_PRG_TEMP_ORDER

--Elimino esos Items (Desperdicios de Calculos en "O") que aparecen cuando se reprograma (CORREGIR ESTO DESPUES)
--Por mientras los mando a eliminar para que no estorben al momento de mostrar la Progranacion
  --DELETE FROM PLANNING_PROGRAMACION WHERE HorasTrabajo = 0.00 and Libras= 0.00 and TotalMetros=0.00 
		--								  AND ProgramacionID = @prm_ProgramacionID 


