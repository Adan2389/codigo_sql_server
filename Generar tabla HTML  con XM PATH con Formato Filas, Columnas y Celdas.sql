
CREATE FUNCTION dbo.CreateHTMLTable
(
    @SelectForXmlPathRowElementsXsinil XML
   ,@tblClass VARCHAR(100) --NULL to omit this class
   ,@thClass VARCHAR(100)  --same
   ,@tbClass VARCHAR(100)  --same
)
RETURNS XML
AS
BEGIN

RETURN 
(
    SELECT @tblClass AS [@class]  
    ,@thClass AS [thead/@class]
    ,@SelectForXmlPathRowElementsXsinil.query(
              N'let $first:=/row[1]
                return 
                <tr> 
                {
                for $th in $first/*
                return <th>{if(not(empty($th/@caption))) then xs:string($th/@caption) else local-name($th)}</th>
                }
                </tr>') AS thead
    ,@tbClass AS [tbody/@class]
    ,@SelectForXmlPathRowElementsXsinil.query(
               N'for $tr in /row
                 return 
                 <tr>{$tr/@class}
                 {
                 for $td in $tr/*
                 return
                 if(empty($td/@link)) 
                 then <td>{$td/@class}{string($td)}</td>
                 else <td>{$td/@class}<a href="{$td/@link}">{string($td)}</a></td>
                 }
                 </tr>') AS tbody
    FOR XML PATH('table'),TYPE
) 
END

GO



declare @body varchar(max)
Set @body = 
		'<html>'+
		N'<head>'+ 
		'<style type="text/css"> 
			.trMark{ background-color: #B0B0B0; } 
			.tdMarkNull{ background-color: #B0B0B0; } 
			.thFormat{ background-color: #00B0F0; } 
			.tblFormat{ border-collapse: collapse; border:1px; } 
		</style>'+
		N'</head>'+
		N'<body>'
	
set @body += CAST(
				(SELECT dbo.SP_GENERAL_CREATE_TABLE_HTML
					(
						 (
							 SELECT TOP 50
							   CASE WHEN ROW_NUMBER() OVER (ORDER BY CODIGO ASC) % 2 = 0 THEN 'trMark' ELSE NULL END AS [@class]    --Clase condicionda aplicara a todo un <tr>
							  
							  ,CODIGO
							  
							  ,'center' AS [Dummy/@class]                                                    --a class within TestText (appeary always)
							  ,'DESCRIPCION DEL PRODUCTO' AS [Dummy/@caption]                                             --a different caption
							  ,DESCRIPCION AS [Dummy] 
																											--blanks in the column's name must be tricked away...
							  ,CASE WHEN USO IS NULL THEN 'tdMarkNull' END AS [USO/@class]					--a class within ShouldNotBeNull (appears only if needed)
							  ,'USO' AS [USO/@caption]										--a caption for a CamelCase-ColumnName
							  ,USO

							 FROM GENERAL_PRODUCTOS 
							 FOR XML PATH('row'),ELEMENTS XSINIL
						 ),
						 'testTbl',
						 'thFormat',
						 'testTb'
					)
				)AS VARCHAR(max))

SET @body +=
		N'</table>'+
		N'<body>'+
		N'<html>'
		
PRINT @body




DECLARE @tbl3 TABLE(ID INT, [With blank] VARCHAR(100),Link VARCHAR(MAX),ShouldNotBeNull INT);
INSERT INTO @tbl3 VALUES
 (1,'NoWarning',NULL,1)
,(2,'No Warning too','http://www.Link2.com',2)
,(3,'Warning','http://www.Link3.com',3)
,(4,NULL,NULL,NULL)
,(5,'Warning',NULL,5)
,(6,'One more warning','http://www.Link6.com',6);
--The query adds an attribute Link to an element (NULL if not defined)
SELECT dbo.CreateHTMLTable
(
     (
     SELECT 
       CASE WHEN LEFT([With blank],2) != 'No' THEN 'warning' ELSE NULL END AS [@class]      --The first @class is the <tr>-class
      ,ID
      ,'center' AS [Dummy/@class]                                                    --a class within TestText (appeary always)
      ,Link AS [Dummy/@link]                                                         --a mark to pop up as link
      ,'New caption' AS [Dummy/@caption]                                             --a different caption
      ,[With blank] AS [Dummy]                                                       --blanks in the column's name must be tricked away...
      ,CASE WHEN ShouldNotBeNull IS NULL THEN 'MarkRed' END AS [ShouldNotBeNull/@class] --a class within ShouldNotBeNull (appears only if needed)
      ,'Should not be null' AS [ShouldNotBeNull/@caption]                             --a caption for a CamelCase-ColumnName
      ,ShouldNotBeNull
     FROM @tbl3 FOR XML PATH('row'),ELEMENTS XSINIL),'testTbl','testTh','testTb'
);