
-- =============================================
-- Author:		Chatchadaporn
-- Create date: 2024/08/22
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_process_receiving] 			
	 @material_receiving_process_id			INT 
   , @po_number								VARCHAR(20) 
   , @category_id							INT  
   , @production_id							INT 
   , @invoice_number						VARCHAR(50)
   , @lot_number							VARCHAR(50) 
   , @package_qty							DECIMAL(18,4)
   , @order_qty								DECIMAL(18,4) 
   , @receiving_qty							DECIMAL(18,4)
   , @receive_unit							VARCHAR(10) 
   , @expiry_date							DATETIME
   , @emp_id								INT			= NULL


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

		INSERT INTO APIStoredProDB.[dbo].[exec_sp_history]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no])
		SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [material].[sp_set_process_receiving_001] @id  = ''' + ISNULL(CAST(@material_receiving_process_id AS nvarchar(MAX)),'') 
				+ ''',@ponumber = ''' + ISNULL(CAST(@po_number AS nvarchar(MAX)),'') +  
				+ ''',@category_id = ''' + ISNULL(CAST(@category_id AS nvarchar(MAX)),'') +
				+ ''',@production_id = ''' + ISNULL(CAST(@production_id AS nvarchar(MAX)),'') +
				+ ''',@invoice_number = ''' + ISNULL(CAST(@invoice_number AS nvarchar(MAX)),'') +
				+ ''',@lot_number = ''' + ISNULL(CAST(@lot_number AS nvarchar(MAX)),'') +
				+ ''',@package_qty = ''' + ISNULL(CAST(@package_qty AS nvarchar(MAX)),'') +
				+ ''',@order_qty = ''' + ISNULL(CAST(@order_qty AS nvarchar(MAX)),'') +
				+ ''',@receiving_qty = ''' + ISNULL(CAST(@receiving_qty AS nvarchar(MAX)),'') +
				+ ''',@receive_unit = ''' + ISNULL(CAST(@receive_unit AS nvarchar(MAX)),'') +
				+ ''',@expiry_date = ''' + ISNULL(CAST(@expiry_date AS nvarchar(MAX)),'') +
				+ ''',@emp_id = ''' + ISNULL(CAST(@emp_id AS nvarchar(MAX)),'') +
				''''
			, @lot_number

	---- ########## VERSION 001 ##########

	EXEC [APIStoredProVersionDB].[material].[sp_set_process_receiving_001]
		 	 @material_receiving_process_id 	=  @material_receiving_process_id 
		   , @po_number 						=  @po_number 
		   , @category_id 						=  @category_id  
		   , @production_id						=  @production_id 
		   , @invoice_number 					=  @invoice_number 
		   , @lot_number 						=  @lot_number 
		   , @package_qty 						=  @package_qty 
		   , @order_qty 						=  @order_qty 
		   , @receiving_qty						=  @receiving_qty
		   , @receive_unit 						=  @receive_unit 
		   , @expiry_date 						=  @expiry_date 
		   , @emp_id 							=  @emp_id 

	---- ########## VERSION 001 ##########

END
