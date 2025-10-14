-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_record_template]
	@id INT = NULL, @name varchar(50), @display_name nvarchar(50), @description nvarchar(255) = NULL, @emp_code varchar(6)
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
			, 'EXEC [lds].[sp_set_lot_record_template_ver_001] @id = ''' + ISNULL(CAST(@id AS varchar),'') + ''', @name = ''' + ISNULL(CAST(@name AS varchar(50)),'') + ''', @display_name =''' 
				+ ISNULL(CAST(@display_name AS nvarchar(50)),'') + ''', @description = ''' + ISNULL(CAST(@description AS nvarchar(255)),'') + ''', @emp_code = ''' + ISNULL(CAST(@emp_code AS varchar),'') + '''' ;

	EXEC [APIStoredProVersionDB].[lds].[sp_set_lot_record_template_ver_001]
		@id = @id, 
		@name = @name, 
		@display_name = @display_name, 
		@description = @description, 
		@emp_code = @emp_code

END
