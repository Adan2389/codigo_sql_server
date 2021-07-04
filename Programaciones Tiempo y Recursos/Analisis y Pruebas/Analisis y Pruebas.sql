

--select * from app_sistemas.dbo.PLANNING_PROGRAMACION

		-- CONVERTE UNA FECHA DATE + UNA HORA TIME PARA OBTENER UN VALOR EN FORMATO DATETIME
		Declare @Fecha date = '12-01-2018'
		Declare @Hora time = '23:45:45'
		Declare @TInicio datetime = null;
		Set @TInicio = convert(varchar(12), @Fecha,103 ) +' '+ cast(@Hora as varchar(10))

		--SE LE SUMAN MINUTOS A UNA HORA DE TIPO DATETIME 
		Set @TInicio = dateadd(minute,300, @TInicio)
		PRINT @TInicio




		--LISTADO SELECTIVO DE ORDENES A PROGRAMAR 
		SELECT DISTINCT   FechaCreado, WORKORDER_ID, CodProducto, Ref_Producto,	Maquina, Libras, Ancho, Espesor, PesoMetro,
				LibrasxHora, HorasTrabajo 
		FROM VMFGPN.DBO.LIST_ORDER_PRG ()
		--WHERE Maquina = @prm_Maquina and HorasTrabajo =20.00
		WHERE WORKORDER_ID IN ( 'OPR-00652-17', 'OPR-00481-17','OPR-01424-17', 
														'OPR-00844-17', 'OPR-01398-17')
		ORDER BY WORKORDER_ID