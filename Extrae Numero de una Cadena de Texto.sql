--Con esta funcion extraemos el numero dentro una cadena de texto
CREATE FUNCTION dbo.EXTRACT_YEAR(@periodo AS VARCHAR(max))
RETURNS INT
AS
BEGIN

WHILE PATINDEX('%[^0-9]%', @periodo) > 0
 BEGIN
  SET @periodo = REPLACE(@periodo,SUBSTRING(@periodo,PATINDEX('%[^0-9]%', @periodo),1),'')
 END

 RETURN LEFT(@periodo, 4)
END
SELECT dbo.EXTRACT_YEAR('(489 mm)')