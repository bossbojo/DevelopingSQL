UES <'YOUR DATABASE'>
----------------------------1 
--@table_name ชื่อ table หรือ view เช่น [MRP].[Order]
--@search_text ข้อความที่ต้องการค้นหา (ไม่จำเป็นต้องใส่ว่าจะค้นหา column ไหน f_GetWhenConditionOfFilter นี้จะบอกเอง)
CREATE FUNCTION dbo.f_GetWhenConditionOfFilter(
    @table_name NVARCHAR(50),@search_text NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX);
	IF(ISDATE(@search_text) = 1)
	BEGIN--------type value date or datetime
		SELECT 
			@SQL = coalesce(@SQL + '= CONVERT(DATE,'''+@search_text+''') OR ', '') +  convert(varchar(50),CONCAT('CONVERT(DATE,',cl.[name],')'))
		FROM sys.columns cl 
		WHERE cl.object_id = OBJECT_ID(@table_name) AND (TYPE_NAME(cl.user_type_id) = 'date' OR TYPE_NAME(cl.user_type_id) = 'datetime')
		SET @SQL = @SQL + '='+'CONVERT(DATE,'''+@search_text+''')'
	END
	ELSE
	BEGIN--------type value not date or datetime
		SELECT 
			@SQL = coalesce(@SQL + ' LIKE ''%'+@search_text+'%'' OR ', '') +  convert(varchar(50),CONCAT('CONVERT(NVARCHAR(MAX),',cl.[name],')'))
		FROM sys.columns cl 
		WHERE cl.object_id = OBJECT_ID(@table_name) AND (TYPE_NAME(cl.user_type_id) != 'date' AND TYPE_NAME(cl.user_type_id) != 'datetime')
		SET @SQL = @SQL + ' LIKE '+'''%'+@search_text+'%'''
	END
	RETURN CONVERT(NVARCHAR(MAX),@SQL)
END

----------------------------2
--@table_name ชื่อ table หรือ view เช่น [MRP].[Order]
--@search_text ข้อความที่ต้องการค้นหา (ไม่จำเป็นต้องใส่ว่าจะค้นหา column ไหน f_GetWhenConditionOfFilter นี้จะบอกเอง)
--@page ต้องการหน้าไหน
--@limit_page Max row ที่ต้องการ
--@sortby ใส่ชื่อ column ที่ต้องการ sort
--@sort_type ใส่ ASC หรือ DESC
--@fromToBy ชื่อที่เป็น date หรือ datetime ที่ต้องการ filter เเบบ from to
--@from ใส่ date หรือ datetime เริ่มต้น
--@to  ใส่ date หรือ datetime สิ้นสุด
CREATE PROCEDURE [dbo].[pagination]
	 @table_name NVARCHAR(50),
	 @search_text NVARCHAR(MAX),
     @filter_column1 NVARCHAR(50) = '',
     @filter_column_value1 NVARCHAR(50) = '',
     @filter_column2 NVARCHAR(50) = '',
     @filter_column_value2 NVARCHAR(50) = '',
     @filter_column3 NVARCHAR(50) = '', 
     @filter_column_value3 NVARCHAR(50) = '',
     @filter_column4 NVARCHAR(50) = '', 
     @filter_column_value4 NVARCHAR(50) = '',
	 @page INT = 1,
	 @limit_page INT = 15,
	 @sortby NVARCHAR(50) = '',  
	 @sort_type NVARCHAR(50) = 'ASC', 
	 @fromToBy NVARCHAR(50) = '',
	 @from NVARCHAR(50) = '',
	 @to NVARCHAR(50) = ''
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @SQL_OFFSET NVARCHAR(MAX) = ((@page-1)*@limit_page);
	DECLARE @SQL_MAX NVARCHAR(MAX) = @limit_page;
	PRINT @SQL_OFFSET
	DECLARE @SQL_FILTER NVARCHAR(MAX) = '('+dbo.f_GetWhenConditionOfFilter(@table_name,@search_text)+')';
	IF(ISDATE(@from) = 1 AND ISDATE(@to) = 1)
	BEGIN

        DECLARE @FILTER_CUSTOM NVARCHAR(MAX) = '';

        IF(@filter_column1 != '' AND @filter_column_value1 != '')
        BEGIN
            SET @FILTER_CUSTOM =  'CONVERT(NVARCHAR(MAX),'+filter_column1+') = '+filter_column_value1
        END
        IF(@filter_column2 != '' AND @filter_column_value2 != '')
        BEGIN
            SET @FILTER_CUSTOM =  @FILTER_CUSTOM+' AND CONVERT(NVARCHAR(MAX),'+filter_column2+') = '+filter_column_value2
        END
        IF(@filter_column3 != '' AND @filter_column_value3 != '')
        BEGIN
            SET @FILTER_CUSTOM =  @FILTER_CUSTOM+' AND CONVERT(NVARCHAR(MAX),'+filter_column3+') = '+filter_column_value3
        END
        IF(@filter_column4 != '' AND @filter_column_value4 != '')
        BEGIN
            SET @FILTER_CUSTOM =  @FILTER_CUSTOM+' AND CONVERT(NVARCHAR(MAX),'+filter_column4+') = '+filter_column_value4
        END
        IF( @FILTER_CUSTOM  != '')
        BEGIN
            SET @FILTER_CUSTOM = 'AND ( '+@FILTER_CUSTOM+' )'
        END

		DECLARE @SQL_FROMTO NVARCHAR(MAX) = '( CONVERT(DATE,'+@fromToBy+') >= CONVERT(DATE,'''+@from+''') AND CONVERT(DATE,'+@fromToBy+') <=  CONVERT(DATE,'''+@to+''') )';
		IF(@sortby != '')
		BEGIN
			SELECT TOP 1 @sortby = cl.[name] FROM sys.columns cl WHERE cl.object_id = OBJECT_ID(@table_name)
			SET @SQL = ('SELECT * FROM '+@table_name+' WHERE '+  @SQL_FILTER + ' AND ' + @SQL_FROMTO + ' '+@FILTER_CUSTOM+' ORDER BY '+@sortby+' '+@sort_type+' OFFSET '+@SQL_OFFSET+' ROWS FETCH NEXT '+@SQL_MAX+' ROWS ONLY') 
		END
		ELSE
		BEGIN
			SELECT TOP 1 @sortby = cl.[name] FROM sys.columns cl WHERE cl.object_id = OBJECT_ID(@table_name)
			SET @SQL = ('SELECT * FROM '+@table_name+' WHERE '+  @SQL_FILTER + ' AND ' + @SQL_FROMTO + ' '+@FILTER_CUSTOM+' ORDER BY '+@sortby+' '+@sort_type+' OFFSET '+@SQL_OFFSET+' ROWS FETCH NEXT '+@SQL_MAX+' ROWS ONLY') 
		END
	END
	ELSE
	BEGIN
		IF(@sortby != '')
		BEGIN
			SET @SQL = ('SELECT * FROM '+@table_name+' WHERE '+  @SQL_FILTER + ' '+@FILTER_CUSTOM+' ORDER BY '+@sortby+' '+@sort_type+' OFFSET '+@SQL_OFFSET+' ROWS FETCH NEXT '+@SQL_MAX+' ROWS ONLY') 
		END
		ELSE
		BEGIN
			SELECT TOP 1 @sortby = cl.[name] FROM sys.columns cl WHERE cl.object_id = OBJECT_ID(@table_name)
			SET @SQL = ('SELECT * FROM '+@table_name+' WHERE '+  @SQL_FILTER + ' '+@FILTER_CUSTOM+' ORDER BY '+@sortby+' '+@sort_type+' OFFSET '+@SQL_OFFSET+' ROWS FETCH NEXT '+@SQL_MAX+' ROWS ONLY') 
		END
	END
	PRINT @SQL
	EXEC (@SQL)
END
var res = db.database.sqlQury<Users>("SELECT * FROM clinic.UsersTable1234")

------------------------3 
--@table_name ชื่อ table หรือ view เช่น [MRP].[Order]
--@search_text ข้อความที่ต้องการค้นหา (ไม่จำเป็นต้องใส่ว่าจะค้นหา column ไหน f_GetWhenConditionOfFilter นี้จะบอกเอง)
--@fromToBy ชื่อที่เป็น date หรือ datetime ที่ต้องการ filter เเบบ from to
--@from ใส่ date หรือ datetime เริ่มต้น
--@to  ใส่ date หรือ datetime สิ้นสุด

CREATE PROCEDURE [dbo].[pagination_row_count]
	 @table_name NVARCHAR(50),
	 @search_text NVARCHAR(MAX),
     @filter_column1 NVARCHAR(50) = '',
     @filter_column_value1 NVARCHAR(50) = '',
     @filter_column2 NVARCHAR(50) = '',
     @filter_column_value2 NVARCHAR(50) = '',
     @filter_column3 NVARCHAR(50) = '', 
     @filter_column_value3 NVARCHAR(50) = '',
     @filter_column4 NVARCHAR(50) = '', 
     @filter_column_value4 NVARCHAR(50) = '',
	 @fromToBy NVARCHAR(50) = '',
	 @from NVARCHAR(50) = '',
	 @to NVARCHAR(50) = ''
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @SQL_FILTER NVARCHAR(MAX) = '('+dbo.f_GetWhenConditionOfFilter(@table_name,@search_text)+')';
    DECLARE @FILTER_CUSTOM NVARCHAR(MAX) = '';

    IF(@filter_column1 != '' AND @filter_column_value1 != '')
    BEGIN
        SET @FILTER_CUSTOM =  'CONVERT(NVARCHAR(MAX),'+filter_column1+') = '+filter_column_value1
    END
    IF(@filter_column2 != '' AND @filter_column_value2 != '')
    BEGIN
        SET @FILTER_CUSTOM =  @FILTER_CUSTOM+' AND CONVERT(NVARCHAR(MAX),'+filter_column2+') = '+filter_column_value2
    END
    IF(@filter_column3 != '' AND @filter_column_value3 != '')
    BEGIN
        SET @FILTER_CUSTOM =  @FILTER_CUSTOM+' AND CONVERT(NVARCHAR(MAX),'+filter_column3+') = '+filter_column_value3
    END
    IF(@filter_column4 != '' AND @filter_column_value4 != '')
    BEGIN
        SET @FILTER_CUSTOM =  @FILTER_CUSTOM+' AND CONVERT(NVARCHAR(MAX),'+filter_column4+') = '+filter_column_value4
    END
    IF( @FILTER_CUSTOM  != '')
    BEGIN
        SET @FILTER_CUSTOM = 'AND ( '+@FILTER_CUSTOM+' )'
    END

	IF(ISDATE(@from) = 1 AND ISDATE(@to) = 1)
	BEGIN
		DECLARE @SQL_FROMTO NVARCHAR(MAX) = '( CONVERT(DATE,'+@fromToBy+') >= CONVERT(DATE,'''+@from+''') AND CONVERT(DATE,'+@fromToBy+') <=  CONVERT(DATE,'''+@to+''') )';
		SET @SQL = ('SELECT COUNT(*) FROM '+@table_name+' WHERE '+  @SQL_FILTER + ' AND ' + @SQL_FROMTO +' '+@FILTER_CUSTOM+) 
	END
	ELSE
	BEGIN
		SET @SQL = ('SELECT COUNT(*) FROM '+@table_name+' WHERE '+  @SQL_FILTER +' '+@FILTER_CUSTOM+) 
	END
	PRINT @SQL
	EXEC (@SQL)
END