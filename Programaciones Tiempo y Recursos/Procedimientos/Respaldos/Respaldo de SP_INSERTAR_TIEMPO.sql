USE [APP_SISTEMAS]
GO
/****** Object:  StoredProcedure [dbo].[INSERT_TIEMPO]    Script Date: 24/01/2018 02:11:01 p.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[INSERT_TIEMPO]
(
	@prm_FECHA DATE,
	@prm_HORA TIME,
	@prm_ADD_HRS decimal(12,2),
	@prm_TipoItem smallint,
	@prm_TipoHorario smallint,
	@prm_DESCRIPCION varchar(350),
	@prm_PROGRAMACIONID VARCHAR(100)

)
as 
BEGIN
	
	--DECLARE @prm_FECHA DATE ='24-01-2017'
	--DECLARE @prm_HORA TIME = '01:15'	
	--DECLARE @prm_ADD_HRS decimal(12,2) = 0.75
	--DECLARE @prm_DESCRIPCION varchar(350) = 'TIEMPO DE ALMUERZO'
	--DECLARE @prm_PROGRAMACIONID VARCHAR(100) = 'OOOUNDA2121REsdsd8412'

	
	
	--Cargo la Programacion en la Tabla Fisica-Temporal 
	DELETE FROM PLANNING_PRG_TEMP_ITEM

	INSERT INTO PLANNING_PRG_TEMP_ITEM
		SELECT * FROM PLANNING_PROGRAMACION WHERE ProgramacionID = @prm_PROGRAMACIONID
	
	
	DECLARE @ORDERNAR BIT =0			--Permite decidir el momento en que va reordenar los items
	DECLARE @NEWITEM smallint = null	--Obtiene el nuevo numero de intem en la reordenacion
	DECLARE @prm_FECHA_HORA_BUSCADA DATETIME = convert(varchar(12), @prm_FECHA,103 ) +' '+ cast(@prm_HORA as varchar(10))


	DECLARE @ITEM smallint, @DESCRIPCION varchar(300), @TIPOHORARIO smallint, @TURNO varchar(2), @LIBRAS decimal(12,2), @HORASTRABAJO decimal(12,2), @TINICIO datetime, @TFINAL datetime

	DECLARE crsProgramacion cursor for 
		SELECT  ITEM, DESCRIPCION, TIPOHORARIO, TURNO, LIBRAS, HORASTRABAJO, TINICIO, TFINAL FROM PLANNING_PRG_TEMP_ITEM ORDER BY ITEM

	OPEN crsProgramacion


	FETCH NEXT FROM crsProgramacion INTO @ITEM, @DESCRIPCION, @TIPOHORARIO, @TURNO, @LIBRAS, @HORASTRABAJO, @TINICIO, @TFINAL
	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		IF (NOT @ORDERNAR = 1)
		BEGIN
			IF (@prm_FECHA_HORA_BUSCADA  BETWEEN  @TINICIO  AND @TFINAL )
			BEGIN
				--------------------------------Cuando eL Tiempo que se va insertar comienza al inicio del primer Item del cursor--------------------------
				IF (@prm_FECHA_HORA_BUSCADA = @TINICIO )
				BEGIN
					SET @ORDERNAR = 1
					SET @NEWITEM = 1
					INSERT INTO  PLANNING_PRG_TEMP_ITEM ( ITEM, HorasTrabajo, TInicio, TFinal, Turno, Descripcion)
					VALUES (@NEWITEM, @prm_ADD_HRS, @prm_FECHA_HORA_BUSCADA, NULL, NULL, @prm_DESCRIPCION  )

					SET @NEWITEM = @NEWITEM + 1
					UPDATE PLANNING_PRG_TEMP_ITEM SET ITEM =@NEWITEM,  TInicio=NULL, TFinal= NULL, Turno= NULL
					WHERE PROGRAMACIONID = @prm_PROGRAMACIONID  AND TINICIO=@TINICIO AND  TFINAL=@TFINAL
				END
				  ELSE
				BEGIN
					-------------------------Cuando eL Tiempo que se va insertar comienza al final  del rango de horas del Item-----------------------------
					IF (@prm_FECHA_HORA_BUSCADA = @TFINAL )
					BEGIN
						SET @ORDERNAR = 1
						SET @NEWITEM = @ITEM + 1
						INSERT INTO  PLANNING_PRG_TEMP_ITEM ( ITEM, HorasTrabajo, TInicio, TFinal, Turno, Descripcion)
						VALUES (@NEWITEM, @prm_ADD_HRS, @prm_FECHA_HORA_BUSCADA, NULL, NULL, @prm_DESCRIPCION  )
					END
					  ELSE
					BEGIN
						-----------------------Cuando eL Tiempo que se va insertar comienza  en medio del rango de horas del Item --------------------------
					
						Declare @Mod_Libras decimal(12,2), @Mod_Horas decimal(12,2)
						Select @Mod_Horas = (DATEDIFF(MINUTE,@TINICIO,@prm_FECHA_HORA_BUSCADA) /60.00)
						SET @Mod_Libras = (@LIBRAS/@HORASTRABAJO) * @Mod_Horas

						UPDATE PLANNING_PRG_TEMP_ITEM SET  TFinal=@prm_FECHA_HORA_BUSCADA, Libras= @Mod_Libras,  HorasTrabajo=@Mod_Horas
						WHERE PROGRAMACIONID = @prm_PROGRAMACIONID  AND ITEM =@ITEM

						SET @ORDERNAR = 1
						SET @NEWITEM = @ITEM + 1
						INSERT INTO  PLANNING_PRG_TEMP_ITEM ( ITEM, HorasTrabajo, TInicio, TFinal, Turno, Descripcion)
						VALUES (@NEWITEM, @prm_ADD_HRS, @prm_FECHA_HORA_BUSCADA, NULL, NULL, @prm_DESCRIPCION  )

						SET @NEWITEM = @NEWITEM + 1
						INSERT INTO  PLANNING_PRG_TEMP_ITEM ( ITEM, Descripcion, Turno, Libras, HorasTrabajo, TInicio, TFinal)
						VALUES (@NEWITEM, @DESCRIPCION, NULL, (@LIBRAS-@Mod_Libras), (@HORASTRABAJO-@Mod_Horas), NULL, NULL)
					END
				END
			END
		END

		ELSE

		BEGIN
			--CONTINUO ORDENANDO LOS DEMAS ITEMS, ANULANDO LOS TURNOS, ANULANDO LAS FECHAS
			SET @NEWITEM = @NEWITEM + 1
			UPDATE PLANNING_PRG_TEMP_ITEM SET ITEM =@NEWITEM,  TInicio=NULL, TFinal= NULL, Turno= NULL
			WHERE PROGRAMACIONID = @prm_PROGRAMACIONID  AND TINICIO=@TINICIO AND  TFINAL=@TFINAL
		END

		FETCH NEXT FROM crsProgramacion INTO @ITEM, @DESCRIPCION, @TIPOHORARIO, @TURNO, @LIBRAS, @HORASTRABAJO, @TINICIO, @TFINAL
	END
	CLOSE crsProgramacion
	DEALLOCATE crsProgramacion

	DELETE FROM PLANNING_PROGRAMACION WHERE ProgramacionID=@prm_PROGRAMACIONID

	INSERT INTO PLANNING_PROGRAMACION
		SELECT * FROM  PLANNING_PRG_TEMP_ITEM


END 
