
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/09/25>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_set_stock_in_pc_receiving]
			  
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

		EXEC [APIStoredProVersionDB].[material].[sp_set_stock_in_pc_receiving_001]
			 
			  @location_id			=  @location_id		
			 ,@category_id			=  @category_id		
			 ,@po_id				=  @po_id					
			 ,@production_id		=  @production_id		
			 ,@invoice_number  		=  @invoice_number  		
			 ,@lot_number	 		=  @lot_number	 	
			 ,@package_unit			=  @package_unit		
			 ,@receive_unit			=  @receive_unit		
			 ,@order_qty			=  @order_qty				
			 ,@package_qty			=  @package_qty		
			 ,@receiving_qty	 	=  @receiving_qty	 		 	
			 ,@expiry_condition		=  @expiry_condition		
			 ,@expiry_date			=  @expiry_date		
			 ,@emp_id				=  @emp_id			
		 
END
