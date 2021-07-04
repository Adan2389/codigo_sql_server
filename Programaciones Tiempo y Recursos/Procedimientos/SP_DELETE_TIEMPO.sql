
--ESTE PROCEDIMIENTO ELIMINA UN TIEMPO DE LA PROGRAMACION YA SEA UNA ORDEN DE PRODUCCION O UN TIEMPO DE MANTENIMIENTO
--UTILIZA EL CAMPO DESCRIPCION PARA ELLIMAR TODOS LOS ITEM QUE TENGAN DICHA DESCRIPCION

ALTER PROCEDURE DELETE_TIEMPO
(
	@prm_PROGRAMACIONID varchar(100),
	@prm_DESCRIPCION varchar(350),
	@Fecha_Retornada date = null output,
	@Hora_Retornada time = null output

)
as 
BEGIN

	--Cargo la Programacion en la Tabla Fisica-Temporal 
	DELETE FROM PLANNING_PRG_TEMP_ITEM
	INSERT INTO PLANNING_PRG_TEMP_ITEM
		SELECT * FROM PLANNING_PROGRAMACION WHERE ProgramacionID = @prm_PROGRAMACIONID
		
	--Variables de Verificacion	
	DECLARE @ORDERNAR BIT =0			--Permite decidir el momento en que va reordenar los items
	DECLARE @NEWITEM smallint = null	--Obtiene el nuevo numero de item en la reordenacion
	DECLARE @TInicio_Default datetime = null --Obtiene la Fecha-Hora Predeterminada en los casos Cuando se elimina el primier Tiempo(Orden)

	
	--Variables del cursor 
	DECLARE
	@crs_ProgramacionID varchar(100) , 	@crs_Item smallint , 				@crs_Turno varchar(2) ,		@crs_Estado smallint ,
	@crs_Descripcion varchar(350) ,     @crs_TInicio datetime ,				@crs_TFinal datetime  ,		@crs_FechaReprog datetime,
	@crs_TipoTiempo smallint

		DECLARE crsProgramacion CURSOR FOR 
		SELECT ProgramacionID , Item, Turno, Estado ,  Descripcion ,TInicio , TFinal, FechaReprog, TipoTiempo	
		FROM PLANNING_PRG_TEMP_ITEM AS a
		ORDER BY Item ASC
	OPEN crsProgramacion


	FETCH NEXT FROM crsProgramacion INTO @crs_ProgramacionID ,  @crs_Item , @crs_Turno, @crs_Estado ,	@crs_Descripcion ,	
										 @crs_TInicio , @crs_TFinal , @crs_FechaReprog, @crs_TipoTiempo 
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF (@prm_DESCRIPCION = @crs_Descripcion )
			Set @ORDERNAR = 1	
				
			
		IF ( @ORDERNAR = 1)
		BEGIN
			IF (@prm_DESCRIPCION = @crs_Descripcion )
			BEGIN
				DELETE FROM PLANNING_PRG_TEMP_ITEM WHERE ITEM=	@crs_Item
			END
			ELSE
			BEGIN
				--Obtengo la Fecha-Hora Default 
				IF (@TInicio_Default IS NULL)
					SELECT @TInicio_Default= TInicio FROM  PLANNING_PRG_TEMP_ITEM WHERE PROGRAMACIONID = @prm_PROGRAMACIONID  AND ITEM =	@crs_Item

				--Voy Quitando los Tunros y las Fechas para que queden listos para reprogramar 
				UPDATE PLANNING_PRG_TEMP_ITEM SET  TInicio=NULL, TFinal= NULL, Turno= NULL, Estado=@crs_Estado+1, FechaReprog=GETDATE()
				WHERE PROGRAMACIONID = @prm_PROGRAMACIONID  AND ITEM =	@crs_Item
			END
			
			--Voy Eliminando los Items que sean RECESOS que se encuentran adelante del tiempo que se va a eliminar
			if (@crs_TipoTiempo = 2)
				DELETE FROM PLANNING_PRG_TEMP_ITEM WHERE PROGRAMACIONID = @prm_PROGRAMACIONID  AND ITEM =	@crs_Item	
				

		END

		FETCH NEXT FROM crsProgramacion INTO @crs_ProgramacionID ,  @crs_Item , @crs_Turno, @crs_Estado ,	@crs_Descripcion ,	
										 @crs_TInicio , @crs_TFinal , @crs_FechaReprog, @crs_TipoTiempo
	END
	CLOSE crsProgramacion
	DEALLOCATE crsProgramacion

	--Elimino la Programacion Vieja, dejando la nueva modificacion en la tabala fisica-temporal con el tiempo  insertado
	--Lista para que sea Re-programada
	DELETE FROM PLANNING_PROGRAMACION WHERE ProgramacionID=@prm_PROGRAMACIONID

	Select @Fecha_Retornada = CAST(Max(TFinal) AS DATE) from PLANNING_PRG_TEMP_ITEM WHERE PROGRAMACIONID = @prm_PROGRAMACIONID 
	Select @Hora_Retornada= CONVERT(VARCHAR(5),Max(TFinal),108) from PLANNING_PRG_TEMP_ITEM WHERE PROGRAMACIONID = @prm_PROGRAMACIONID 

	--Asigno la Fecha Default si el primer Item fue el que se elimino
	IF (@Fecha_Retornada IS NULL)
	begin
		select  @Fecha_Retornada = CAST(@TInicio_Default AS DATE) 
		Select @Hora_Retornada= CONVERT(VARCHAR(5),@TInicio_Default,108) 
	end


END 
GO 