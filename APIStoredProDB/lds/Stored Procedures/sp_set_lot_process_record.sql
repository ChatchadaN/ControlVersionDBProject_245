-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_process_record]
	@strcolumn_common varchar(max), 
	@strvalue_common nvarchar(max), 
	@strcolumn_extends varchar(max), 
	@strvalue_extends nvarchar(max), 
	@process_id int , 
	@template_name varchar(50)
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
			, 'EXEC [lds].[sp_set_lot_process_record_ver_001] @strcolumn_common = ''' + ISNULL(CAST(@strcolumn_common AS varchar(max)),'') + ''', @strvalue_common = ''' + ISNULL(CAST(@strvalue_common AS nvarchar(max)),'') + 
				', @strcolumn_extends = ''' + ISNULL(CAST(@strcolumn_extends AS varchar(max)),'') + ''', @strvalue_extends = ''' + ISNULL(CAST(@strvalue_extends AS nvarchar(max)),'') +
				''', @process_id = ' + ISNULL(CAST(@process_id AS varchar),'') + ', @template_name = ''' + ISNULL(CAST(@template_name AS varchar),'') + '''';

	EXEC [APIStoredProVersionDB].[lds].[sp_set_lot_process_record_ver_001]
		@strcolumn_common = @strcolumn_common, 
		@strvalue_common =  @strvalue_common, 
		@strcolumn_extends = @strcolumn_extends, 
		@strvalue_extends = @strvalue_extends, 
		@process_id = @process_id , 
		@template_name = @template_name

END
