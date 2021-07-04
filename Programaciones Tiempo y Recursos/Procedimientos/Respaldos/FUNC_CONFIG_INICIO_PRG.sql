

ALTER FUNCTION CONFIG_INICIO_PRG (@Hora time) returns @Consulta TABLE 
(
	HrInicioTurno decimal(12,2),
	HrInicioDia decimal(12,2),
	TotalHrsTurno decimal(12,2),
	Turno char(2)
)
as 
BEGIN

	Declare @HoraInicio datetime
	DECLARE @HoraFinal datetime


	Declare @i int  = 0
	Declare @Turno char(2)
	Declare @HrInicioDia decimal(12,2)=0.0
	Declare @HrInicioTurno decimal(12,2) = 0.0
	Declare @TotalHrsTurno decimal(12,2) = 0.0



	--Defino la Hora de Inicio y Final en un rango de 24 Hrs	
	if (@Hora <'06:00')
	begin
		Set @HoraInicio = '01/01/1900 ' +  '06:00'
		Set @HoraFinal = '02/01/1900 ' + cast(@Hora as varchar(10))
	end
	else
	begin
		Set @HoraInicio = '01/01/1900 ' +  '06:00'
		Set @HoraFinal  = '01/01/1900 ' + cast(@Hora as varchar(10))
	end


	--Obtengo la diferencia en minutos
	Select @i = datediff(MINUTE, @HoraInicio, @HoraFinal)

	
	----Obtengo el Turno
	select @Turno= (CASE  when (@Hora >='06:00' and @Hora <='13:59') then 'A' 
						  when (@Hora >='14:00' and @Hora <='20:59') then 'B'
						  when (@Hora >='21:00' and @Hora <='23:59') OR (@Hora >='00:00' and @Hora <='05:59') then 'C'
					end)
	
	--Calculo la hora inicio del Dia
	Set @HrInicioDia = round(((@i/60.00)*100.00),0)

	---Asigno el Total de Horas segun el turno
	select @TotalHrsTurno= (CASE when @Turno ='A' then 800.0 when @Turno ='B' then 700.00  when @Turno ='C' then 900.00	end)
	
	--Obtengo la Hora de inicio del Turno 
	Select  @HrInicioTurno = (CASE WHEN @TotalHrsTurno=800 THEN (@HrInicioDia)
								 WHEN @TotalHrsTurno=700 THEN (@HrInicioDia-800)
								 WHEN @TotalHrsTurno=900 THEN (@HrInicioDia-1500)
						      END )

		
	Insert into @Consulta
		Values (@HrInicioTurno, @HrInicioDia, @TotalHrsTurno, @Turno )
	
	RETURN
END
GO 

