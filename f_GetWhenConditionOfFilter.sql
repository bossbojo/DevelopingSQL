
CREATE FUNCTION [dbo].[f_GetWhenConditionOfFilter](@table_name NVARCHAR(50),@search_text NVARCHAR(MAX),@key_where NVARCHAR(MAX) = '')
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @SQL NVARCHAR(MAX);
	IF(ISDATE(@search_text) = 1 AND LEN(@search_text) >= 8)
	BEGIN
		SELECT  
			@SQL = coalesce(@SQL + ' = 0 OR ', '') + 'DATEDIFF (DAY,'+CONVERT(NVARCHAR(50),cl.[name])+',CONVERT(DATE,'''+@search_text+'''))'
			FROM sys.columns cl 
			JOIN sys.types ty on ty.user_type_id = cl.user_type_id
			WHERE cl.object_id = OBJECT_ID(@table_name) 
				  AND (cl.[name] NOT IN(SELECT * FROM STRING_SPLIT(@key_where,',')))
				  AND ty.name in('date','time','datetime2','datetimeoffset','smalldatetime','datetime')
			SET @SQL = @SQL + ' = 0'
			RETURN @SQL
	END
	ELSE IF(ISNUMERIC(@search_text) = 1)
	BEGIN
		SELECT 
			@SQL = coalesce(@SQL + ' = '+@search_text+' OR ', '') + cl.[name]
			FROM sys.columns cl 
			JOIN sys.types ty on ty.user_type_id = cl.user_type_id
			WHERE cl.object_id = OBJECT_ID(@table_name) 
				  AND (cl.[name] NOT IN(SELECT * FROM STRING_SPLIT(@key_where,',')))
				  AND ty.collation_name is null and ty.name not in('date','time','datetime2','datetimeoffset','smalldatetime','datetime')
		SET @SQL = @SQL + ' = '+@search_text
		RETURN @SQL
	END
	ELSE 
	BEGIN
		SELECT 
			@SQL = coalesce(@SQL + ' LIKE ''%'+@search_text+'%'' OR ', '') + cl.[name]
			FROM sys.columns cl 
			JOIN sys.types ty on ty.user_type_id = cl.user_type_id
			WHERE cl.object_id = OBJECT_ID(@table_name) 
				  AND (cl.[name] NOT IN(SELECT * FROM STRING_SPLIT(@key_where,',')))
				  AND ty.collation_name is not null
		SET @SQL = @SQL + ' LIKE '+'''%'+@search_text+'%'''
		RETURN @SQL
	END
	RETURN @SQL
END

