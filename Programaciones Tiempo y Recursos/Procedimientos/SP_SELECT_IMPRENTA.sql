

--EXECUTE SELECT_EXTRUSION '1__Prueba '

ALTER PROCEDURE SELECT_IMPRENTA (@ProgramacionID varchar(50))

as 
BEGIN


	--TABLA TEMPORAL PARA GUARDAR LA PROGRAMACION DE EXTRUSION
	CREATE TABLE ##Temp_Programacion_Imprenta   (
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
	INSERT INTO ##Temp_Programacion_Imprenta
		EXECUTE SELECT_PROGRAMACION @ProgramacionID


		--AJUSTO LA SALIDA DE LOS CAMPOS
		SELECT  Item, FechaItem, Turno_View as Turno, Horario_TrabajoID as [Horario Trabajo],
				 
				  CASE WHEN TipoTiempo=2  and TipoItem=1 then (Select Descripcion from TIPO_TIEMPO where NumTiempo=a.TipoTiempo)
					   ELSE Descripcion
				  END AS Descripcion,

				  CASE WHEN TipoTiempo=2 and TipoItem=1 then (Select Descripcion from TIPO_TIEMPO where NumTiempo=a.TipoTiempo)
					   WHEN TipoTiempo=1 and TipoItem=1 then  (CoProducto +'-'+(Select lower(Description) from VMFGPN.DBO.PART where ID=a.CoProducto))
					   ELSE Observacion  
				  END as DesProducto,

				 Round(((Libras) - (((HorasTrabajo/Tot_HrsOrden)*(TSeteo))*(LibrasXhora))),2) as Libras, 
				 Ancho, Largo, Espesor, Rodillo, Colores, 
				 Round(((TotalMetros) - (((HorasTrabajo/Tot_HrsOrden)*(TSeteo))*(LibrasXhora))),2) as TotalMetros,  
				 MetrosMetaMin, LibrasXhora, HorasTrabajo, TInicio, TFinal, Item_Order_Line AS IOL, TipoItem as TI
		FROM ##Temp_Programacion_Imprenta as a


	DROP TABLE  ##Temp_Programacion_Imprenta

END
GO 

	
	




