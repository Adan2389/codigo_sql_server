


ALTER PROCEDURE UPDATE_PROGRAMACION (@prm_PROGRAMACIONID VARCHAR(100))
AS 
BEGIN

---------------------------------------------------------------------------------------------------------------------------------------------
--------------- VERIFICO SI HUBO ALGUNA ACTUALIZACION DE LAS VELOCIDADES DE LAS MAQUINAS EN INFOR--------------------------------------------
---------------             QUE CORRESPONDAN A LAS ORDENES DE LA PROGRAMACION INDICADA            -------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------

		Declare @Actualizar bit = 0
		Declare @Run Decimal(12,2)
		Declare @OrdenPrg  nvarchar(30),  @LibrasXhoraPrg Decimal(12,2)

		DECLARE  crs_Temp_Itemns CURSOR FOR 
			SELECT Orden, LibrasXhora FROM  PLANNING_PROGRAMACION WHERE ProgramacionID= @prm_PROGRAMACIONID AND TipoItem=1 AND TipoTiempo=1 
			GROUP BY Orden, LibrasXhora

			OPEN crs_Temp_Itemns 

			FETCH NEXT FROM  crs_Temp_Itemns   INTO  @OrdenPrg,  @LibrasXhoraPrg

			WHILE (@@FETCH_STATUS=0)
			BEGIN
				SELECT @Run = RUN FROM VMFGPN.DBO.OPERATION WHERE WORKORDER_BASE_ID= @OrdenPrg AND RUN > 0
				IF(NOT(@Run=@LibrasXhoraPrg))
				begin
					Set @Actualizar = 1	
				end
			FETCH NEXT FROM  crs_Temp_Itemns   INTO @OrdenPrg,  @LibrasXhoraPrg 
			END
			CLOSE crs_Temp_Itemns
			DEALLOCATE crs_Temp_Itemns
	
	PRINT CAST( @Actualizar AS VARCHAR(10))

	
	--AVANZO CON EL PROCESO POR SI HUBO ALGUN CAMBIO 
	IF (@Actualizar = 1)
	BEGIN

    -------------------------------------------------------------------------------------------------------------------------------------
    ----------------- --AGRUPO LA PROGRAMACION Y MANDO UNA COPIA A LA TABLA FISICA A L ATABLA TEMPORAL DE ITEMS.----------------------------------------
    -----------------------------------------------------------------------------------------------------------------------------------------
		
	INSERT INTO PLANNING_PRG_TEMP_ITEM
		EXECUTE AGRUPAR_PROGRAMACION @prm_PROGRAMACIONID


    -----------------------------------------------------------------------------------------------------------------------------------------
    ----------- VOY RECORRIENDO LAS ORDENES Y ACTUALIZANDO LA VELOCIDAD A LAS MAQUIANS ------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------------------------

		if ((select count(*) from PLANNING_PRG_TEMP_ITEM) > 0)
		begin
			
			
			Declare @Item smallint, @Orden nvarchar(30), @Libras Decimal(12,4), @LibrasXhora Decimal(12,2)

			DECLARE  crs_Temp_Itemns CURSOR FOR 
			SELECT Item, Orden, Libras, LibrasXhora  FROM  PLANNING_PRG_TEMP_ITEM ORDER BY Item

			OPEN crs_Temp_Itemns 

			FETCH NEXT FROM  crs_Temp_Itemns   INTO @Item, @Orden, @Libras, @LibrasXhora

			WHILE (@@FETCH_STATUS=0)
			BEGIN
				if (@Orden is not null)
				begin
					SELECT @Run = RUN FROM VMFGPN.DBO.OPERATION WHERE WORKORDER_BASE_ID= @Orden AND RUN > 0
					IF(NOT(@Run=@LibrasXhora))
					begin
						Set @Actualizar = 1	

						UPDATE PLANNING_PRG_TEMP_ITEM SET HorasTrabajo = (@Libras/@Run), LibrasXhora = @Run, Tot_HrsOrden= (@Libras/@Run)
						WHERE Item = @Item

					end
				end
			FETCH NEXT FROM  crs_Temp_Itemns   INTO @Item, @Orden, @Libras, @LibrasXhora 
			END
			CLOSE crs_Temp_Itemns
			DEALLOCATE crs_Temp_Itemns

			
			------------------------------------------------------------------------------------------------------------------------------
			----------- PREPARO LOS ITEMS, OBTENGO LOS PARARAMETROS NECESARIOS PARA LA RE-PROGRAMACION------------------------------------
            ------------------------------------------------------------------------------------------------------------------------------
			Declare @Maquina nvarchar(20), @FechaInicio date, @HoraInicio Time, @HorarioTrabajoID varchar(50), @CreadoPor varchar(30)
					    
			Select @Maquina=MaquinaID, @FechaInicio=FechaItem, @HoraInicio=cast(TInicio as Time), @HorarioTrabajoID= Horario_TrabajoID
			FROM PLANNING_PRG_TEMP_ITEM WHERE Item=1

			UPDATE PLANNING_PRG_TEMP_ITEM SET Turno = NULL, TInicio = NULL, TFinal= NULL

			--ELIMINO LA PROGRAMACION ORIGINAL
			DELETE FROM PLANNING_PROGRAMACION WHERE ProgramacionID=@prm_PROGRAMACIONID
			
			--MANDO A REPROGRAMAR LOS ITEMS EN LA TABLA TEMPORAL 
			EXECUTE PROGRAMADOR_WORK_ORDER @Maquina, @FechaInicio, @HoraInicio, @prm_PROGRAMACIONID, 0, @HorarioTrabajoID, 'REPROGRAMACION', @CreadoPor 

		END
			
	END

	Return @Actualizar
END
 
GO