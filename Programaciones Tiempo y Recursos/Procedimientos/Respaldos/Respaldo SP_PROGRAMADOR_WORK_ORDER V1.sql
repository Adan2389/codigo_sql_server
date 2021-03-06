USE [APP_SISTEMAS]
GO
/****** Object:  StoredProcedure [dbo].[SP_Programacion_ABC]    Script Date: 24/01/2018 07:59:29 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Programacion_ABC]
(
	@prm_Maquina nvarchar(20) , 
	@prm_FechaInicioPrg date,
	@prm_HoraInicio time,
	@prm_ProgramacionID nvarchar(50),
	@prm_IncluirDomingos bit,
	@prm_HoraCambioFecha time = '06:00', 
	@prm_TipoTurno varchar(10)='ABC',
	@prm_Accion varchar(20)='PROGRAMACION'
	
)
AS

	--DECLARE @prm_Maquina nvarchar(20) = 'E-02' 
	--DECLARE @prm_FechaInicioPrg date = '22/01/2018'
	--DECLARE @prm_HoraInicio time = '10:30'
	--DECLARE @prm_ProgramacionID nvarchar(50) = ' REPROG. PRU_E-02_86.35 HRS 3.6 DIAS'
	--DECLARE @prm_IncluirDomingos bit = 0
	--DECLARE @prm_HoraCorte time = '06:00' 

	


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
--DECLARE @H_Inicio time							--Para ir calculando y mostrando la hora de inicio del item de la Programacion
--DECLARE @H_Final time							--Para ir calculando y mostrando la hora de Final del item de la Programacion



---VARIABLES DEL CURSOR 
DECLARE @FechaCreado date, @NumOrder smallint, @OrdenTrabajo nvarchar(100), @CodProducto nvarchar(50), @NomProducto nvarchar(200), @Maquina nvarchar(20),
		 @TotalLibras Decimal(12,2), @Ancho varchar(50), @Espesor varchar(50), @PesoMetro float, @LibrasxHora decimal(6,2), @TotalHrsOrden decimal(6,2)  

--CURSOR PARA RECORRER LAS ORDENES DE TRABAJO
Declare crsWorkOrder CURSOR for SELECT  F_CREADA, NUMORDER, BASE_ID, PART_ID, DESC_PART_ID, MAQUINA, LIBRAS, Ancho, Espesor, Peso_Metro,
								   LibrasXHora, TOT_HRSTRABAJO 
								FROM PLANNING_PRG_TEMP_ORDER 
								ORDER BY NUMORDER ASC
								

								/*
								SELECT FechaCreado, NumOrder,  Orden, Part_id, (select Description from VMFGPN.DBO.PART WHERE ID=a.Part_id) as Part_ID, MaquinaID, lIBRAS, Ancho, 
										Espesor, PesoMetro, LibrasXHora, HorasTrabajo 
								FROM PLANNING_PRG_TEMP_ITEM AS a
								ORDER BY Item ASC
								*/
								
								 

--TABLA TEMPORAL PARA GUARDAR LA PROGRAMACION
CREATE TABLE ##Temp_Programacion(
	ProgramacionID varchar(50),
	Item smallint,
	Fecha date,
	NumOrder smallint,
	Orden nvarchar(30),
	Turno varchar(2),
	Part_id nvarchar(15),
	Libras Decimal(12,4),
	Ancho varchar(50),
	Espesor varchar(50),
	PesoMetro float,
	TotalMetros Decimal(12,2),
	MetrosMetaMin Decimal(8,2),
	LibrasXhora Decimal(8,2),
	HorasTrabajo Decimal(4,2),
	TInicio datetime,
	TFinal datetime
	--HrInicio varchar(10),
	--HrFinal varchar(10)	
)

--INICIALIZO VALORES PREDETERMINADOS ANTES DE QUE EMPIECE EL CURSOR Y UTILIZO LA FUNCION DE CONFIGURACION DE INICIO
	Set @TotalDiaHrs =  2400.00
 --	SET @H_Inicio  =@prm_HoraInicio     
	--SET @H_Final  = null				 
	SET @FechaPrg = @prm_FechaInicioPrg
	SET @i_Item = 0
	Set @AcumDias = 0

Select  @TotalTurnoHrs = TotalHrsTurno,
	    @AcumAsingTurnoHrs = HrInicioTurno,
		@AcumAsingDiaHrs = HrInicioDia,
		@Turno = Turno
from dbo.CONFIG_INICIO_PRG(@prm_HoraInicio)
	

OPEN crsWorkOrder
FETCH NEXT FROM crsWorkOrder INTO @FechaCreado, @NumOrder, @OrdenTrabajo, @CodProducto, @NomProducto, @Maquina,  
								  @TotalLibras, @Ancho, @Espesor, @PesoMetro, @LibrasxHora, @TotalHrsOrden
WHILE (@@FETCH_STATUS = 0)
BEGIN

	Set @AsingOrdenHrs = 0.00
	Set @i	= 1.0
	
	WHILE (@i <= (@TotalHrsOrden * 100) )
	BEGIN
			
		--SE VAN IDENTIFICANDO LOS TURNOS Y ASIGNANDO LAS HORAS DE LA ORDEN A LA PROGRAMACION
		--CADA VEZ QUE LAS HORAS ASIGNADAS DE UN TURNO SEAN IGUALES A LOS HORAS TOTALES
		--SE IDENTIFICA EL TURNO EN EL VALOR DE LA SECUENCIA DE LAS HORAS DEL DIA (2400)
		if (@AcumAsingTurnoHrs = @TotalTurnoHrs)
		begin
	
			If (@AcumAsingDiaHrs = 800)
			begin
				SET @Turno = 'A'
				SET @TotalTurnoHrs = 700 -- total de horas que se deben acumular para el siguiente turno 
			end

			If (@AcumAsingDiaHrs = 1500)
			begin
				SET @Turno = 'B'
				SET @TotalTurnoHrs = 900 -- total de horas que se deben acumular para el siguiente turno 
			end

			If (@AcumAsingDiaHrs = 2400)
			begin
				SET @Turno = 'C'
				SET @TotalTurnoHrs = 800 -- asigno el total de horas que se deben acumular para el siguiente turno
			end	
						
				
			-----------------------GUARDO EL REGISTRO  TEMPORALMENTE Y ENUMERO EL ITEM DE LA PROGRAMACION-----------------------
			SET @i_Item = @i_Item + 1

			INSERT INTO ##Temp_Programacion (ProgramacionID, Item, Fecha, NumOrder, Orden, Turno, Part_id, Libras, Ancho, Espesor, PesoMetro, TotalMetros, 
											 MetrosMetaMin, LibrasXhora, HorasTrabajo, TInicio, TFinal)
											 VALUES ( @prm_ProgramacionID, @i_Item, DATEADD(DAY,@AcumDias,@FechaPrg), @NUMORDER, @OrdenTrabajo, (@Turno),
													   (@CodProducto), ((@AsingOrdenHrs/100.00) * @LibrasxHora),
													   @Ancho, @Espesor, @PesoMetro, (((@AsingOrdenHrs/100.00) * @LibrasxHora)/@PesoMetro),
													   ((@LibrasxHora/@PesoMetro)/60), @LibrasxHora, (@AsingOrdenHrs/100.00),
													   DATEADD(MINUTE,(((@AcumAsingDiaHrs - @AsingOrdenHrs) /100.00)*60), CAST((convert(varchar(12), DATEADD(DAY,@AcumDias,@FechaPrg),103 ) +' '+ '06:00')AS DATETIME)), 													   
													   DATEADD(MINUTE,((@AcumAsingDiaHrs/100.00)*60), CAST((convert(varchar(12), DATEADD(DAY,@AcumDias,@FechaPrg),103 ) +' '+ '06:00')AS DATETIME))
				  
											 )

			------------------------------INCIALIZO PARA ACUMULAR PARA OTRO TURNO Y PARA OTRO ITEM ----------------------------
			Set @AcumAsingTurnoHrs = 0
			Set @AsingOrdenHrs = 0
		end
	
		-----------------------------VA AVANZANDO DE DIA DIA APARTIR DE LA FECHA DE INICIO DE LA PROGRAMACION,-------------------
		if (@AcumAsingDiaHrs = @TotalDiaHrs)
		begin
			--Agrego un dia al contador
			Set @AcumDias = @AcumDias +1 
			
			--Verifico si NO se va a trabajar los domingos para Saltarlos!
			IF (@prm_IncluirDomingos = 0)
			begin
				IF ( (SELECT DATEPART(DW,DATEADD(DAY,@AcumDias,@FechaPrg)))=7 )
				begin
					Set @AcumDias = @AcumDias +1 
				end
			end
			--Vulo a cero para acumular para otro dia
			Set @AcumAsingDiaHrs = 0
		end
		---------------------VOY ACUMULANDO LAS HORAS ASIGNADAS AL TURNO, AL DIA, ITEM Y LA ORDEN---------------------------
		Set @AcumAsingDiaHrs = @AcumAsingDiaHrs + 1      
		set @AcumAsingTurnoHrs = @AcumAsingTurnoHrs + 1  
		Set @AsingOrdenHrs = @AsingOrdenHrs + 1			 
		Set @i = @i + 1.0
		
	END--FIN DEL CILCLO DE HRS
	

	--AL FINAL DE RECORRER EL TIEMPO DE TRABAJO DE CADA ORDEN,  VERIFICO SI LAS HORAS SOBRANTES NO COMPLETAN UN TURNO
	--PARA PODER GUARDAR EL REGISTRO EN LA PROGRAMACION CON LAS HORAS QUE SOBRAN PARA PODER TERMINNAR LA ORDEN,
	if (@AcumAsingTurnoHrs < @TotalTurnoHrs )
	begin
		

		--VERIFICO A QUE TURNO SE ASIGNARAN LAS HORAS RESTANTES PARA COMPLETAR LA ORDEN
		If ( @AcumAsingDiaHrs > 0 and @AcumAsingDiaHrs < 800 )
			SET @Turno = 'A'
			
		If (@AcumAsingDiaHrs >= 800 and  @AcumAsingDiaHrs < 1500 )
			SET @Turno = 'B'
			
		If ( @AcumAsingDiaHrs >= 1500 and @AcumAsingDiaHrs <= 2400)
			SET @Turno = 'C'
	

		--GUARDO EL REGISTRO 
		SET @i_Item = @i_Item + 1
		INSERT INTO ##Temp_Programacion (ProgramacionID, Item, Fecha, NumOrder, Orden, Turno, Part_id, Libras, Ancho, Espesor, PesoMetro, TotalMetros, 
											 MetrosMetaMin, LibrasXhora, HorasTrabajo, TInicio, TFinal)
											 VALUES ( @prm_ProgramacionID, @i_Item, DATEADD(DAY,@AcumDias,@FechaPrg), @NUMORDER, @OrdenTrabajo, @Turno,
													   @CodProducto, ((@AsingOrdenHrs/100.00) * @LibrasxHora),
													   @Ancho, @Espesor, @PesoMetro, (((@AsingOrdenHrs/100.00) * @LibrasxHora)/@PesoMetro),
													   ((@LibrasxHora/@PesoMetro)/60), @LibrasxHora, (@AsingOrdenHrs/100.00),
													   DATEADD(MINUTE,(((@AcumAsingDiaHrs - @AsingOrdenHrs) /100.00)*60), CAST((convert(varchar(12), DATEADD(DAY,@AcumDias,@FechaPrg),103 ) +' '+ '06:00')AS DATETIME)), 
													   DATEADD(MINUTE,((@AcumAsingDiaHrs/100.00)*60), CAST((convert(varchar(12), DATEADD(DAY,@AcumDias,@FechaPrg),103 ) +' '+ '06:00')AS DATETIME))
										  
											 )
	
	end
	--------------------------------------------------------------------------------------------------------------------------------------------
			
FETCH NEXT FROM crsWorkOrder INTO @FechaCreado, @NumOrder,  @OrdenTrabajo, @CodProducto, @NomProducto, @Maquina,  
								@TotalLibras, @Ancho, @Espesor, @PesoMetro, @LibrasxHora, @TotalHrsOrden
END
CLOSE crsWorkOrder
DEALLOCATE crsWorkOrder


--GUARDO EN LA TABLA FISICA
INSERT INTO APP_SISTEMAS.DBO.PLANNING_PROGRAMACION

SELECT 	''+@prm_ProgramacionID+'',
		''+@prm_Maquina+'',
		'APP_SISTEMAS',
		GETDATE(),
		Item,
		NULL, --ESTADO
		1, --TipoItem 
		Orden, --Descripcion
		Fecha, 
		Orden, 
		NumOrder, 
		Turno, 
		'ABC',  
		1,		--Tipo Horario (1-Variable 2-Fijo)
		Part_id, 
		null, --Co_Producto
		Libras, 
		Ancho,
		NULL, --Largo 
		Espesor, 
		PesoMetro, 
		TotalMetros,
		NULL, --Colores
		NULL, --Rodillo
		NULL, --NoPistas
		NULL, --FardosXhora
		NULL, --HorasCambio
		MetrosMetaMin,
		NULL, --Tseteo
		NULL, --PorDesperdicio
		NULL, --Desperdicio
	    LibrasXhora, 
		HorasTrabajo, 
		TInicio,
		TFinal,
		'Item Programado Automaticamente desde SQL SERVER MODO DE PRUEBA'  
FROM ##Temp_Programacion

DELETE FROM PLANNING_PRG_TEMP_ORDER

----DEVULVO LOS RESULTADOS POR LA EJECUCION DEL PROCEDIMIENTO
--SELECT 	Item, CONVERT(VARCHAR(10), fecha, 103)as  Fecha, Orden, LTRIM(RTRIM(Turno))AS Turno, Part_id, Libras, Ancho, Espesor, PesoMetro, TotalMetros, MetrosMetaMin AS MetrosXMin,
--	   LibrasXhora as LbsXhr, HorasTrabajo as HrsTrabajo, TInicio, TFinal,
--	   CONVERT(CHAR(5),Cast(TInicio as time),9) +  RIGHT(CONVERT(VARCHAR(50), TInicio, 9), 2) as TInicio, 
--	  CONVERT(CHAR(5),Cast(TFinal as time),9) +  RIGHT(CONVERT(VARCHAR(50), TFinal, 9), 2) as  TFinal 
--FROM ##Temp_Programacion

DROP TABLE ##Temp_Programacion

