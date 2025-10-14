
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/09/29>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE[material].[sp_set_production_001]
	-- Add the parameters for the stored procedure here
		  @supplier_cd				VARCHAR(10)			= NULL 
		, @code						VARCHAR(2)			= NULL 
		, @productions_name			NVARCHAR(100)		= NULL 
		, @spec						NVARCHAR(200)		= NULL 
		, @details					NVARCHAR(510)		= NULL 
		, @category_id				INT			   		= NULL 
		, @pack_std_qty				INT					= NULL 
		, @unit_code				INT					= NULL 
		, @arrival_std_qty			INT 				= NULL 
		, @min_order_qty			INT 				= NULL 
		, @lead_time				INT					= NULL 
		, @lead_time_unit			INT 				= NULL 
		, @expiration_base			INT 				= NULL 
		, @expiration_value			INT 				= NULL 
		, @expiration_unit			INT 				= NULL 
		, @is_disabled				INT					= 0  
		, @calculate_unit			DECIMAL(18,9)		= 0
		, @emp_id					INT					= 1
		, @item_cd					CHAR(8)				 
		, @po_supplier_cd			INT					= 0 
		 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  
	BEGIN TRY  
		
		IF EXISTS(SELECT 1 FROM [APCSProDB].[material].[productions] WHERE name = @productions_name)
		BEGIN
				SELECT    'FALSE'											AS Is_Pass
						, N'Data ('+(@productions_name)+') Duplicate'		AS Error_Message_ENG
						, N'ข้อมูล ('+(@productions_name)+') ลงทะเบียนแล้ว'		AS Error_Message_THA
						, ''												AS Handling 

		END 
		ELSE
		BEGIN 

			DECLARE   @productions_id INT	=  1

			EXEC [StoredProcedureDB].material.[sp_get_number_id]
					@TABLENAME		= 'productions.id'	
				, @NEWID			= @productions_id OUTPUT


			INSERT INTO [APCSProDB].[material].[productions]
					(
						     [id]
						   , [product_family_id]
						   , [supplier_cd]
						   , [code]
						   , [name]
						   , [spec]
						   , [details]
						   , [category_id]
						   , [pack_std_qty]
						   , [unit_code]
						   , [arrival_std_qty]
						   , [min_order_qty]
						   , [lead_time]
						   , [lead_time_unit]
						   , [label_issue_qty]
						   , [expiration_base]
						   , [expiration_unit]
						   , [expiration_value]
						   , [is_disabled] 
						   , [created_at]
						   , [created_by]
					 )
					 VALUES
					 (
						     @productions_id
						   , 1 
						   , @supplier_cd 
						   , @code 
						   , @productions_name
						   , @spec 
						   , @details 
						   , @category_id 
						   , @pack_std_qty 
						   , @unit_code 
						   , @arrival_std_qty 
						   , @min_order_qty 
						   , @lead_time 
						   , @lead_time_unit 
						   , 0
						   , @expiration_base 
						   , @expiration_unit 
						   , @expiration_value 
						   , @is_disabled  
						   , GETDATE()
						   , 1
						   )
						  

			INSERT INTO [APCSProDB].[material].[purchase_order_items]
			(		 
					 [item_cd]
				   , [item_name]
				   , [specification]
				   , [po_supplier_cd]
				   , [po_supplier_name]
				   , [material_id]
				   , [calculate_unit]
			)
			SELECT  
					 @item_cd
				   , podata.item
				   , podata.specification
				   , podata.suppliercode
				   , podata.suppliername
				   , (SELECT id FROM [APCSProDB].[material].[productions] WHERE name  = @productions_name)
				   , @calculate_unit
			 FROM  [APCSProDWH].oneworld.podata
			 WHERE itemcode = @item_cd AND suppliercode  = @po_supplier_cd

			SELECT    'TRUE' AS Is_Pass
					, N'('+(@productions_name)+') Successfully registered !!' AS Error_Message_ENG
					, N'('+(@productions_name)+') Successfully registered !!' AS Error_Message_THA
					, '' AS Handling 
		END  

		END TRY  
		BEGIN CATCH  
					SELECT    'FALSE'					AS Is_Pass 
							, N'Failed to register !!'	AS Error_Message_ENG
							, N'Failed to register !!'	AS Error_Message_THA 
							, ''						AS Handling

		END CATCH  


END
