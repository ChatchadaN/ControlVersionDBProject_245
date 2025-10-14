-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_clear_inventory]
	    @id		INT
	,	@emp_no NVARCHAR(MAX)
 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 DECLARE	  @lot_id		INT 
				, @lot_no		NVARCHAR(MAX) 
				, @user_id		INT
				, @stock_class  NVARCHAR(10)

  BEGIN TRY

				 SELECT   @lot_id	=  lot_id 
						, @lot_no	=  lot_no
						, @stock_class = stock_class
				 FROM [APCSProDB].[trans].[lot_inventory] 
				 WHERE lot_inventory.id =  @id

			IF (@stock_class = 01) 
			BEGIN
				 
				 DELETE APCSProDB.trans.lot_inventory  
				 WHERE lot_inventory.id =  @id

				SELECT	  'TRUE'					AS Is_Pass 
						, 'Delete data success.'	AS Error_Message_ENG
						, N'ลบข้อมูลสำเร็จ'				AS Error_Message_THA 
						, ''						AS Handling

			END
			ELSE
			BEGIN 

				 UPDATE APCSProDB.trans.surpluses
				 SET   in_stock	 = 2
				 	, updated_at = GETDATE()
				 	, updated_by = @user_id
				 WHERE lot_id = @lot_id
				 
				 EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] 
						@lotno					= @lot_no
				 	,	@sataus_record_class	= 2
				 	,	@emp_no_int				= 1


				 DELETE APCSProDB.trans.lot_inventory  
				 WHERE lot_inventory.id =  @id

					 
				 SELECT	  'TRUE'					AS Is_Pass 
						, 'Delete data success.'	AS Error_Message_ENG
						, N'ลบข้อมูลสำเร็จ'				AS Error_Message_THA 
						, ''						AS Handling

			END

			END TRY
			BEGIN CATCH
			ROLLBACK;
				SELECT	  'FALSE'				AS Is_Pass
						, 'Delete Faild !!'		AS Error_Message_ENG
						, N'ลบข้อมูลผิดพลาด !!'	AS Error_Message_THA
						, ''					AS Handling
			END CATCH
		 
	 
END
