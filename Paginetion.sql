CREATE PROCEDURE [dbo].[pagination]
	 @table_name NVARCHAR(50) = '',
	 @search_text NVARCHAR(MAX) ='',
     @yourwhere NVARCHAR(MAX) = '',
	 @key_where NVARCHAR(MAX) = '',
	 @page INT = 1,
	 @limit_page INT = 15,
	 @sortby NVARCHAR(50) = '',  
	 @sort_type NVARCHAR(50) = 'ASC'
AS
BEGIN
	--SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @SQL_OFFSET NVARCHAR(MAX) = ((@page-1)*@limit_page);
	DECLARE @SQL_MAX NVARCHAR(MAX) = @limit_page;
	DECLARE @SQL_FILTER NVARCHAR(MAX) = '';
    DECLARE @FILTER_CUSTOM NVARCHAR(MAX) = '';
	DECLARE @SQL_ORDERBY NVARCHAR(MAX);

	--SORT BY NOT NULL ถ้า SORT BY ไม่มีค่า------------------------------------------------
	IF(@sortby = '')
	BEGIN
		SELECT TOP 1 @sortby = cl.[name] FROM sys.columns cl WHERE cl.object_id = OBJECT_ID(@table_name)
		SET @SQL_ORDERBY = ' ORDER BY '+@sortby+' '+@sort_type+' OFFSET '+@SQL_OFFSET+' ROWS FETCH NEXT '+@SQL_MAX+' ROWS ONLY'
	END
	ELSE
	BEGIN
		SET @SQL_ORDERBY = ' ORDER BY '+@sortby+' '+@sort_type+' OFFSET '+@SQL_OFFSET+' ROWS FETCH NEXT '+@SQL_MAX+' ROWS ONLY'
	END
	---SEARCH TEXT ALL COLUMN IS NOT NULL ถ้าการค้นหาเเบบทั้งหมดไม่เป็นค่าว่าง(มีค่า)----------------
	IF(@search_text != '')
	BEGIN
		PRINT 'SEARCH ALL มีค่า'
		SET @SQL_FILTER = 'WHERE ('+dbo.f_GetWhenConditionOfFilter(@table_name,@search_text,@key_where)+')';
		PRINT @SQL_FILTER;
	END

	---YOUR WHERE IS NOT NULL ถ้า WHERE เเบบกำหนดเองไม่เท่ากับค่าว่าง(มีค่า)------------------------
    IF( @yourwhere  != '')
    BEGIN
		PRINT 'YOUR WHERE มีค่า'
        SET @FILTER_CUSTOM = 'WHERE ('+@yourwhere+') ';
		PRINT @FILTER_CUSTOM;
    END
	---SUMMARY WHERE WORD รวมคำของการ WHERE --------------------------------------------5
	SET @SQL = ('WITH CTE AS (SELECT * FROM '+@table_name+' '+@FILTER_CUSTOM+') SELECT * FROM CTE '+@SQL_FILTER+' '+@SQL_ORDERBY); 
	PRINT @SQL
	EXEC (@SQL)
END


CREATE PROCEDURE [dbo].[pagination_row_count]
	 @table_name NVARCHAR(50),
	 @search_text NVARCHAR(MAX) = '',
     @yourwhere NVARCHAR(MAX) = '',
	 @key_where NVARCHAR(MAX) = ''
AS
BEGIN
	--SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @SQL_FILTER NVARCHAR(MAX) = '';
    DECLARE @FILTER_CUSTOM NVARCHAR(MAX) = '';
	DECLARE @WHERE_WORD NVARCHAR(MAX) = '';
	----------------------------------MANAGE WHERE-------------------------------------

	---SEARCH TEXT ALL COLUMN IS NOT NULL ถ้าการค้นหาเเบบทั้งหมดไม่เป็นค่าว่าง(มีค่า)----------------
	IF(@search_text != '')
	BEGIN
		SET @SQL_FILTER = 'WHERE ('+dbo.f_GetWhenConditionOfFilter(@table_name,@search_text,@key_where)+')';
		PRINT @SQL_FILTER
	END

	---YOUR WHERE IS NOT NULL ถ้า WHERE เเบบกำหนดเองไม่เท่ากับค่าว่าง(มีค่า)------------------------
    IF( @yourwhere  != '')
    BEGIN
        SET @FILTER_CUSTOM = 'WHERE ('+@yourwhere+')';
		PRINT @FILTER_CUSTOM
	END

	---SUMMARY WHERE WORD รวมคำของการ WHERE --------------------------------------------

	SET @SQL = ('WITH CTE AS (SELECT * FROM '+@table_name+' '+@FILTER_CUSTOM+') SELECT COUNT(*) FROM CTE '+@SQL_FILTER); 
	PRINT @SQL
	EXEC (@SQL)
END

CREATE FUNCTION [dbo].[f_GetWhenConditionOfFilter](@table_name NVARCHAR(50),@search_text NVARCHAR(MAX),@key_where NVARCHAR(MAX) = '')
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @SQL NVARCHAR(MAX);
	IF(ISDATE(@search_text) = 1 AND LEN(@search_text) >= 8)
	BEGIN
		SELECT 
			@SQL = coalesce(@SQL + '= CONVERT(DATE,'''+@search_text+''') OR ', '') + cl.[name]
			FROM sys.columns cl 
			JOIN sys.types ty on ty.user_type_id = cl.user_type_id
			WHERE cl.object_id = OBJECT_ID(@table_name) 
				  AND (cl.[name] NOT IN(SELECT * FROM STRING_SPLIT(@key_where,',')))
				  AND ty.name in('date','time','datetime2','datetimeoffset','smalldatetime','datetime')
			SET @SQL = @SQL + '='+'CONVERT(DATE,'''+@search_text+''')'
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

CREATE PROCEDURE [dbo].[pagination_json]
	 @table_name NVARCHAR(50) = '',
	 @search_text NVARCHAR(MAX) ='',
     @yourwhere NVARCHAR(MAX) = '',
	 @key_where NVARCHAR(MAX) = '',
	 @page INT = 1,
	 @limit_page INT = 15,
	 @sortby NVARCHAR(50) = '',  
	 @sort_type NVARCHAR(50) = 'ASC'
AS
BEGIN
	--SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @SQL_OFFSET NVARCHAR(MAX) = ((@page-1)*@limit_page);
	DECLARE @SQL_MAX NVARCHAR(MAX) = @limit_page;
	DECLARE @SQL_FILTER NVARCHAR(MAX) = '';
    DECLARE @FILTER_CUSTOM NVARCHAR(MAX) = '';
	DECLARE @SQL_ORDERBY NVARCHAR(MAX);

	--SORT BY NOT NULL ถ้า SORT BY ไม่มีค่า------------------------------------------------
	IF(@sortby = '')
	BEGIN
		SELECT TOP 1 @sortby = cl.[name] FROM sys.columns cl WHERE cl.object_id = OBJECT_ID(@table_name)
		SET @SQL_ORDERBY = ' ORDER BY '+@sortby+' '+@sort_type+' OFFSET '+@SQL_OFFSET+' ROWS FETCH NEXT '+@SQL_MAX+' ROWS ONLY'
	END
	ELSE
	BEGIN
		SET @SQL_ORDERBY = ' ORDER BY '+@sortby+' '+@sort_type+' OFFSET '+@SQL_OFFSET+' ROWS FETCH NEXT '+@SQL_MAX+' ROWS ONLY'
	END
	---SEARCH TEXT ALL COLUMN IS NOT NULL ถ้าการค้นหาเเบบทั้งหมดไม่เป็นค่าว่าง(มีค่า)----------------
	IF(@search_text != '')
	BEGIN
		PRINT 'SEARCH ALL มีค่า'
		SET @SQL_FILTER = 'WHERE ('+dbo.f_GetWhenConditionOfFilter(@table_name,@search_text,@key_where)+')';
		PRINT @SQL_FILTER;
	END

	---YOUR WHERE IS NOT NULL ถ้า WHERE เเบบกำหนดเองไม่เท่ากับค่าว่าง(มีค่า)------------------------
    IF( @yourwhere  != '')
    BEGIN
		PRINT 'YOUR WHERE มีค่า'
        SET @FILTER_CUSTOM = 'WHERE ('+@yourwhere+') ';
		PRINT @FILTER_CUSTOM;
    END
	---SUMMARY WHERE WORD รวมคำของการ WHERE --------------------------------------------5
	SET @SQL = ('WITH CTE AS (SELECT * FROM '+@table_name+' '+@FILTER_CUSTOM+') SELECT (SELECT * FROM CTE '+@SQL_FILTER+' '+@SQL_ORDERBY+' FOR JSON AUTO) AS JSON_DATA'); 
	PRINT @SQL 
	EXEC (@SQL)
END