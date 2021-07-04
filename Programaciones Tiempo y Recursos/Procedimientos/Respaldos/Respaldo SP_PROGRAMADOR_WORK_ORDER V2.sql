
execute PROGRAMADOR_WORK_ORDER 'E-02', '22/01/2018', '10:14', ' REPROG. PRU_E-02_86.35 HRS 3.6 DIAS',0



CREATE PROCEDURE PROGRAMADOR_WORK_ORDER
(
	@prm_Maquina nvarchar(20) , 
	@prm_FechaInicioPrg date,
	@prm_HoraInicio time,
	@prm_ProgramacionID nvarchar(50),
	@prm_IncluirDomingos bit,
	@prm_HoraCicloDia time = '06:00', 
	@prm_TipoTurno varchar(10)='ABC',
	@prm_Accion varchar(20)='PROGRAMACION',
	@prm_CreadoPor varchar(30)='APP_SISTEMAS'
	
)
AS

	--DECLARE @prm_Maquina nvarchar(20) = 'E-02' 
	--DECLARE @prm_FechaInicioPrg date = '24/01/2018'
	--DECLARE @prm_HoraInicio time = '06:00'
	--DECLARE @prm_ProgramacionID nvarchar(50) = 'PRUEBA_V1'
	--DECLARE @prm_IncluirDomingos bit = 0
	--DECLARE @prm_HoraCicloDia time = '06:00'
	--DECLARE @prm_TipoTurno varchar(10)='ABC'
	--DECLARE @prm_Accion varchar(20)='REPROGRAMACION'
	--DECLARE @prm_CreadoPor varchar(30)='APP_SISTEMAS' 

	
	DECLARE @i numeric(10,2)						----Recorre el total del tiempo de la orden en base a (100)

	DECLARE @TotalDiaHrs decimal(12,2)				--Límite del día (2400)
	DECLARE @AcumAsingDiaHrs decimal(12,2)			--Acumulador de 0-2400 para completar un dia. 

	DECLARE @TotalTurnoHrs decimal(12,2)			--Limite condicionado según el tipo turno (800, 700, 900)
	DECLARE @AcumAsingTurnoHrs decimal(12,2)        --Acumulador para completar un turno 0-Limite 


	DECLARE @i_Item	int								--Indica el número de orden de línea (ítem) en la Programación 
	DECLARE @AsingOrdenHrs decimal(12,2)            --Indica el total de hrs asignadas a un Ítem de la Orden
	DECLARE @FechaPrg date							--Indica la fecha del ítem 
	DECLARE @Turno Char(1)							--Identifica el Turno 
	DECLARE @AcumDias	int 						--Acumula los dias Asignados en la Programacion

---VARIABLES DEL CURSOR 
	DECLARE
	@crs_ProgramacionID varchar(100) , 	@crs_MaquinaID varchar(20) ,		@crs_CreadoPor varchar(30) ,		 @crs_FechaCreado datetime ,		
	@crs_Item smallint , 				@crs_Estado smallint ,				@crs_TipoItem smallint ,			 @crs_Descripcion varchar(350) , 
	@crs_FechaItem date ,				@crs_Orden nvarchar(30) ,			@crs_NumOrder smallint ,			 @crs_Turno varchar(2) ,			
	@crs_TipoTurno varchar(10) ,		@crs_TipoHorario int ,				@crs_Part_id nvarchar(15) ,			 @crs_CoProducto nvarchar(15) , 
	@crs_Libras Decimal(12,4) ,			@crs_Ancho varchar(50) ,			@crs_Largo varchar(50) ,			 @crs_Espesor varchar(50) ,			
	@crs_PesoMetro float ,				@crs_TotalMetros Decimal(12,2) ,	@crs_Colores smallint ,				 @crs_Rodillo Decimal(12,2),
	@crs_NoPistas smallint ,			@crs_FardosXhora decimal(12,2) , 	@crs_HrsCambio Decimal(12,2) ,	 	 @crs_MetrosMetaMin Decimal(8,2) ,	
	@crs_TSeteo Decimal(12,2) ,			@crs_Por_Desperdicio varchar(10) ,	@crs_Desperdicio Decimal(12,2) ,	 @crs_LibrasXhora Decimal(12,2) ,
	@crs_HorasTrabajo Decimal(12,2) ,	@crs_TInicio datetime ,				@crs_TFinal datetime  ,				 @crs_Observacion varchar(350)

	--CURSOR PARA RECORRER LAS ORDENES DE TRABAJO SEGUN LA ACCION 
	if (@prm_Accion ='PROGRAMACION')
	begin
		DECLARE crsWorkOrder CURSOR FOR 

			SELECT @prm_ProgramacionID , @prm_Maquina , @prm_CreadoPor, GETDATE() , NULL , 1 , 1 , BASE_ID ,	NULL , BASE_ID , NUMORDER ,	NULL ,
			@prm_TipoTurno ,	1 , PART_ID , CO_PRODUCTO ,  LIBRAS , 	Ancho ,  NULL , Espesor , 	Peso_Metro, 	NULL , NULL , NULL ,
			NULL , NULL , NULL , NULL , T_SETEO , 	NULL , NULL,  LibrasXHora, 	TOT_HRSTRABAJO ,	NULL , NULL , 	NULL 
			FROM PLANNING_PRG_TEMP_ORDER 
			ORDER BY NUMORDER ASC
	end
	if (@prm_Accion ='REPROGRAMACION')
	begin
		DECLARE crsWorkOrder CURSOR FOR						
						
			SELECT ProgramacionID , MaquinaID , CreadoPor, FechaCreado , Item , Estado , TipoItem , Descripcion ,	FechaItem , Orden , NumOrder ,	Turno ,
			TipoTurno ,	TipoHorario , Part_id , CoProducto ,  Libras , 	Ancho ,  Largo , Espesor , 	PesoMetro, 	TotalMetros , Colores , Rodillo ,
			NoPistas , FardosXhora ,  HrsCambio , MetrosMetaMin , TSeteo , 	Por_Desperdicio , Desperdicio ,  LibrasXhora , 	HorasTrabajo ,
			TInicio , TFinal , 	Observacion 
			FROM PLANNING_PRG_TEMP_ITEM AS a
			ORDER BY Item ASC
	end
								
--INICIALIZO VALORES PREDETERMINADOS ANTES DE QUE EMPIECE EL CURSOR Y UTILIZO LA FUNCION DE CONFIGURACION DE INICIO
	Set @TotalDiaHrs =  2400.00
	SET @FechaPrg = @prm_FechaInicioPrg
	SET @i_Item = 0
	Set @AcumDias = 0

	Select  @TotalTurnoHrs = TotalHrsTurno,
			@AcumAsingTurnoHrs = HrInicioTurno,
			@AcumAsingDiaHrs = HrInicioDia,
			@Turno = Turno
	from dbo.CONFIG_INICIO_PRG(@prm_HoraInicio)

OPEN crsWorkOrder
FETCH NEXT FROM crsWorkOrder INTO @crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @crs_Item , @crs_Estado ,	@crs_TipoItem ,	
								  @crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_TipoTurno , @crs_TipoHorario , 
								  @crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
								  @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
								  @crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo ,
								  @crs_TInicio , @crs_TFinal , @crs_Observacion
WHILE (@@FETCH_STATUS = 0)
BEGIN
	Set @AsingOrdenHrs = 0.00
	Set @i	= 1.0
	IF (@crs_Turno IS  NULL)
	BEGIN
		---------------------------------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------   GUARDANDO TURNOS COMPLETOS    -----------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------
		WHILE (@i <= (@crs_HorasTrabajo * 100) )
		BEGIN
			--IDENTIFICO EL TURNO
			if (@AcumAsingTurnoHrs = @TotalTurnoHrs)
			begin
	
				If (@AcumAsingDiaHrs = 800)
				begin
					SET @Turno = 'A'
					-- Hrs sig turno
					SET @TotalTurnoHrs = 700  
				end

				If (@AcumAsingDiaHrs = 1500)
				begin
					SET @Turno = 'B'
					-- Hrs sig turno
					SET @TotalTurnoHrs = 900 
				end

				If (@AcumAsingDiaHrs = 2400)
				begin
					SET @Turno = 'C'
					-- Hrs sig turno
					SET @TotalTurnoHrs = 800 
				end	
						
				--MANDO A CALCULAR Y GUARDAR EL ITEM
				SET @i_Item = @i_Item + 1

				EXECUTE SP_GUARDAR_ITEM 1 ,	@FechaPrg , @AcumDias , @AsingOrdenHrs , @AcumAsingDiaHrs , @crs_LibrasXhora , @prm_HoraCicloDia ,

				@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @i_Item , @crs_Estado ,	@crs_TipoItem ,	
				@crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @Turno , @crs_TipoTurno , @crs_TipoHorario , 
				@crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
				@crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
				@crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion

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
				--Para volver acumular hrs 
				Set @AcumAsingDiaHrs = 0
			end
			--incremento de los acumuladores en base 100
			Set @AcumAsingDiaHrs = @AcumAsingDiaHrs + 1      
			set @AcumAsingTurnoHrs = @AcumAsingTurnoHrs + 1  
			Set @AsingOrdenHrs = @AsingOrdenHrs + 1			 
			Set @i = @i + 1.0
		
		END--FIN DEL CILCLO DE HRS

	
		---------------------------------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------   GUARDANDO HORAS SOBRANTES     -----------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------

		--VERIFICO EL TURNO Y GARDO EL ITEM DE LAS HRS SOBRANTES DE LA ORDEN
		if (@AcumAsingTurnoHrs < @TotalTurnoHrs )
		begin
			If ( @AcumAsingDiaHrs > 0 and @AcumAsingDiaHrs < 800 )
				SET @Turno = 'A'
			
			If (@AcumAsingDiaHrs >= 800 and  @AcumAsingDiaHrs < 1500 )
				SET @Turno = 'B'
			
			If ( @AcumAsingDiaHrs >= 1500 and @AcumAsingDiaHrs <= 2400)
				SET @Turno = 'C'
	

			--GUARDO EL REGISTRO 
			SET @i_Item = @i_Item + 1

			EXECUTE SP_GUARDAR_ITEM 1,	@FechaPrg, @AcumDias, @AsingOrdenHrs , @AcumAsingDiaHrs , @crs_LibrasXhora , @prm_HoraCicloDia ,

				@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @i_Item , @crs_Estado ,	@crs_TipoItem ,	
				@crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @Turno , @crs_TipoTurno , @crs_TipoHorario , 
				@crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
				@crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
				@crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion
		end

	END

	  ELSE

	BEGIN
		--------------------------------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------    GUARDANDO UNA RE-PORGRAMACION   -------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------

		--EN CASO DE QUE SEA UNA REPROGRAMACION Y EL TURNO ESTE ASIGNADO SOLAMENTE SE GUARDARA EL REGISTRO SIN REALIZAR NINGUN CALCULO
		SET @i_Item = @i_Item + 1
				
		EXECUTE SP_GUARDAR_ITEM 0,	NULL, NULL, NULL , NULL , NULL , NULL ,

				@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @i_Item , @crs_Estado ,	@crs_TipoItem ,	
				@crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_TipoTurno , @crs_TipoHorario , 
				@crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
				@crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
				@crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion

	END
			
FETCH NEXT FROM crsWorkOrder INTO @crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @crs_Item , @crs_Estado ,	@crs_TipoItem ,	
								  @crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_TipoTurno , @crs_TipoHorario , 
								  @crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
								  @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
								  @crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo ,
								  @crs_TInicio , @crs_TFinal , @crs_Observacion
END
CLOSE crsWorkOrder
DEALLOCATE crsWorkOrder


--Elimino los registros de las tablas teporales que alimentan el Programador de Trabajo
DELETE FROM PLANNING_PRG_TEMP_ITEM
DELETE FROM PLANNING_PRG_TEMP_ORDER


GO






