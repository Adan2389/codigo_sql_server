
--ESTA  FUNCION HACE LA CONVERVION DE LOS TURNOS DE ACUERDO COMO LO MANEJAN 
--LOS JEFES DE PLANEACION. 
--ESTA CONVERSION SOLAMENTE ES UNA VISTA DE USUARIO EL VERDADEO TURNO SE MANEJAN EN ORDEN LOGICO (A,B,C,D) (A,C,D)


CREATE FUNCTION TURNO_VIEW (@HORARIO_TRABAJOID varchar(50), @TURNO Varchar(2) ) returns varchar(2)  
as 
BEGIN
	
	DECLARE @Turno_View varchar(2) =null

	IF (@HORARIO_TRABAJOID IN ('ABCD-[8,7,9]', 'ABCD-[8,7,9]RECS'))
	BEGIN
		IF (@TURNO= 'A')
			Set @Turno_View='C'
		IF (@TURNO= 'B')
			Set @Turno_View='A'
		IF (@TURNO= 'C')
			Set @Turno_View='B'
		IF (@TURNO= 'D')
			Set @Turno_View='C'
	END

	IF (@HORARIO_TRABAJOID IN ('ACD-[12,12]', 'ACD-[12,12]RECS'))
	BEGIN
		IF (@TURNO= 'A')
			Set @Turno_View='C'
		IF (@TURNO= 'C')
			Set @Turno_View='A'
		IF (@TURNO= 'D')
			Set @Turno_View='C'
	END


	RETURN ISNULL(@Turno_View,'-1')
END

GO 



