-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_transaction]
	@strcolumn varchar(max), @strvalue nvarchar(max), @process_id int, @transaction_id INT OUTPUT
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
			, 'EXEC [lds].[sp_set_lot_transaction_ver_001] @strcolumn = ''' + ISNULL(CAST(@strcolumn AS varchar(max)),'') + ''', @strvalue = ''' + ISNULL(CAST(@strvalue AS nvarchar(max)),'') + ''', @process_id = ' 
				+ ISNULL(CAST(@process_id AS varchar),'');

	EXEC [APIStoredProVersionDB].[lds].[sp_set_lot_transaction_ver_001]
		@strcolumn = @strcolumn, 
		@strvalue = @strvalue,
		@process_id = @process_id,
		@transaction_id = @transaction_id OUTPUT;

END
