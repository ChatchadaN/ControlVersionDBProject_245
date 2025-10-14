---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_stock_in_pc_receiving_001]
	-- Add the parameters for the stored procedure here

			 @location_id				INT
           , @category_id				INT
           , @po_id						INT
           , @production_id				INT
           , @invoice_number  			VARCHAR(50)
           , @lot_number	 			VARCHAR(50)
           , @package_unit				VARCHAR(5)
           , @receive_unit				VARCHAR(5)
           , @order_qty					DECIMAL
           , @package_qty				DECIMAL
           , @receiving_qty	 			DECIMAL
           , @expiry_condition			VARCHAR(200)
           , @expiry_date				DATETIME 
		   , @emp_id					INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	DECLARE @mat_record_id INT 
	 
	BEGIN TRANSACTION
	BEGIN TRY  
			  
				INSERT INTO APCSProDB.[trans].[material_receiving_process]
				(		 
						 [location_id]
					   , [category_id]
					   , [po_id]
					   , [product_id]
					   , [invoice_number] 
					   , [lot_number]
					   , [package_unit]
					   , [receive_unit]
					   , [order_qty]
					   , [package_qty]
					   , [receiving_qty]
					   , [expiry_condition]
					   , [expiry_date]
					   , [is_frame_type] 
					   , [status]
					   , [created_at]
					   , [created_by]
				)
				 VALUES
				(		 @location_id --
					   , @category_id
					   , @po_id
					   , @production_id
					   , @invoice_number	--  
					   , @lot_number	--
					   , @package_unit
					   , @receive_unit
					   , @order_qty
					   , @package_qty
					   , @receiving_qty	--
					   , @expiry_condition
					   , @expiry_date
					   , 'False' 
					   , 'W'
					   , GETDATE() 
					   , @emp_id
				)

		 

				SELECT    'TRUE'						AS Is_Pass 
						, 'Data saved successfully.'	AS Error_Message_ENG
						, N'บันทึกข้อมูลสำเร็จ'				AS Error_Message_THA	
						, ''							AS Handling	
			COMMIT;
	 
	END TRY
	BEGIN CATCH
		ROLLBACK;

			SELECT   'FALSE'							AS Is_Pass 
					, ERROR_MESSAGE()					AS Error_Message_ENG
					, N'การบันทึกข้อมูลผิดพลาด !!'			AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ material'	AS Handling

	END CATCH


END
