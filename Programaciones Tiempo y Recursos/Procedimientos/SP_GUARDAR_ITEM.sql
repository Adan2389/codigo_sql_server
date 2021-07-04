
--CALCULA Y GUARDA LOS DATOS DE UN ITEM EN LA PROGRAMACION 

ALTER PROCEDURE SP_GUARDAR_ITEM 
(
	--Decide se van a realizar calculos de algun proceso
	@prm_CalcularProceso bit,
	--Para Determinar los calculos cunado 'PROGRAMA' o 'REPROGRAMA'
	@prm_Accion varchar(20),

	--Variables para Calcular
	@prm_FechaPrg as date,
	@prm_AcumDias int,
	@prm_AsingOrdenHrs decimal(12,2),
	@prm_AcumAsingDiaHrs decimal(12,2),
	@prm_LibrasxHora decimal(8,2),
	@prm_HoraCicloDia time,
	

	--Datos a Gaurdar en la Programacion 
	@ProgramacionID varchar(100) , 			@MaquinaID varchar(20) ,		@CreadoPor varchar(30) ,		 @FechaCreado datetime , 
	@Item smallint , 						@Estado smallint ,				@TipoItem smallint ,			 @Descripcion varchar(350) , 
	@FechaItem date ,						@Orden nvarchar(30) ,			@NumOrder smallint ,			 @Turno varchar(2) , 
	@Horario_TrabajoID varchar(50) ,		@TipoHorario int ,				@Part_id nvarchar(15) ,			 @CoProducto nvarchar(15) , 
	@Libras Decimal(12,4) ,					@Ancho varchar(50) ,			@Largo varchar(50) ,			 @Espesor varchar(50) ,
	@PesoMetro float ,						@TotalMetros Decimal(12,2) ,	@Colores smallint ,				 @Rodillo Decimal(12,2),
	@NoPistas smallint ,					@FardosXhora decimal(12,2) , 	@HrsCambio Decimal(12,2) ,	 	 @MetrosMetaMin Decimal(8,2) ,
	@TSeteo Decimal(12,2) ,					@Por_Desperdicio varchar(10) , 	@Desperdicio Decimal(12,2) ,     @LibrasXhora Decimal(12,2) ,
	@HorasTrabajo Decimal(12,2) ,			@TInicio datetime ,				@TFinal datetime ,			 	 @Observacion varchar(350),
	@FechaReprog datetime ,					@Item_Order_Line smallint ,		@TipoTiempo smallint  ,			 @Tot_HrsOrden decimal(12,2)
	)
as
BEGIN
	
	IF (@prm_Accion IN ('PROGRAMACION',  'REPROGRAMACION'))
	BEGIN
	
		--Verifico si se van hacer calculos de un proceso de produccion
		if (@TipoTiempo=1 and @TipoItem=1)
		begin
			set @prm_CalcularProceso = 1
		end
		else
		begin
			set @prm_CalcularProceso = 0
		end

		--Calculos Especiales  del proceso de Extrusion
		IF (@prm_CalcularProceso = 1)
		begin
			--Aqui se Debe Acondicionar el Proceso por la Maquina 
			
			set @Libras = ((@prm_AsingOrdenHrs/100.00) * @prm_LibrasxHora)
			set @TotalMetros = (((@prm_AsingOrdenHrs/100.00) * @prm_LibrasxHora)/@PesoMetro)
			set @MetrosMetaMin= ((@prm_LibrasxHora/@PesoMetro)/60)	
		end	

		--Calculo de Fechas de la Programacion (APLICA PARA TODOS)
		select @FechaItem =  DATEADD(DAY,@prm_AcumDias,@prm_FechaPrg)
		select  @TInicio = DATEADD(MINUTE,(((@prm_AcumAsingDiaHrs - @prm_AsingOrdenHrs) /100.00)*60), CAST((convert(varchar(12), DATEADD(DAY,@prm_AcumDias,@prm_FechaPrg),103 ) +' '+ CAST(@prm_HoraCicloDia AS VARCHAR(5)))AS DATETIME))
		select  @TFinal= DATEADD(MINUTE,((@prm_AcumAsingDiaHrs/100.00)*60), CAST((convert(varchar(12), DATEADD(DAY,@prm_AcumDias,@prm_FechaPrg),103 ) +' '+ CAST(@prm_HoraCicloDia AS VARCHAR(5)))AS DATETIME))	
		set @HorasTrabajo= (@prm_AsingOrdenHrs/100.00)

		
		--Si el Tiempo es un Receso Reseteo los Campos 
		if (@TipoTiempo=2)
		begin
			set @Libras =NULL Set @TotalMetros = NULL set @MetrosMetaMin=NULL Set @Item_Order_Line = NULL Set @LibrasXhora = NULL
			Set @Part_id=NULL Set @CoProducto = NULL Set @Ancho=NULL Set @Largo=NULL Set @Espesor=NULL Set @PesoMetro=NULL 
			Set @Colores=NULL Set @Rodillo=NULL Set @NoPistas=NULL Set @FardosXhora=NULL Set @HrsCambio=NULL Set @TSeteo=NULL
			Set @Desperdicio=NULL Set @Por_Desperdicio=NULL
		end

	END

	INSERT INTO PLANNING_PROGRAMACION
		(
			ProgramacionID , MaquinaID , CreadoPor, FechaCreado , Item , Estado , TipoItem , Descripcion ,	FechaItem , Orden , NumOrder ,	Turno ,
			Horario_TrabajoID ,	TipoHorario , Part_id , CoProducto ,  Libras , 	Ancho ,  Largo , Espesor , 	PesoMetro, 	TotalMetros , Colores , Rodillo ,
			NoPistas , FardosXhora ,  HrsCambio , MetrosMetaMin , TSeteo , 	Por_Desperdicio , Desperdicio ,  LibrasXhora , 	HorasTrabajo ,
			TInicio , TFinal , 	Observacion , FechaReprog , Item_Order_Line  ,	TipoTiempo , Tot_HrsOrden
		)	
		VALUES
		(
			@ProgramacionID , 	@MaquinaID , @CreadoPor , @FechaCreado , @Item , @Estado ,	@TipoItem ,	@Descripcion ,	@FechaItem , @Orden , @NumOrder ,			
			@Turno , @Horario_TrabajoID , @TipoHorario , @Part_id , @CoProducto , @Libras , @Ancho , @Largo , @Espesor , @PesoMetro , @TotalMetros , @Colores ,
			@Rodillo , @NoPistas , 	@FardosXhora , @HrsCambio , @MetrosMetaMin , @TSeteo , 	@Por_Desperdicio , @Desperdicio , @LibrasXhora , @HorasTrabajo ,
			@TInicio , @TFinal , @Observacion, @FechaReprog , @Item_Order_Line  ,	@TipoTiempo , @Tot_HrsOrden
		)


END 
GO 