
SELECT TABLE_CATALOG AS BASE_DATOS,  TABLE_NAME AS TABLA, COLUMN_NAME AS CAMPO, DATA_TYPE AS TIPO,
		CASE WHEN DATA_TYPE  in ('int', 'decimal') then NUMERIC_PRECISION 
			 WHEN DATA_TYPE  in ('varchar') then CHARACTER_MAXIMUM_LENGTH
			 ELSE NULL
		END AS TAMANIO
FROM Information_Schema.Columns
WHERE TABLE_CATALOG = 'APP_SISTEMAS' --AND LEFT(TABLE_NAME,5) = 'SIQM_'  OR TABLE_NAME = 'GENERAL_USUARIOS'
ORDER BY TABLE_NAME DESC 
