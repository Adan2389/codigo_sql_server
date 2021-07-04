

--EXECUTE SELECT_SLITTER '1__Prueba '

CREATE PROCEDURE SELECT_CONVERSION (@ProgramacionID varchar(50))

as 
BEGIN


	--TABLA TEMPORAL PARA GUARDAR LA PROGRAMACION DE EXTRUSION
	CREATE TABLE ##Temp_Programacion_Conversion   (
		Item smallint,

		ProgramacionID varchar(100) ,	MaquinaID varchar(20) ,		CreadoPor varchar(30) ,			 FechaCreado datetime ,		
		Estado smallint ,				TipoItem smallint ,			Descripcion varchar(350) ,  	 FechaItem date ,				
		Orden nvarchar(30) ,			NumOrder smallint ,			Turno varchar(2) ,				 Horario_TrabajoID varchar(50),	
		TipoHorario int ,				Part_id nvarchar(15) ,		CoProducto nvarchar(15) ,		 Libras Decimal(12,4) ,
		Ancho varchar(50) ,				Largo varchar(50) ,			Espesor varchar(50) ,			 PesoMetro float ,			
		TotalMetros Decimal(12,2) ,		Colores smallint ,			Rodillo Decimal(12,2),			 NoPistas smallint ,		
		FardosXhora decimal(12,2) , 	HrsCambio Decimal(12,2) ,	MetrosMetaMin Decimal(8,2) ,	 TSeteo Decimal(12,2) ,	
		Por_Desperdicio varchar(10) ,	Desperdicio Decimal(12,2) ,	LibrasXhora Decimal(12,2) , 	 HorasTrabajo Decimal(12,2) ,	
		TInicio datetime ,				TFinal datetime  ,			Observacion varchar(350) , 		 FechaReprog datetime ,	
		Item_Order_Line smallint ,		TipoTiempo smallint ,		Tot_HrsOrden decimal(12,2) ,	
	
		Turno_View varchar(2)
	
	)
	
	--OBTENGO LA PROGRAMACION 
	INSERT INTO ##Temp_Programacion_Conversion
		EXECUTE SELECT_PROGRAMACION @ProgramacionID


		--AJUSTO LA SALIDA DE LOS CAMPOS
		SELECT Item, FechaItem, Turno as Turno, Horario_TrabajoID as [Horario Trabajo], Descripcion, DesProducto as [Descripcion Producto],
				Libras, Ancho, Largo, Espesor, TotalMetros, LibrasXhora, HorasTrabajo, TInicio, TFinal, Ancho_Film,  Refil,  
				Round((Desperdicio/Libras),2)AS [ % Desper.], Desperdicio, PorDesperAuto as [% Desper. Auto], IOL, TI
		FROM (
			SELECT *,
					ROUND(((PorDesperAuto/100)*Libras),2)AS Desperdicio
			FROM (
				SELECT  Item, FechaItem, Turno_View as Turno, Horario_TrabajoID,
				 
						  CASE WHEN TipoTiempo=2  and TipoItem=1 then (Select Descripcion from TIPO_TIEMPO where NumTiempo=a.TipoTiempo)
							   ELSE Descripcion
						  END AS Descripcion,

						  CASE WHEN TipoTiempo=2 and TipoItem=1 then (Select Descripcion from TIPO_TIEMPO where NumTiempo=a.TipoTiempo)
							   WHEN TipoTiempo=1 and TipoItem=1 then  (CoProducto +'-'+(Select lower(Description) from VMFGPN.DBO.PART where ID=a.CoProducto))
							   ELSE Observacion  
						  END as DesProducto,

						 Round(((Libras) - (((HorasTrabajo/Tot_HrsOrden)*(TSeteo))*(LibrasXhora))),2) as Libras, 

						 (Select TOP 1 USER_1 from VMFGPN.DBO.OPERATION WHERE WORKORDER_BASE_ID= Orden and RUN > 0) as Ancho_Film,

						 NULL AS Refil, (SELECT Round(SCRAP_PERCENT,2) FROM VMFGPN.DBO.REQUIREMENT WHERE WORKORDER_BASE_ID = Descripcion AND PIECE_NO=10)AS PorDesperAuto,		
						 Ancho, Largo, Espesor,
						 Round(((TotalMetros) - (((HorasTrabajo/Tot_HrsOrden)*(TSeteo))*(LibrasXhora))),2) as TotalMetros,  
						 MetrosMetaMin, LibrasXhora, HorasTrabajo, TInicio, TFinal, Item_Order_Line AS IOL, TipoItem as TI
				FROM ##Temp_Programacion_Conversion as a
			)AS C1
		)AS C2

	DROP TABLE  ##Temp_Programacion_Conversion

END
GO 

	
	




