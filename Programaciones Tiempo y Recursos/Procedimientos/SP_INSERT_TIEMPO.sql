
--ESTE PROCEDIMIENTO INSERTA  TIEMPOS DE (RECESO, PAROS, MANTENIMIENTO y ORDENES DE PRODUCCION ) SOBRE UNA PROGRAMACION O UNA REPROGRAMACION

ALTER PROCEDURE INSERT_TIEMPO
(
	@prm_FECHA DATE ,
	@prm_HORA TIME,
	@prm_ADD_HRS decimal(12,2),
	@prm_TipoItem smallint,
	@prm_TipoHorario smallint,
	@prm_DESCRIPCION varchar(350),
	@prm_PROGRAMACIONID VARCHAR(100),
	@prm_Observacion varchar(350)=null,
	@prm_Orden nvarchar(30) = null
	
)
as 
BEGIN
	
	--Variables por si se va insertar una orden de produccion 
	DECLARE 
	@ProgramacionID varchar(100)=null ,		@MaquinaID varchar(20) =null ,			@CreadoPor varchar(30) =null ,		 @FechaCreado datetime =null, 
	@Item smallint=null , 					@Estado smallint =null ,				@TipoItem smallint =null ,			 @Descripcion varchar(350) =null , 
	@FechaItem date =null,					@Orden nvarchar(30) =null ,				@NumOrder smallint =null ,			 @Turno varchar(2) =null , 
	@Horario_TrabajoID varchar(50)=null ,	@TipoHorario int =null ,				@Part_id nvarchar(15) =null ,		 @CoProducto nvarchar(15) =null , 
	@Libras Decimal(12,4)=null ,			@Ancho varchar(50) =null ,				@Largo varchar(50) =null ,			 @Espesor varchar(50) =null ,
	@PesoMetro float =null ,				@TotalMetros Decimal(12,2) =null ,		@Colores smallint =null ,			 @Rodillo Decimal(12,2) =null,
	@NoPistas smallint =null,				@FardosXhora decimal(12,2) =null, 		@HrsCambio Decimal(12,2) =null ,	 @MetrosMetaMin Decimal(8,2) =null ,
	@TSeteo Decimal(12,2)=null ,			@Por_Desperdicio varchar(10) =null , 	@Desperdicio Decimal(12,2) =null ,   @LibrasXhora Decimal(12,2) =null ,
	@HorasTrabajo Decimal(12,2)=null ,		@TInicio datetime =null ,				@TFinal datetime =null ,			 @Observacion varchar(350) =null, 
	@FechaReprog datetime = NULL ,			@Item_Order_Line smallint = NULL ,		@TipoTiempo smallint = NULL  ,		 @Tot_HrsOrden decimal(12,2)=null

		
	--Cargo la Programacion en la Tabla Fisica-Temporal 
	DELETE FROM PLANNING_PRG_TEMP_ITEM
	INSERT INTO PLANNING_PRG_TEMP_ITEM
		SELECT * FROM PLANNING_PROGRAMACION WHERE ProgramacionID = @prm_PROGRAMACIONID

	--Indentifico un Correlativo en la Descripcion de los Tiempos que no son de Produccion
	if (@prm_TipoItem > 1)
	begin
		SELECT @prm_DESCRIPCION = CAST((ISNULL(COUNT(Distinct Descripcion),0)+1) AS VARCHAR(10)) +'-'+ @prm_DESCRIPCION from PLANNING_PRG_TEMP_ITEM where TipoItem=@prm_TipoItem
	end
		
	--Variables de Verificacion	
	DECLARE @ORDERNAR BIT =0			--Permite decidir el momento en que va reordenar los items
	DECLARE @NEWITEM smallint = null	--Obtiene el nuevo numero de item en la reordenacion
	DECLARE @prm_FECHA_HORA_BUSCADA DATETIME = convert(varchar(12), @prm_FECHA,103 ) +' '+ cast(@prm_HORA as varchar(10))

	--Elimino los Items que sean RECESOS que se encuentran adelante del tiempo que se va a Insertar
	DELETE FROM PLANNING_PRG_TEMP_ITEM WHERE TInicio >=@prm_FECHA_HORA_BUSCADA and TipoTiempo=2

	--Asignacion inicial del tiempo que se va a insertar NO ES una orden de produccion 
	set @FechaItem = @prm_FECHA
	set @TInicio = @prm_FECHA_HORA_BUSCADA
	set @HorasTrabajo = @prm_ADD_HRS
	set @TipoItem = @prm_TipoItem
	set @TipoHorario = @prm_TipoHorario
	set @Descripcion = @prm_DESCRIPCION
	set @ProgramacionID = @prm_PROGRAMACIONID
	set @FechaCreado = getdate()
	set @Estado = 1
	set @Observacion = @prm_Observacion
	Select top 1 @MaquinaID=MaquinaID,  @CreadoPor=CreadoPor
	FROM PLANNING_PROGRAMACION WHERE ProgramacionID = @prm_PROGRAMACIONID

	--Asignacion inicial si el tiempo que se va insertar ES UNA  Orden de produccion
	if (@prm_Orden is not null)
	begin
		SELECT @NumOrder=MAX(NumOrder)+1 FROM PLANNING_PRG_TEMP_ITEM WHERE ProgramacionID=@ProgramacionID
	
		SELECT @Orden=BASE_ID, @Part_id=PART_ID,  @CoProducto=CO_PRODUCTO, @Libras=LIBRAS, @Ancho=Ancho, @Largo=NULL, @Espesor=Espesor, 
				@PesoMetro=Peso_Metro, @TSeteo = T_SETEO, @LibrasXhora= LibrasXHora, @Tot_HrsOrden=@prm_ADD_HRS, @Rodillo=Rodillo,
				@Colores=Colores
		from PLANNING_PRG_TEMP_ORDER  
	end

	--Variables del cursor 
	DECLARE
	@crs_ProgramacionID varchar(100) , 	@crs_MaquinaID varchar(20) ,		@crs_CreadoPor varchar(30) ,		 @crs_FechaCreado datetime ,		
	@crs_Item smallint , 				@crs_Estado smallint ,				@crs_TipoItem smallint ,			 @crs_Descripcion varchar(350) , 
	@crs_FechaItem date ,				@crs_Orden nvarchar(30) ,			@crs_NumOrder smallint ,			 @crs_Turno varchar(2) ,			
	@crs_Horario_TrabajoID varchar(50),	@crs_TipoHorario int ,				@crs_Part_id nvarchar(15) ,			 @crs_CoProducto nvarchar(15) , 
	@crs_Libras Decimal(12,4) ,			@crs_Ancho varchar(50) ,			@crs_Largo varchar(50) ,			 @crs_Espesor varchar(50) ,			
	@crs_PesoMetro float ,				@crs_TotalMetros Decimal(12,2) ,	@crs_Colores smallint ,				 @crs_Rodillo Decimal(12,2),
	@crs_NoPistas smallint ,			@crs_FardosXhora decimal(12,2) , 	@crs_HrsCambio Decimal(12,2) ,	 	 @crs_MetrosMetaMin Decimal(8,2) ,	
	@crs_TSeteo Decimal(12,2) ,			@crs_Por_Desperdicio varchar(10) ,	@crs_Desperdicio Decimal(12,2) ,	 @crs_LibrasXhora Decimal(12,2) ,
	@crs_HorasTrabajo Decimal(12,2) ,	@crs_TInicio datetime ,				@crs_TFinal datetime  ,				 @crs_Observacion varchar(350) ,
	@crs_FechaReprog datetime ,			@crs_Item_Order_Line smallint ,		@crs_TipoTiempo smallint  ,			 @crs_Tot_HrsOrden decimal(12,2)

	DECLARE crsProgramacion CURSOR FOR 
		SELECT ProgramacionID , MaquinaID , CreadoPor, FechaCreado , Item , Estado , TipoItem , Descripcion ,	FechaItem , Orden , NumOrder ,	Turno ,
		Horario_TrabajoID ,	TipoHorario , Part_id , CoProducto ,  Libras , 	Ancho ,  Largo , Espesor , 	PesoMetro, 	TotalMetros , Colores , Rodillo , NoPistas , 
		FardosXhora ,  HrsCambio , MetrosMetaMin , TSeteo , 	Por_Desperdicio , Desperdicio ,  LibrasXhora , 	HorasTrabajo , TInicio , TFinal , 	
		Observacion, FechaReprog , Item_Order_Line  ,	TipoTiempo ,  Tot_HrsOrden
		FROM PLANNING_PRG_TEMP_ITEM AS a
		ORDER BY Item ASC

	OPEN crsProgramacion


	FETCH NEXT FROM crsProgramacion INTO @crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @crs_Item , @crs_Estado ,	@crs_TipoItem ,	
										 @crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_Horario_TrabajoID , @crs_TipoHorario , 
										 @crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
										 @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
										 @crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion ,
										 @crs_FechaReprog ,	@crs_Item_Order_Line ,	@crs_TipoTiempo  , @crs_Tot_HrsOrden
	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		IF (NOT @ORDERNAR = 1)
		BEGIN
			IF (@prm_FECHA_HORA_BUSCADA  BETWEEN  @crs_TInicio  AND @crs_TFinal )
			BEGIN
				--------------------------------Cuando eL Tiempo que se va insertar comienza al inicio del primer Item del cursor--------------------------
				IF (@prm_FECHA_HORA_BUSCADA = @crs_TInicio )
				BEGIN
					SET @ORDERNAR = 1
					SET @NEWITEM = 1
					
					--Inserto el nuevo tiempo
					INSERT INTO  PLANNING_PRG_TEMP_ITEM VALUES(	
					@ProgramacionID , 	@MaquinaID , @CreadoPor , @FechaCreado , @NEWITEM , @Estado ,	@TipoItem ,	@Descripcion ,	@FechaItem , @Orden , @NumOrder ,			
					@Turno , @Horario_TrabajoID , @TipoHorario , @Part_id , @CoProducto , @Libras , @Ancho , @Largo , @Espesor , @PesoMetro , @TotalMetros , @Colores ,
					@Rodillo , @NoPistas , 	@FardosXhora , @HrsCambio , @MetrosMetaMin , @TSeteo , 	@Por_Desperdicio , @Desperdicio , @LibrasXhora , @HorasTrabajo ,
					@TInicio , @TFinal , @Observacion,  @FechaReprog ,	@Item_Order_Line ,	@TipoTiempo , @Tot_HrsOrden   )

					SET @NEWITEM = @NEWITEM + 1

					--Actualizo haciendo nullo el turno y las fechas para que sea reprogramado el siguiente item
					UPDATE PLANNING_PRG_TEMP_ITEM SET  					
					Item = @NEWITEM	 ,	Estado= @crs_Estado + 1 ,	Turno = NULL ,	TInicio = NULL , TFinal = NULL, FechaReprog=GETDATE()
					WHERE PROGRAMACIONID = @prm_PROGRAMACIONID  AND TINICIO=@crs_TInicio AND  TFINAL=@crs_TFinal

				END
				  ELSE
				BEGIN
					-------------------------Cuando eL Tiempo que se va insertar comienza al final  del rango de horas del Item-----------------------------
					IF (@prm_FECHA_HORA_BUSCADA = @crs_TFinal )
					BEGIN
						SET @ORDERNAR = 1
						SET @NEWITEM = @crs_Item + 1

						--Inserto el nuevo Tiempo
						INSERT INTO  PLANNING_PRG_TEMP_ITEM VALUES(	
						@ProgramacionID , 	@MaquinaID , @CreadoPor , @FechaCreado , @NEWITEM , @Estado ,	@TipoItem ,	@Descripcion ,	@FechaItem , @Orden , @NumOrder ,			
						@Turno , @Horario_TrabajoID , @TipoHorario , @Part_id , @CoProducto , @Libras , @Ancho , @Largo , @Espesor , @PesoMetro , @TotalMetros , @Colores ,
						@Rodillo , @NoPistas , 	@FardosXhora , @HrsCambio , @MetrosMetaMin , @TSeteo , 	@Por_Desperdicio , @Desperdicio , @LibrasXhora , @HorasTrabajo ,
						@TInicio , @TFinal , @Observacion , @FechaReprog ,	@Item_Order_Line ,	@TipoTiempo , @Tot_HrsOrden)

					END
					  ELSE
					BEGIN
						-----------------------Cuando eL Tiempo que se va insertar comienza  en medio del rango de horas del Item --------------------------
					
						--Calculo los valores del los campos del item que se corto antes del tiempo a insertar,  ya que no va a ser reprogramado en la funcion
						Declare @Mod_Libras decimal(12,2), @Mod_Horas decimal(12,2), @mod_TotalMetros decimal(12,2), @mod_MetrosMetaMin decimal(12,2),
						@mod_FardosXhora decimal(12,2), @Mod_Desperdicio decimal(12,2), @mod_Por_Desperdicio varchar(10)
						Select @Mod_Horas = (DATEDIFF(MINUTE,@crs_TInicio,@prm_FECHA_HORA_BUSCADA) /60.00)
						SET @Mod_Libras = (@crs_Libras/@crs_HorasTrabajo) * @Mod_Horas
						SET @mod_TotalMetros = (@crs_TotalMetros/@crs_HorasTrabajo) * @Mod_Horas
						SET @mod_MetrosMetaMin = (@mod_TotalMetros/(@Mod_Horas*60)) 
						SET @mod_FardosXhora = (@crs_TotalMetros/@crs_FardosXhora ) * @Mod_Horas
						SET @Mod_Desperdicio = (@crs_Desperdicio/@crs_HorasTrabajo) * @Mod_Horas
						SET @mod_Por_Desperdicio = (@crs_Por_Desperdicio/@crs_HorasTrabajo) * @Mod_Horas
						--Aplico la actualizacion
						UPDATE PLANNING_PRG_TEMP_ITEM SET  TFinal=@prm_FECHA_HORA_BUSCADA, Libras= @Mod_Libras,  HorasTrabajo=@Mod_Horas, Estado= @crs_Estado+1,
						TotalMetros=@mod_TotalMetros, MetrosMetaMin=@mod_MetrosMetaMin, FardosXhora=@mod_FardosXhora,  Desperdicio = @Mod_Desperdicio, 
						Por_Desperdicio = @mod_Por_Desperdicio, FechaReprog=GETDATE()
						WHERE PROGRAMACIONID = @prm_PROGRAMACIONID  AND ITEM =@crs_Item


						--Inserto el nuevo Tiempo
						SET @ORDERNAR = 1
						SET @NEWITEM = @crs_Item + 1
						INSERT INTO  PLANNING_PRG_TEMP_ITEM VALUES(	
						@ProgramacionID , 	@MaquinaID , @CreadoPor , @FechaCreado , @NEWITEM , @Estado ,	@TipoItem ,	@Descripcion ,	@FechaItem , @Orden , @NumOrder ,			
						@Turno , @Horario_TrabajoID , @TipoHorario , @Part_id , @CoProducto , @Libras , @Ancho , @Largo , @Espesor , @PesoMetro , @TotalMetros , @Colores ,
						@Rodillo , @NoPistas , 	@FardosXhora , @HrsCambio , @MetrosMetaMin , @TSeteo , 	@Por_Desperdicio , @Desperdicio , @LibrasXhora , @HorasTrabajo ,
						@TInicio , @TFinal , @Observacion , @FechaReprog ,	@Item_Order_Line ,	@TipoTiempo , @Tot_HrsOrden )


						--Inserto y calculo los valores del los campos del item que se corto y quedo despues  del tiempo a insertar
						--este item va a ser reprogramado por la funcion y actualizara los campos de calculos 						 
						SET @NEWITEM = @NEWITEM + 1

						INSERT INTO  PLANNING_PRG_TEMP_ITEM VALUES(	
						@crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @NEWITEM , (@crs_Estado + 1) ,	@crs_TipoItem ,	@crs_Descripcion ,	NULL , 
						@crs_Orden , @crs_NumOrder ,NULL , @crs_Horario_TrabajoID , @crs_TipoHorario , @crs_Part_id , @crs_CoProducto , (@crs_Libras-@Mod_Libras) , 
						@crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , 	@crs_TotalMetros , @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	
						@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	(CAST(@crs_Por_Desperdicio AS FLOAT)-CAST(@mod_Por_Desperdicio AS FLOAT)) , 
						(@crs_Desperdicio-@Mod_Desperdicio) , @crs_LibrasXhora , (@crs_HorasTrabajo-@Mod_Horas) ,NULL , NULL , @crs_Observacion , GETDATE() ,	
						 @crs_Item_Order_Line ,	@crs_TipoTiempo , @crs_Tot_HrsOrden )
					END
				END
			END
		END

		ELSE

		BEGIN
			--CONTINUO ORDENANDO LOS DEMAS ITEMS, ANULANDO LOS TURNOS Y LAS FECHAS PARA QUE SEAN REPROGRAMADOS POR LA FUNCION
			SET @NEWITEM = @NEWITEM + 1
			UPDATE PLANNING_PRG_TEMP_ITEM SET ITEM =@NEWITEM,  TInicio=NULL, TFinal= NULL, Turno= NULL, Estado= @crs_Estado + 1, FechaReprog=GETDATE()
			WHERE PROGRAMACIONID = @prm_PROGRAMACIONID  AND TINICIO=@crs_TInicio AND  TFINAL=@crs_TFinal
		END

		FETCH NEXT FROM crsProgramacion INTO @crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @crs_Item , @crs_Estado ,	@crs_TipoItem ,	
											 @crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_Horario_TrabajoID , @crs_TipoHorario , 
											 @crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
											 @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
											 @crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion ,
											 @crs_FechaReprog ,  @crs_Item_Order_Line ,	@crs_TipoTiempo , @crs_Tot_HrsOrden
	END
	CLOSE crsProgramacion
	DEALLOCATE crsProgramacion

	--Elimino la Programacion Vieja, dejando la nueva modificacion en la tabala fisica-temporal con el tiempo  insertado
	--Lista para que sea Re-programada
	DELETE FROM PLANNING_PROGRAMACION WHERE ProgramacionID=@prm_PROGRAMACIONID


END 
GO 