-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [atom].[sp_set_data_inventory]
(	    @state			INT
	,	@emp_no			NVARCHAR(6)
 )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 DECLARE	  @lot_id		INT 
				, @lot_no		NVARCHAR(MAX) 
				, @user_id		INT
				, @stock_class  NVARCHAR(10)


			SET @user_id =  (SELECT users.id  FROM  APCSProDB.man.users WHERE emp_num   = @emp_no )


BEGIN TRANSACTION;
  BEGIN TRY

	   IF (@state = 1)
	   BEGIN 
				IF NOT EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lot_inventory]
								LEFT JOIN [APCSProDB].[trans].[lot_inventory_hist]
								ON [lot_inventory_hist].lot_id =  [lot_inventory].lot_id
								AND [lot_inventory_hist].year_month =  [lot_inventory].year_month
								AND [lot_inventory_hist].stock_class =[lot_inventory].stock_class
								WHERE  [lot_inventory_hist].year_month  IS NULL  
								)
			 
				BEGIN  
						SELECT	  'FALSE'											AS Is_Pass 
								, 'Data not found for then lot inventory'		AS Error_Message_ENG
								, N'ไม่พบข้อมูล lot inventory'					AS Error_Message_THA 
								, ''												AS Handling
						COMMIT;
						RETURN
				END
				ELSE
				BEGIN 
	
					INSERT INTO  [APCSProDB].[trans].[lot_inventory_hist]
					(
						  recorded_at
						, lot_id
						, lot_no
						, package_id
						, device_id
						, job_id
						, qty_pass
						, qty_hasuu
						, qty_out
						, qty_combined
						, location_id
						, [address]
						, fcoino
						, sheet_no
						, stock_class
						, classification_no
						, year_month
						, created_at
						, created_by 
					) 
					SELECT  GETDATE()   
						, [lot_inventory].lot_id
						, [lot_inventory].lot_no
						, [lot_inventory].package_id
						, [lot_inventory].device_id
						, [lot_inventory].job_id
						, [lot_inventory].qty_pass
						, [lot_inventory].qty_hasuu
						, [lot_inventory].qty_out
						, [lot_inventory].qty_combined
						, [lot_inventory].location_id
						, [lot_inventory].[address]
						, [lot_inventory].fcoino
						, [lot_inventory].sheet_no
						, [lot_inventory].stock_class
						, [lot_inventory].classification_no
						, [lot_inventory].year_month
						, [lot_inventory].created_at
						, [lot_inventory].created_by  	 
					FROM [APCSProDB].[trans].[lot_inventory]
					LEFT JOIN [APCSProDB].[trans].[lot_inventory_hist]
					ON [lot_inventory_hist].lot_id =  [lot_inventory].lot_id
					AND [lot_inventory_hist].year_month =  [lot_inventory].year_month
					AND [lot_inventory_hist].stock_class =[lot_inventory].stock_class
					WHERE  [lot_inventory_hist].year_month  IS NULL  
 
  

					SELECT	  'TRUE'					AS Is_Pass 
							, 'Backup data success.'	AS Error_Message_ENG
							, N'Backup data สำเร็จ'		AS Error_Message_THA 
							, ''						AS Handling

						COMMIT;
						RETURN

				END 

		END 

	   IF (@state = 2)
	   BEGIN 
				
				IF EXISTS ( SELECT 'xx' FROM [APCSProDB].[trans].[lot_inventory]
								LEFT JOIN [APCSProDB].[trans].[lot_inventory_hist]
								ON [lot_inventory_hist].lot_id =  [lot_inventory].lot_id
								AND [lot_inventory_hist].year_month		= [lot_inventory].year_month
								AND [lot_inventory_hist].stock_class	= [lot_inventory].stock_class
								WHERE  [lot_inventory_hist].year_month  IS NULL  
								)
			 
				BEGIN 
						SELECT	  'FALSE'											AS Is_Pass 
								, 'Inventory data has not been backed up yet'		AS Error_Message_ENG
								, N'ยังไม่ Back up data Inventory'						AS Error_Message_THA 
								, ''												AS Handling

						COMMIT;
						RETURN

				END
				ELSE
				BEGIN 

					DELETE APCSProDB.trans.lot_inventory   
				  

					SELECT	  'TRUE'					AS Is_Pass 
							, 'Delete data success.'	AS Error_Message_ENG
							, N'ลบข้อมูลสำเร็จ'				AS Error_Message_THA 
							, ''						AS Handling

						COMMIT;
						RETURN

				END 

		END 

	   IF (@state = 3)
	   BEGIN 
				IF NOT EXISTS (SELECT 'xx' FROM APCSProDB.trans.surpluses WHERE surpluses.in_stock IN (41, 4))
				BEGIN 
					SELECT	  'FALSE'											AS Is_Pass 
							, 'Data not found for then surpluses inventory'		AS Error_Message_ENG
							, N'ไม่พบข้อมูล surpluses inventory'					AS Error_Message_THA 
							, ''												AS Handling

						COMMIT;
						RETURN

				END
				ELSE
				BEGIN 

						 UPDATE APCSProDB.trans.surpluses
						 SET   in_stock	 = IIF(surpluses.in_stock = 4, 2 , 3)
				 			, updated_at = GETDATE()
				 			, updated_by = @user_id
						 FROM APCSProDB.trans.surpluses
						 WHERE surpluses.in_stock  IN (4, 41)
						  


						COMMIT;
					 
					 SELECT	  'TRUE'								AS Is_Pass 
							, 'update surpluses data success.'		AS Error_Message_ENG
							, N'แก้ไขข้อมูล surpluses สำเร็จ '			AS Error_Message_THA 
							, ''									AS Handling
							RETURN
				END 
		END		 

	END TRY
	BEGIN CATCH
		-------------------------------------------------------------------------------------------------------
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
		END

		SELECT	 'FALSE' AS [Is_Pass] 
				, ERROR_MESSAGE() AS [Error_Message_ENG]
				, ERROR_MESSAGE() AS [Error_Message_THA] 
				, N'กรุณาติดต่อ System' AS [Handling];
		RETURN;
		-------------------------------------------------------------------------------------------------------
	END CATCH
		 
	 
END
