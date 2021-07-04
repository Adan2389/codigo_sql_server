



select SUM(LIBRAS)AS Libras, Sum(TOT_HRSTRABAJO) AS HRS  from PLANNING_PRG_TEMP_ORDER

SELECT SUM(Libras) as Libras, Sum(HorasTrabajo) as Hrs from PLANNING_PROGRAMACION 

Select ProgramacionID, Item, FechaItem, Orden, Turno, Libras, HorasTrabajo, TInicio, TFinal, 
CONVERT(CHAR(5),Cast(TInicio as time),9) +  RIGHT(CONVERT(VARCHAR(50), TInicio, 9), 2) as FInicio, 
	  CONVERT(CHAR(5),Cast(TFinal as time),9) +  RIGHT(CONVERT(VARCHAR(50), TFinal, 9), 2) as  FFinal 
from PLANNING_PROGRAMACION 

Select Orden, SUM(Libras) AS Libras, sum(HorasTrabajo)as Hrs from PLANNING_PROGRAMACION GROUP BY Orden


