-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_set_data_interface_receive_halfproduct]
	-- Add the parameters for the stored procedure here
	@type_table INT ---1: half_product_order_list, 2: half_product_rohm_stock_list, 3: half_product_invoice_data
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
	IF (@type_table = 1) ---1: half_product_order_list
	BEGIN
		IF EXISTS(SELECT TOP 1 [lot_no] FROM [APCSProDB].[dbo].[half_product_order_list_temp])
		BEGIN
			-------------------------------------------------------------------------------------------------------
			-- (1) insert half_product_order_list_temp to half_product_order_list
			-------------------------------------------------------------------------------------------------------
   			MERGE [APCSProDB].[dbo].[half_product_order_list] AS [a]
			USING [APCSProDB].[dbo].[half_product_order_list_temp] AS [atemp] ON (
				[a].[order_no] = [atemp].[order_no] AND
				[a].[lot_no] = [atemp].[lot_no] AND
				[a].[outsource_lot_no] = [atemp].[outsource_lot_no] AND
				[a].[invoice_no] = [atemp].[invoice_no]
			) 
			WHEN NOT MATCHED BY TARGET 
				THEN INSERT ( [factory_code]
					, [throw_in_date]
					, [form_name]
					, [asssy_model_name]
					, [order_model_name]
					, [throw_in_rank]
					, [tp_rank]
					, [order_no]
					, [lot_no]
					, [outsource_lot_no]
					, [invoice_no]
					, [mno]
					, [qty]
					, [datetime_stamp] ) 
				VALUES ( [atemp].[factory_code]
					, [atemp].[throw_in_date]
					, [atemp].[form_name]
					, [atemp].[asssy_model_name]
					, [atemp].[order_model_name]
					, [atemp].[throw_in_rank]
					, [atemp].[tp_rank]
					, [atemp].[order_no]
					, [atemp].[lot_no]
					, [atemp].[outsource_lot_no]
					, [atemp].[invoice_no]
					, [atemp].[mno]
					, [atemp].[qty]
					, GETDATE() );
		END
		ELSE
		BEGIN
			RETURN;
		END
	END
	ELSE IF (@type_table = 2) ---2: half_product_rohm_stock_list
	BEGIN
		IF EXISTS(SELECT TOP 1 [ft_lot_no] FROM [APCSProDB].[dbo].[half_product_rohm_stock_list_temp])
		BEGIN
			-------------------------------------------------------------------------------------------------------
			-- (1) insert half_product_rohm_stock_list_temp to half_product_rohm_stock_list
			-------------------------------------------------------------------------------------------------------
   			MERGE [APCSProDB].[dbo].[half_product_rohm_stock_list] AS [a]
			USING [APCSProDB].[dbo].[half_product_rohm_stock_list_temp] AS [atemp] ON ( 
				[a].[ft_lot_no] = [atemp].[ft_lot_no] AND
				[a].[ft_device_name] = [atemp].[ft_device_name] AND
				[a].[invoice_no] = [atemp].[invoice_no]
			) 
			WHEN NOT MATCHED BY TARGET 
				THEN INSERT ( [factory_code]
				  , [ft_lot_no]
				  , [ft_device_name]
				  , [stock_date]
				  , [quantity]
				  , [invoice_no]
				  , [hold_flag]
				  , [datetime_stamp] ) 
				VALUES ( [atemp].[factory_code]
				  , [atemp].[ft_lot_no]
				  , [atemp].[ft_device_name]
				  , [atemp].[stock_date]
				  , [atemp].[quantity]
				  , [atemp].[invoice_no]
				  , [atemp].[hold_flag]
				  , GETDATE() );
		END
		ELSE
		BEGIN
			RETURN;
		END
	END
	ELSE IF (@type_table = 3) ---3: half_product_invoice_data
	BEGIN
		IF EXISTS(SELECT TOP 1 [switch_invoice_no] FROM [APCSProDB].[dbo].[half_product_invoice_data_temp])
		BEGIN
			-------------------------------------------------------------------------------------------------------
			-- (1) insert half_product_invoice_data to half_product_invoice_data_temp
			-------------------------------------------------------------------------------------------------------
   			MERGE [APCSProDB].[dbo].[half_product_invoice_data] AS [a]
			USING [APCSProDB].[dbo].[half_product_invoice_data_temp] AS [atemp] ON (
				[a].[switch_invoice_no] = [atemp].[switch_invoice_no] AND
				[a].[line_no] = [atemp].[line_no] AND
				[a].[send_order_no] = [atemp].[send_order_no]
			) 
			WHEN NOT MATCHED BY TARGET 
				THEN INSERT ( [switch_invoice_no]
					, [line_no]
					, [original_invoice_no]
					, [product_name]
					, [send_order_no]
					, [quantity]
					, [unit_price]
					, [amount]
					, [check_flag]
					, [date_upload]
					, [date_receive] ) 
				VALUES ( [atemp].[switch_invoice_no]
					, [atemp].[line_no]
					, [atemp].[original_invoice_no]
					, [atemp].[product_name]
					, [atemp].[send_order_no]
					, [atemp].[quantity]
					, [atemp].[unit_price]
					, [atemp].[amount]
					, [atemp].[check_flag]
					, [atemp].[date_upload]
					, NULL );
		END
		ELSE
		BEGIN
			RETURN;
		END
	END
END