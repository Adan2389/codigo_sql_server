
INICIO

	1- Creo las variables que usara el cursor (crs_ITEM, crs_TIPO_ITEM, crs_ORDEN, crs_TURNO, crs_LIBRAS, crs_VELOCIDAD, crs_HORAS_TRABAJO)
	2- Creo un cursor “CRS_WORKO_RDER” que decidirá de donde cargara las ordenes [según el parámetro de entrada “prm_Accion”. Si se trata 
		Programacion cargara las órdenes de la tabla “TEMP_ORDER”. Si es una re-Programacion será dela tabla “TEMP_ITEM”]
	3-Abro el Cursor y Ejecuto la lectura del Primer Registro.   
		3-1 Inicializo  “@AsingOrdenHrs=0”
		3-2 Inicializo “@i=0” 
		3-3 Inicializo “@i_Item_Order_line=0” 
		3-4 Verifico si “crs_TURNO = null” 
		 SI-(es por que hay programar la Orden que esta leyendo el cursor)
			
			3-4 Inicio un Ciclo While que recorra el Tiempo en base 100 (“@i < crs_HORAS_TRABAJO * 100”)
				3-4-1 Verifico si el tiempo del turno es un Receso dentro del horario de Produccion (“crs_TIPO_ITEM=1 AND  @TipoTiempo=2”)
				  SI-
					-Se detiene el recorrido del Tiempo  “@i=@i”
				  NO-
					-El tiempo avanza normalemte “@i++”
				  FIN
				_______________________________________________________________________________________________________________________
					                                            SECCION CUANDO SE COMPLETA UN TURNO 
				_______________________________________________________________________________________________________________________
				3-4-2 Verifico si se completo un Turno "@AcumAsingTurnoHrs = @TotalTurnoHrs"
				  SI-
					3-4-2 Obtengo la informacion del turno actual (Turno, TotalHrsSigTurno, TipoTiempo) Segun el numero de secuencia que 
						se este leyendo del horario de Trabajo 
					3-4-2 Enumero los los Items de las Ordenes de Produccion cuando se son de una  "PROGRAMACION "("@i_Item_Order_line ++")
					3-4-2 Enumero los los Items de las Ordenes de Produccion cuando vienes en una "REPROGRAMACION"("@i_Item_Order_line ++")
					3-4-2 Incrento el Item de la Programacion 
					3-4-2 Guardo el Item del Turno que se ha Completado en un procedimiento especial que realiza los calculos de fechas
						internamente ("SP_GUARDAR_ITEM  @AcumDias, @AsingOrdenHrs, ")
					3-4-2Paso a la Siguiente Secuencia del Horario de Trabajo ("@Num_Secuencia ++")
					3-4-2 Verifico el numero de Secuencia. Por que si la secuencia excede la maxima secuencia del horario de trabajo 
						la vuelvo a iniciar desde 1
					3-4-2 Obtengo el Tipo de Tiempo de la Nueva Secuencia 
						(con el proposito de que se verifique al inicio del siguiente turno para determinar si se se va a detener o avanzar el tiempo)
					
					3-4-2 Vuelvo iniciar en cero los acumuladores del Turno y de Horas para que empiecen el conteo del siguiente turno.
						@AcumAsingTurnoHrs =0, @AsingOrdenHrs = 0
				  FIN

				_______________________________________________________________________________________________________________________
					                                        SECCION PARA CONDICIONAR HORARIOS ESPECIALES  
				_______________________________________________________________________________________________________________________
				3-4-3 Verfico si se Completo el Horario de Trabajo de un Dia  ("@AcumAsingDiaHrs = @TotalDiaHrs")
				  SI
				    3-4-3 Avanzo al siguiente Dia ("@AcumDias++")
					3-4-3 Vuelvo a iniciar el cero el acumulador del Dia para que empiece el conteo del siguiente dia
					3-4-3 Verifico si NO se va a trabajar los domingos
					  SI
						Anvanzo a otro dia "@AcumDias++"
					  FIN
				  FIN

				3-4-4 Los Acumuladores van incrementado de 1 hasta completar el Turno, el Dia y las Horas de la Orden
					"@AcumAsingDiaHrs = @AcumAsingDiaHrs + 1" , "@AcumAsingTurnoHrs = @AcumAsingTurnoHrs + 1", "@AsingOrdenHrs = @AsingOrdenHrs +1"
			
			FIN-CICLO ("WHILE") 

			_______________________________________________________________________________________________________________________
			                                       SECCION QUE GUARDA HORAS SOBRANTES 
								   CUANDO SE TERMINA EL TIEMPO DE LA ORDEN Y UN TURNO QUEDA IMCOMPLETO
			_______________________________________________________________________________________________________________________
			3-4-5 Verifico si el Turno quedo Incompleto ("@AcumAsingTurnoHrs <= @TotalTurnoHrs")
			  SI
				3-4-5 Obtengo la informacion del turno actual (Turno, TotalHrsSigTurno, TipoTiempo) Segun el numero de secuencia que 
						se este leyendo del horario de Trabajo
				3-4-5 Obtengo el Tipo de Tiempo (con el proposito de que se verifique al inicio del siguiente turno para determinar si se se va a detener o avanzar el tiempo)
				3-4-5 Enumero los los Items de las Ordenes de Produccion cuando se son de una  "PROGRAMACION" ("@i_Item_Order_line ++")
				3-4-5 Enumero los los Items de las Ordenes de Produccion cuando vienes en una "REPROGRAMACION"("@i_Item_Order_line ++")
				3-4-5 Incrento el Item de la Programacion 
				3-4-5 Guardo el Item del Turno que se ha Completado en un procedimiento especial que realiza los calculos de fechas
					internamente ("SP_GUARDAR_ITEM  @AcumDias, @AsingOrdenHrs")
				3-4-6 Verifico Si el Turno se Completa Despues de Recorrer el Tiempo  de la Orden 
				  SI
					3-4-6 Obtengo las Horas del Siguiente Turno
					3-4-6 Paso a la Siguiente Secuencia del Horario de Trabajo ("@Num_Secuencia ++")
					3-4-6 Verifico el numero de Secuencia. Por que si la secuencia excede la maxima secuencia del horario de trabajo 
						la vuelvo a iniciar desde 1
					3-4-6 Obtengo el Tipo de Tiempo (con el proposito de que se verifique al inicio del siguiente turno para determinar si se se va a detener o avanzar el tiempo)
					3-4-6 Vuelvo iniciar en cero los acumuladores del Turno y de Horas para que empiecen el conteo del siguiente turno.
						@AcumAsingTurnoHrs =0, @AsingOrdenHrs = 0
				  NO

			  FIN
		NO (Cuando el Trno es diferente de NULL es por que el item en lectura NO hay que reprogramarlo SOLO GURDARLO) 
		_______________________________________________________________________________________________________________________
										   SECCION QUE SOLO SE GUARDA EL ITEM  
		_______________________________________________________________________________________________________________________				
		3-5  Guardo el Item del Turno que se ha Completado en un procedimiento especial PERO NO VA REALIZAR NINGUN CALCULO
					 ("SP_GUARDAR_ITEM  NULL, NULL")
		3-6 Se Ejecuto la lectura del Sguiente Registro.
	FIN-CURSOR 
	
	4- Mando a Eliminar los Registros de las Tablas Temporakes (TEMP_ORDER Y TEMP_ITEM)
	
FINAL 