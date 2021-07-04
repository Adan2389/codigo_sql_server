USE APP_SISTEMAS
GO 



--EN ESTA TABLA SE GUARDAN LAS PROGRAMACIONES DE ORDENES DE TRABAJO 
--SEGUN LA MAQUINA QUE ESTEN ASIGNADAS.
DROP TABLE PLANNING_PROGRAMACION
GO 

CREATE TABLE PLANNING_PROGRAMACION(
	ProgramacionID varchar(100),
	MaquinaID varchar(20),
	CreadoPor varchar(30),
	FechaCreado datetime,
	Item smallint,				--Numero ascendente que indica la ejecucion del horario 
	Estado smallint,			-- Estado [1-Programado, 2-Re-programado ]
	TipoItem smallint,			-- [1- Produccion,  2-Mantenimiento, 3-Tiempo de Cambio, 4-Tiempo de Otros Paros ]
	Descripcion varchar(350),	
	FechaItem date,
	Orden nvarchar(30),
	NumOrder smallint,			--Secuencia de Ejecucion de la Programacion definida por el usuario 
	Turno varchar(2),
	Horario_TrabajoID varchar(50),
	TipoHorario int,			-- [ 1- Variable, 2-Fijo]
	Part_id nvarchar(15),
	CoProducto nvarchar(15),
	Libras Decimal(12,4),
	Ancho varchar(50),
	Largo varchar(50),
	Espesor varchar(50),
	PesoMetro float,
	TotalMetros Decimal(12,2),
	Colores smallint,
	Rodillo Decimal(12,2),
	NoPistas smallint,
	FardosXhora decimal(12,2),
	HrsCambio Decimal(12,2),
	MetrosMetaMin Decimal(8,2),
	TSeteo Decimal(12,2),
	Por_Desperdicio varchar(10),
	Desperdicio Decimal(12,2),
	LibrasXhora Decimal(12,2),
	HorasTrabajo Decimal(12,2),
	TInicio datetime,
	TFinal datetime,
	Observacion varchar(350),
	FechaReprog datetime,		--Fecha cuando se reprogarma un Item
	Item_Order_Line smallint,	--Numero de Item que se va fragmentando una orden produccion en la primera programacion
	TipoTiempo smallint,		--Numero que indica el tipo de tiempo [1-Produccion,  2-Recesos]
	Tot_HrsOrden decimal(12,2)	--Obtiene la Cantidad de Hrs que fueron programadas de una Orden de Produccion
)
GO



--EN ESTA TABLA SE GUARDA LA INFORMACION TEMPORALMENTE DE LAS ORDERNES QUE SE VAN A PROGRAMAR
--SEGUN LA MAQUINA Y EL ORDEN 

DROP TABLE PLANNING_PRG_TEMP_ORDER
GO 
CREATE TABLE PLANNING_PRG_TEMP_ORDER
(

	NUMORDER smallint,
	F_CREADA	date,
	BASE_ID	nvarchar(30),
	CO_PRODUCTO	varchar(30),
	PART_ID	varchar(30),
	DESC_CO_PRODUCTO	varchar(100),
	CUSTOMER_ID	nvarchar(254),
	F_ENTRADA	date,
	F_REQUERIDA date,
	MAQUINA	nvarchar(15),
	LibrasXHora	decimal(15,8),
	T_TRABAJO	decimal(7,2),
	T_SETEO	decimal(8,3),
	TOT_HRSTRABAJO	decimal(9,3),
	LIBRAS	decimal(14,4),
	F_CERRADA	varchar(10),
	STATUS	nchar(1),
	Ancho	varchar(50),
	Tipo	varchar(50),
	Espesor	varchar(50),
	Colores smallint,
	Rodillo Decimal(12,2),
	Peso_Metro	varchar(20),
	Orden_Otro	varchar(15),
	NomCliente	nvarchar(50),
	PRODUCT_CODE	nvarchar(15),
	DESC_PART_ID	nvarchar(100)
)
GO 


--EN ESTA TABLA SE GUARDA LA INFORMACION TEMPORALMENTE DE LOS ITEM QUE SE ESTAN GENERANDO O REPROGRAMANDO
--SEGUN LA MAQUINA Y EL ORDEN 
DROP TABLE PLANNING_PRG_TEMP_ITEM
GO 
CREATE TABLE PLANNING_PRG_TEMP_ITEM
(
	ProgramacionID varchar(100),
	MaquinaID varchar(20),
	CreadoPor varchar(30),
	FechaCreado datetime,
	Item smallint,				--Numero ascendente que indica la ejecucion del horario 
	Estado smallint,			-- Estado [1-Programado, 2-Re-programado ]
	TipoItem smallint,			-- [1- Produccion,  2-Mantenimiento, 3-Tiempo de Cambio, 4-Tiempo de Otros Paros ]
	Descripcion varchar(350),	
	FechaItem date,
	Orden nvarchar(30),
	NumOrder smallint,			--Secuencia de Ejecucion de la Programacion definida por el usuario
	Turno varchar(2),
	Horario_TrabajoID varchar(50),
	TipoHorario int,			-- [ 1- Variable, 2-Fijo]
	Part_id nvarchar(15),
	CoProducto nvarchar(15),
	Libras Decimal(12,4),
	Ancho varchar(50),
	Largo varchar(50),
	Espesor varchar(50),
	PesoMetro float,
	TotalMetros Decimal(12,2),
	Colores smallint,
	Rodillo Decimal(12,2),
	NoPistas smallint,
	FardosXhora decimal(12,2),
	HrsCambio Decimal(12,2),
	MetrosMetaMin Decimal(8,2),
	TSeteo Decimal(12,2),
	Por_Desperdicio varchar(10),
	Desperdicio Decimal(12,2),
	LibrasXhora Decimal(12,2),
	HorasTrabajo Decimal(12,2),
	TInicio datetime,
	TFinal datetime,
	Observacion varchar(350),
	FechaReprog datetime,		--Fecha cuando se reprogarma un Item
	Item_Order_Line smallint,	--Numero de Item que se va fragmentando una orden produccion en la primera programacion
	TipoTiempo smallint	,		--Numero que indica el tipo de tiempo [1-Produccion,  2-Recesos]
	Tot_HrsOrden decimal(12,2)	--Obtiene la Cantidad de Hrs que fueron programadas de una Orden de Produccion
)
GO 



DROP TABLE HORARIOS_TRABAJO

CREATE TABLE HORARIOS_TRABAJO
(
	Horario_TrabajoID varchar(50), 
	Secuencia smallint,				--Orden de Ejecucion
	Num_Lectura smallint,			--Posicion de Lectura/Ejecucion
	TipoTurno varchar(10),			--['ABC', 'AC']
	Turno varchar(2),				--['A','B','C']
	TipoTiempo smallint,			--[1-Produccion, 2-Recesos]
	Descripcion varchar(50),			--'Tiempo de Produccion TurnoX', 'Tiempo de Receso por Almuerzo'
	TotalTurnoHrs decimal(12,2),	
	TotalHrsSigTurno decimal(12,2),
	TInicio Datetime,				
	TFinal Datetime,
	TotalHrs decimal(12,2),
	TInicio_b100 decimal(12,2),
	TFinal_b100 decimal(12,2),
	AcumAsingDiaHrs decimal(12,2), 
	TotalDiaHrs decimal(12,2),
	THora_CicloDia time,
	THora_CicloDia_b100 decimal(12,2), 	
	CONSTRAINT fk_HORARIOS_TRABAJO_TipoTiempo foreign key (TipoTiempo) references   TIPO_TIEMPO  (NumTiempo)
)
GO 




CREATE TABLE TIPO_TIEMPO
(
	NumTiempo smallint,
	Descripcion varchar(50),
	Constraint Pk_TipoTiempo_Num Primary Key  (NumTiempo)
)
GO 



--Esta tabla almacena las Metas de Produccion para poder calcular 
--el resumen mensual de produccion

CREATE TABLE BTS_Metas_Produccion
(
	RowID int,
	Row_Create_Date datetime default getdate(),
	Fecha date,
	Proceso varchar(10),
	Maquina varchar(20),
	Cantidad decimal(15,2),
	Horas Decimal(8,2),
	Constraint Pk_BTS_Metas_Produccion_Num Primary Key  (RowID)
)
GO 
