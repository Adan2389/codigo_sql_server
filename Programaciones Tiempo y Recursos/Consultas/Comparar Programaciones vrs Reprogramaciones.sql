


Select ProgramacionID, FechaItem, Orden, DESCRIPCION, Turno, SUM(Libras)AS lIBRAS, SUM(HorasTrabajo)AS HorasTrabajo, min(TInicio) as TInicio, max(TFinal) as TFinal,
		CONVERT(CHAR(5),Cast(min(TInicio) as time),9) +  RIGHT(CONVERT(VARCHAR(50), min(TInicio), 9), 2) as FInicio, 
		CONVERT(CHAR(5),Cast(max(TFinal) as time),9) +  RIGHT(CONVERT(VARCHAR(50), max(TFinal), 9), 2) as  FFinal 
from PLANNING_PROGRAMACION 
GROUP BY ProgramacionID, FechaItem, Orden, Turno,DESCRIPCION 
ORDER BY FechaItem, Turno


Select ProgramacionID, Item, FechaItem, Orden, DESCRIPCION, Turno, Libras, HorasTrabajo, TInicio, TFinal, 
	  CONVERT(CHAR(5),Cast(TInicio as time),9) +  RIGHT(CONVERT(VARCHAR(50), TInicio, 9), 2) as FInicio, 
	  CONVERT(CHAR(5),Cast(TFinal as time),9) +  RIGHT(CONVERT(VARCHAR(50), TFinal, 9), 2) as  FFinal 
from PLANNING_PROGRAMACION 
ORDER BY Item


Select ProgramacionID, Item, FechaItem, Orden, DESCRIPCION, Turno, Libras, HorasTrabajo, TInicio, TFinal, 
CONVERT(CHAR(5),Cast(TInicio as time),9) +  RIGHT(CONVERT(VARCHAR(50), TInicio, 9), 2) as FInicio, 
	  CONVERT(CHAR(5),Cast(TFinal as time),9) +  RIGHT(CONVERT(VARCHAR(50), TFinal, 9), 2) as  FFinal 
from PLANNING_PRG_TEMP_ITEM ORDER BY Item
