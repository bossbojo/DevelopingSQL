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