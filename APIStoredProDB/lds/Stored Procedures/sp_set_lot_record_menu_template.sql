-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_record_menu_template]
	@template_id INT, @extends_id NVARCHAR(MAX), @is_display BIT, @emp_code VARCHAR(6)
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
			, 'EXEC [lds].[sp_set_lot_record_menu_template_ver_001] @template_id = ''' + ISNULL(CAST(@template_id AS varchar),'') + ''', @extends_id = ''' + ISNULL(CAST(@extends_id AS varchar(MAX)),'') + ''', @is_display = ' 
				+ ISNULL(CAST(@is_display AS varchar),'') + ', @emp_code = ''' + ISNULL(CAST(@emp_code AS varchar),'') + '''' ;

	EXEC [APIStoredProVersionDB].[lds].[sp_set_lot_record_menu_template_ver_001]
		@template_id = @template_id, 
		@extends_id = @extends_id,
		@is_display = @is_display,
		@emp_code = @emp_code

END
