-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_create_lot_record_column]
	@column_name varchar(50), @json_name varchar(50), @data_type varchar(20), @description nvarchar(255) = null, @emp_code varchar(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO APIStoredProDB.[dbo].[exec_sp_history]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text])
	SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [lds].[sp_create_lot_record_column_ver_001] @column_name = ''' + ISNULL(CAST(@column_name AS varchar(50)),'') + ''', @json_name = ''' + ISNULL(CAST(@json_name AS varchar(50)),'') + ''', @data_type = ''' 
				+ ISNULL(CAST(@data_type AS varchar),'') + ''', @description = ''' + ISNULL(CAST(@description AS nvarchar(255)),'') + ''', @emp_code = ''' + ISNULL(CAST(@emp_code AS varchar),'') + '''' ;

	EXEC [APIStoredProVersionDB].[lds].[sp_create_lot_record_column_ver_001]
		@column_name = @column_name, 
		@json_name = @json_name, 
		@data_type = @data_type, 
		@description = @description, 
		@emp_code = @emp_code

END
