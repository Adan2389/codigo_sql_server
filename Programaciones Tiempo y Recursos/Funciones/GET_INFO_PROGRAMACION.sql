
--ESTA FUNCION TABLAR DEVULVE INFORMACION GENERAL DE UNA PROGRAMACION 

ALTER FUNCTION GET_INFO_PROGRAMACION ( @ProgramacionID varchar(100) ) returns @Consulta table
(
	ProgramacionID varchar(100),
	MaquinaID varchar(20),
	CreadoPor varchar(30),
	TInicio datetime,
	TFinal datetime,
	TotHrsProduccion decimal(12,2),
	TotHrsOtros decimal(12,2),
	TotHrsRecesos decimal(12,2),
	TotLibras decimal(12,2),
	Dias decimal(6,2),
	TotHoras decimal(12,2) 
)
as 
BEGIN
	INSERT INTO @Consulta

	SELECT *, ROUND((datediff(HOUR,TInicio,TFinal )/24.00),2)as Dias, 
			  (ISNULL(TotHrsProduccion,0.0)+ISNULL(TotHrsOtros,0.0)+ISNULL(TotHrsRecesos,0.0))as TotHoras
	FROM(
		SELECT TOP 1 ProgramacionID, MaquinaID, CreadoPor, 
			   (Select min(TInicio) FROM PLANNING_PROGRAMACION where ProgramacionID=a.ProgramacionID )AS TInicio,
			   (Select max(TFinal) FROM PLANNING_PROGRAMACION where ProgramacionID=a.ProgramacionID )AS TFinal,
			   (Select sum(HorasTrabajo) FROM PLANNING_PROGRAMACION where ProgramacionID=a.ProgramacionID  and TipoItem=1 and TipoTiempo=1)AS TotHrsProduccion,
			   (Select sum(HorasTrabajo) FROM PLANNING_PROGRAMACION where ProgramacionID=a.ProgramacionID  and not TipoItem=1)AS TotHrsOtros,
			   (Select sum(HorasTrabajo) FROM PLANNING_PROGRAMACION where ProgramacionID=a.ProgramacionID  and TipoItem=1 and TipoTiempo=2)AS TotHrsRecesos,
			   --(Select sum(Libras) FROM PLANNING_PROGRAMACION where ProgramacionID=a.ProgramacionID )AS TotLibras

			   (
			   SELECT SUM(LibrasX) 
			   FROM (
			   SELECT Round(((Libras) - (((HorasTrabajo/Tot_HrsOrden)*(TSeteo))*(LibrasXhora))),2) as LibrasX
			   FROM PLANNING_PROGRAMACION WHERE ProgramacionID= @ProgramacionID 
			   )AS C1
			   )AS TotLibras


		FROM PLANNING_PROGRAMACION  AS a
		WHERE ProgramacionID= @ProgramacionID 
	)AS CF

	RETURN 
END

GO 



