
--ESTE PROCEDIMIENTO AGRUPA LOS ITEMS ACUMULANDO LAS LIBRAS Y LAS HORAS DE TRABAJO 
--PARA EVITAR QUE AL REPROGRAMAR SE CREEN MUCHOS FRAGMENTOS DE REGISTROS CON RESPECTO AL TIMEMPO POR ITEM.


CREATE PROCEDURE AGRUPAR_PROGRAMACION(@ProgramacionID varchar(100))
as
BEGIN

	
	DECLARE @Guardar bit = 0 --Indica el Momento en que va a Guardar el Registro en la Tabla Temporal

	--TABLA TEMPORAL PARA GUARDAR LA PROGRAMACION
	
	CREATE TABLE ##Temp_Programacion   (
	ProgramacionID varchar(100) ,	MaquinaID varchar(20) ,		CreadoPor varchar(30) ,			 FechaCreado datetime ,		
	Estado smallint ,				TipoItem smallint ,			Descripcion varchar(350) ,  	 FechaItem date ,				
	Orden nvarchar(30) ,			NumOrder smallint ,			Turno varchar(2) ,				 Horario_TrabajoID varchar(50),	
	TipoHorario int ,				Part_id nvarchar(15) ,		CoProducto nvarchar(15) ,		 Libras Decimal(12,4) ,
	Ancho varchar(50) ,				Largo varchar(50) ,			Espesor varchar(50) ,			 PesoMetro float ,			
	TotalMetros Decimal(12,2) ,		Colores smallint ,			Rodillo Decimal(12,2),			 NoPistas smallint ,		
	FardosXhora decimal(12,2) , 	HrsCambio Decimal(12,2) ,	MetrosMetaMin Decimal(8,2) ,	 TSeteo Decimal(12,2) ,	
	Por_Desperdicio varchar(10) ,	Desperdicio Decimal(12,2) ,	LibrasXhora Decimal(12,2) , 	 HorasTrabajo Decimal(12,2) ,	
	TInicio datetime ,				TFinal datetime  ,			Observacion varchar(350) , 		 FechaReprog datetime ,	
	Item_Order_Line smallint ,		TipoTiempo smallint ,		Tot_HrsOrden decimal(12,2)
	
	)
	

	--Variables Verificadoras Temporales
	DECLARE
	@Temp_TipoItem smallint ,			@Temp_Descripcion varchar(350) ,	 @Temp_FechaItem date	,			@Temp_Turno varchar(2) ,
	@Temp_TipoTiempo smallint	
		
	--Variables Acumuladoras Temporales
	DECLARE				   				
	@Temp_Libras Decimal(12,4) ,		@Temp_TotalMetros Decimal(12,2) ,	@Temp_HorasTrabajo Decimal(12,2) ,	@Temp_TFinal datetime	
	
	--Variables Solo Guardar	
	DECLARE
	@Temp_ProgramacionID varchar(100) ,	@Temp_MaquinaID varchar(20) ,		@Temp_CreadoPor varchar(30) ,	 	 @Temp_FechaCreado datetime ,		
	@Temp_Estado smallint ,				@Temp_Orden nvarchar(30) ,			@Temp_NumOrder smallint ,			 @Temp_Horario_TrabajoID varchar(50),
	@Temp_TipoHorario int ,				@Temp_Part_id nvarchar(15) ,	    @Temp_CoProducto nvarchar(15) ,  	 @Temp_Ancho varchar(50) ,	
	@Temp_Largo varchar(50) ,			@Temp_Espesor varchar(50) ,			@Temp_PesoMetro float ,				 @Temp_Colores smallint ,
	@Temp_Rodillo Decimal(12,2),		@Temp_NoPistas smallint ,			@Temp_FardosXhora decimal(12,2) , 	 @Temp_HrsCambio Decimal(12,2) ,	
	@Temp_MetrosMetaMin Decimal(8,2) ,	@Temp_TSeteo Decimal(12,2) ,		@Temp_Por_Desperdicio varchar(10) ,  @Temp_Desperdicio Decimal(12,2) ,	
	@Temp_LibrasXhora Decimal(12,2) ,	@Temp_TInicio datetime ,			@Temp_Observacion varchar(350) ,   	 @Temp_FechaReprog datetime ,	
	@Temp_Item_Order_Line smallint 	 ,  @Temp_Tot_HrsOrden decimal(12,2)

	
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
	@crs_FechaReprog datetime ,			@crs_Item_Order_Line smallint ,		@crs_TipoTiempo smallint ,			 @crs_Tot_HrsOrden decimal(12,2)
	
	
	DECLARE crsProgramacion CURSOR FOR 
		--Obtengo las solamente las Horas de Produccion  y Excluyo los Recesos
		SELECT ProgramacionID , MaquinaID , CreadoPor, FechaCreado , Item , Estado , TipoItem , Descripcion ,	FechaItem , Orden , NumOrder ,	Turno ,
		Horario_TrabajoID ,	TipoHorario , Part_id , CoProducto ,  Libras , 	Ancho ,  Largo , Espesor , 	PesoMetro, 	TotalMetros , Colores , Rodillo , NoPistas , 
		FardosXhora ,  HrsCambio , MetrosMetaMin , TSeteo , 	Por_Desperdicio , Desperdicio ,  LibrasXhora , 	HorasTrabajo , TInicio , TFinal , 	
		Observacion, FechaReprog , Item_Order_Line  ,	TipoTiempo  , Tot_HrsOrden
		FROM PLANNING_PROGRAMACION AS a WHERE ProgramacionID = @ProgramacionID and TipoItem=1 AND TipoTiempo=1

		UNION 

		--Obtengo los Otros Items que no son de Produccion Incluyendo los recesos.
		SELECT ProgramacionID , MaquinaID , CreadoPor, FechaCreado , Item , Estado , TipoItem , Descripcion ,	FechaItem , Orden , NumOrder ,	Turno ,
		Horario_TrabajoID ,	TipoHorario , Part_id , CoProducto ,  Libras , 	Ancho ,  Largo , Espesor , 	PesoMetro, 	TotalMetros , Colores , Rodillo , NoPistas , 
		FardosXhora ,  HrsCambio , MetrosMetaMin , TSeteo , 	Por_Desperdicio , Desperdicio ,  LibrasXhora , 	HorasTrabajo , TInicio , TFinal , 	
		Observacion, FechaReprog , Item_Order_Line  ,	TipoTiempo  , Tot_HrsOrden
		FROM PLANNING_PROGRAMACION AS a WHERE ProgramacionID = @ProgramacionID and TipoItem > 1 
		ORDER BY Item ASC


		OPEN crsProgramacion

	FETCH NEXT FROM crsProgramacion INTO @crs_ProgramacionID , 	@crs_MaquinaID , @crs_CreadoPor , @crs_FechaCreado , @crs_Item,  @crs_Estado ,	@crs_TipoItem ,	
										 @crs_Descripcion ,	@crs_FechaItem , @crs_Orden , @crs_NumOrder ,  @crs_Turno , @crs_Horario_TrabajoID , @crs_TipoHorario , 
										 @crs_Part_id , @crs_CoProducto , @crs_Libras , @crs_Ancho , @crs_Largo , @crs_Espesor , @crs_PesoMetro , @crs_TotalMetros , 
										 @crs_Colores , @crs_Rodillo , @crs_NoPistas , 	@crs_FardosXhora , @crs_HrsCambio , @crs_MetrosMetaMin , @crs_TSeteo , 	
										 @crs_Por_Desperdicio , @crs_Desperdicio , @crs_LibrasXhora , @crs_HorasTrabajo , @crs_TInicio , @crs_TFinal , @crs_Observacion ,
										 @crs_FechaReprog ,	@crs_Item_Order_Line ,	@crs_TipoTiempo  , @crs_Tot_HrsOrden
	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		IF (@crs_Item = 1 )
		BEGIN
			--Guardo Temporalmente el primer Item en Lectura
			Set @Temp_ProgramacionID=@crs_ProgramacionID  	Set @Temp_MaquinaID=@crs_MaquinaID  				Set @Temp_CreadoPor=@crs_CreadoPor  		 
			Set @Temp_FechaCreado=@crs_FechaCreado  		Set @Temp_Estado=@crs_Estado  						Set @Temp_TipoItem=@crs_TipoItem  				
			Set @Temp_Descripcion=@crs_Descripcion   		Set @Temp_FechaItem=@crs_FechaItem  				Set @Temp_Orden=@crs_Orden  					
			Set @Temp_NumOrder=@crs_NumOrder  				Set @Temp_Turno=@crs_Turno  						Set @Temp_Horario_TrabajoID=@crs_Horario_TrabajoID													
			Set @Temp_TipoHorario=@crs_TipoHorario  		Set @Temp_Part_id = @crs_Part_id 					Set @Temp_CoProducto=@crs_CoProducto   				
			Set @Temp_Libras  = @crs_Libras					Set @Temp_Ancho=@crs_Ancho  						Set @Temp_Largo=@crs_Largo  					
			Set @Temp_Espesor=@crs_Espesor  				Set @Temp_PesoMetro=@crs_PesoMetro					Set @Temp_TotalMetros=@crs_TotalMetros  		
			Set @Temp_Colores=@crs_Colores  				Set @Temp_Rodillo=@crs_Rodillo						Set @Temp_NoPistas=@crs_NoPistas 				
			Set @Temp_FardosXhora=@crs_FardosXhora 			Set @Temp_HrsCambio=@crs_HrsCambio  	 	 		Set @Temp_MetrosMetaMin=@crs_MetrosMetaMin  	
			Set @Temp_TSeteo=@crs_TSeteo  					Set @Temp_Por_Desperdicio=@crs_Por_Desperdicio  	Set @Temp_Desperdicio=@crs_Desperdicio  		
			Set @Temp_LibrasXhora=@crs_LibrasXhora  		Set @Temp_HorasTrabajo = @crs_HorasTrabajo  		Set @Temp_TInicio=@crs_TInicio  				
			Set @Temp_TFinal=@crs_TFinal   					Set @Temp_Observacion = @crs_Observacion			Set @Temp_FechaReprog=@crs_FechaReprog  		
			Set @Temp_Item_Order_Line=@crs_Item_Order_Line 	Set @Temp_TipoTiempo = @crs_TipoTiempo				Set @Temp_Tot_HrsOrden=@crs_Tot_HrsOrden 
		END
		ELSE
		BEGIN
		
			If (@crs_TipoItem=@Temp_TipoItem)
			begin
				if (@crs_TipoItem=1)
				begin
						
					if (@crs_Descripcion = @Temp_Descripcion  )	
					begin
						Set @Guardar = 0
					end
					else
					begin
						Set @Guardar = 1
					end	
					
				end
				else
				begin
					Set @Guardar = 0
				end
			end
			else
			begin
				Set @Guardar = 1
			end

				
			if (@Guardar = 1)
			begin
				--Guardo en la Tabla Temporal el Registro a mostrar
				INSERT INTO ##Temp_Programacion 
					SELECT 
					 @Temp_ProgramacionID ,		@Temp_MaquinaID  ,				@Temp_CreadoPor	,					 @Temp_FechaCreado  ,	
					 @Temp_Estado  	,			@Temp_TipoItem  ,				@Temp_Descripcion	,			  	 @Temp_FechaItem  	,		
					 @Temp_Orden ,				@Temp_NumOrder ,		 		@Temp_Turno  ,					 	 @Temp_Horario_TrabajoID ,													
					 @Temp_TipoHorario  ,		@Temp_Part_id  ,				@Temp_CoProducto  , 				 @Temp_Libras 	,
					 @Temp_Ancho  ,				@Temp_Largo , 				    @Temp_Espesor ,				 		 @Temp_PesoMetro ,
					 @Temp_TotalMetros  ,		@Temp_Colores  ,				@Temp_Rodillo	,					 @Temp_NoPistas ,
					 @Temp_FardosXhora 	,		@Temp_HrsCambio  ,	 	 		@Temp_MetrosMetaMin , 				 @Temp_TSeteo  	,
					 @Temp_Por_Desperdicio,		@Temp_Desperdicio , 		    @Temp_LibrasXhora ,					 @Temp_HorasTrabajo ,
					 @Temp_TInicio ,  			@Temp_TFinal  ,					@Temp_Observacion  ,				 @Temp_FechaReprog  ,
					 @Temp_Item_Order_Line,		@Temp_TipoTiempo ,				@Temp_Tot_HrsOrden  	

				--Guardo Temporalmente el Item en Lectura
				Set @Temp_ProgramacionID=@crs_ProgramacionID  	Set @Temp_MaquinaID=@crs_MaquinaID  				Set @Temp_CreadoPor=@crs_CreadoPor  		 
				Set @Temp_FechaCreado=@crs_FechaCreado  		Set @Temp_Estado=@crs_Estado  						Set @Temp_TipoItem=@crs_TipoItem  				
				Set @Temp_Descripcion=@crs_Descripcion   		Set @Temp_FechaItem=@crs_FechaItem  				Set @Temp_Orden=@crs_Orden  					
				Set @Temp_NumOrder=@crs_NumOrder  				Set @Temp_Turno=@crs_Turno  						Set @Temp_Horario_TrabajoID=@crs_Horario_TrabajoID													
				Set @Temp_TipoHorario=@crs_TipoHorario  		Set @Temp_Part_id = @crs_Part_id 					Set @Temp_CoProducto=@crs_CoProducto   				
				Set @Temp_Libras  = @crs_Libras					Set @Temp_Ancho=@crs_Ancho  						Set @Temp_Largo=@crs_Largo  					
				Set @Temp_Espesor=@crs_Espesor  				Set @Temp_PesoMetro=@crs_PesoMetro					Set @Temp_TotalMetros=@crs_TotalMetros  		
				Set @Temp_Colores=@crs_Colores  				Set @Temp_Rodillo=@crs_Rodillo						Set @Temp_NoPistas=@crs_NoPistas 				
				Set @Temp_FardosXhora=@crs_FardosXhora 			Set @Temp_HrsCambio=@crs_HrsCambio  	 	 		Set @Temp_MetrosMetaMin=@crs_MetrosMetaMin  	
				Set @Temp_TSeteo=@crs_TSeteo  					Set @Temp_Por_Desperdicio=@crs_Por_Desperdicio  	Set @Temp_Desperdicio=@crs_Desperdicio  		
				Set @Temp_LibrasXhora=@crs_LibrasXhora  		Set @Temp_HorasTrabajo = @crs_HorasTrabajo  		Set @Temp_TInicio=@crs_TInicio  				
				Set @Temp_TFinal=@crs_TFinal   					Set @Temp_Observacion = @crs_Observacion			Set @Temp_FechaReprog=@crs_FechaReprog  		
				Set @Temp_Item_Order_Line=@crs_Item_Order_Line 	Set @Temp_TipoTiempo = @crs_TipoTiempo				Set @Temp_Tot_HrsOrden=@crs_Tot_HrsOrden 

			end
			else
			begin
				--Acumulo el Item en Lectura(agregar campos que solo sean acumulados)
				Set @Temp_Libras = @Temp_Libras +@crs_Libras						Set @Temp_TotalMetros = @Temp_TotalMetros + @crs_TotalMetros
				Set @Temp_HorasTrabajo = @Temp_HorasTrabajo + @crs_HorasTrabajo		SeT @Temp_TFinal = @crs_TFinal 
			end
		
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

	--Guardo el Ultimo Item que fue leido en el Cursor
	INSERT INTO ##Temp_Programacion 
		SELECT 
			@Temp_ProgramacionID ,		@Temp_MaquinaID  ,				@Temp_CreadoPor	,					 @Temp_FechaCreado  ,	
			@Temp_Estado  	,			@Temp_TipoItem  ,				@Temp_Descripcion	,			  	 @Temp_FechaItem  	,		
			@Temp_Orden ,				@Temp_NumOrder ,		 		@Temp_Turno  ,					 	 @Temp_Horario_TrabajoID ,													
			@Temp_TipoHorario  ,		@Temp_Part_id  ,				@Temp_CoProducto  , 				 @Temp_Libras 	,
			@Temp_Ancho  ,				@Temp_Largo , 				    @Temp_Espesor ,				 		 @Temp_PesoMetro ,
			@Temp_TotalMetros  ,		@Temp_Colores  ,				@Temp_Rodillo	,					 @Temp_NoPistas ,
			@Temp_FardosXhora 	,		@Temp_HrsCambio  ,	 	 		@Temp_MetrosMetaMin , 				 @Temp_TSeteo  	,
			@Temp_Por_Desperdicio,		@Temp_Desperdicio , 		    @Temp_LibrasXhora ,					 @Temp_HorasTrabajo ,
			@Temp_TInicio ,  			@Temp_TFinal  ,					@Temp_Observacion  ,				 @Temp_FechaReprog  ,
			@Temp_Item_Order_Line,		@Temp_TipoTiempo ,				@Temp_Tot_HrsOrden
	
	--Consulta que devulve el Procedimiento  
	--SELECT ROW_NUMBER() OVER (ORDER BY FechaItem ASC )AS Item, FechaItem, ProgramacionID, MaquinaID, Estado, TipoItem, Descripcion, Orden, NumOrder,
	--Turno, Libras, HorasTrabajo, Tinicio, TFinal, TipoTiempo, Tot_HrsOrden, 
	
	-- (SELECT DBO.TURNO_VIEW (Horario_TrabajoID, Turno ))as TurnoView
	--FROM ##Temp_Programacion as a
	
		SELECT ProgramacionID , MaquinaID , CreadoPor, FechaCreado , ROW_NUMBER() OVER (ORDER BY FechaItem ASC )AS Item,
		Estado , TipoItem , Descripcion ,	FechaItem , Orden , NumOrder ,	Turno , Horario_TrabajoID ,	TipoHorario , Part_id , 
		CoProducto ,  Libras , 	Ancho ,  Largo , Espesor , 	PesoMetro, 	TotalMetros , Colores , Rodillo , NoPistas , 
		FardosXhora ,  HrsCambio , MetrosMetaMin , TSeteo , 	Por_Desperdicio , Desperdicio ,  LibrasXhora , 	HorasTrabajo , 
		TInicio , TFinal , 	Observacion, FechaReprog , Item_Order_Line  ,	TipoTiempo  , Tot_HrsOrden
		FROM ##Temp_Programacion

	DROP TABLE  ##Temp_Programacion

END

GO