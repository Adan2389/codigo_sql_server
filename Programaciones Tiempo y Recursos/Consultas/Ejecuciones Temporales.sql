DELETE FROM PLANNING_PROGRAMACION 
DELETE FROM PLANNING_PRG_TEMP_ITEM
DELETE FROM PLANNING_PRG_TEMP_ORDER


SELECT  * FROM PLANNING_PROGRAMACION WHERE ProgramacionID = '2__PRUEBA 08 '
ORDER BY ITEM


SELECT Item, Orden, fechaItem, Descripcion, LibrasXHora, Turno, 
		Round(((Libras) - (((HorasTrabajo/Tot_HrsOrden)*(TSeteo))*(LibrasXhora))),2) as Libras, 
TotalMetros, TSeteo, HorasTrabajo, Tot_HrsOrden, Item_Order_line, TipoTiempo, TInicio, TFinal, Estado, FechaReprog  
FROM PLANNING_PROGRAMACION 
ORDER BY ITEM


SELECT Item, Orden, fechaItem, Descripcion, Turno, Libras, TotalMetros, HorasTrabajo, Item_Order_line, TipoTiempo, TInicio, TFinal, Estado, FechaReprog  
FROM PLANNING_PRG_TEMP_ITEM 
ORDER BY ITEM



SELECT * FROM PLANNING_PRG_TEMP_ORDER 
SELECT * FROM  PLANNING_PRG_TEMP_ITEM order by item
SELECT * FROM HORARIOS_TRABAJO  WHERE Horario_TrabajoID= 'ABC-RECESOS'


	--INSERTA UN TIEMPO
	EXECUTE  INSERT_TIEMPO '09-02-2018', '14:00', 1.0, 2, 2, 'Mantenimiento de E-02', '1__Prueba', 'Esta es una Prueba'


	--PROGRAMA Y REPROGRAMA
	execute PROGRAMADOR_WORK_ORDER 'E-02', '09-02-2018', '14:00', '1__Prueba',0, 'ABCD-[8,7,9]', 'REPROGRAMACION', 'ADAN ORDOÑEZ' 

	
	--ELIMINA UN TIEMPO
	DECLARE @Fecha_Inicio Date
	DECLARE @Hora_Inicio time

	EXECUTE DELETE_TIEMPO 'prueba', 'OPR-04275-18',  @Fecha_Retonada = @Fecha_Inicio output , @Hora_Retornada=@Hora_Inicio output   

	print 'FECHA_INICIO ' + CAST(@Fecha_Inicio AS VARCHAR(20))
	PRINT 'HORA_INICIO ' + CAST(@Hora_Inicio AS VARCHAR(05))








		--INSERTA UN TIEMPO
	EXECUTE  INSERT_TIEMPO '25-01-2018', '21:00', 4.0, 2, 1, 'Mantenimiento de E-01', 'E-02 25-01-2018  (View Report', 'Prueba'
	execute PROGRAMADOR_WORK_ORDER 'E-02', '25-01-2018', '21:00', 'E-02 25-01-2018  (View Report)',1, 'ABC-RECESOS', 'REPROGRAMACION', 'ADAN ORDOÑEZ' 

	--INSERTA UN TIEMPO
	EXECUTE  INSERT_TIEMPO '26-01-2018', '10:00', 2.0, 3, 1, 'Paro Por Energia', 'E-02 25-01-2018  (View Report)', 'Prueba'
	execute PROGRAMADOR_WORK_ORDER 'E-02', '26-01-2018', '10:00', 'E-02 25-01-2018  (View Report)',1, 'ABC-RECESOS', 'REPROGRAMACION', 'ADAN ORDOÑEZ' 

	--INSERTA UN TIEMPO
	EXECUTE  INSERT_TIEMPO '26-01-2018', '14:00', 5.0, 2, 1, 'Mantenimiento de E-01', 'E-02 25-01-2018  (View Report)', 'Prueba'
	execute PROGRAMADOR_WORK_ORDER 'E-02', '26-01-2018', '14:00', 'E-02 25-01-2018  (View Report)',1, 'ABC-RECESOS', 'REPROGRAMACION', 'ADAN ORDOÑEZ'



	


