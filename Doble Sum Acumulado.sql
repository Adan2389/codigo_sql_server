

	
	

	 SELECT     FECHA,
				[BPS_SLIT_1],
				SUM(SUM([BPS_SLIT_1])) OVER (ORDER BY FECHA ASC ) AS ACUMULADO1,
				
				[BPS_SLIT_2],
				SUM(SUM([BPS_SLIT_2])) OVER (ORDER BY FECHA ASC ) AS ACUMULADO2			
				
	 FROM [VMFGPN].[dbo].[VK_BCL_LECTURAS_CONSUMO_ENERGIA] as a
	 WHERE FECHA  BETWEEN '08-04-2019' AND '09-04-2019'
	 GROUP BY [BPS_SLIT_2], [BPS_SLIT_1],  FECHA
	 

