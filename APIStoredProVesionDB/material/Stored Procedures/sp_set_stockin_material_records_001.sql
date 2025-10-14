
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/09/29>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_stockin_material_records_001]
	-- Add the parameters for the stored procedure here
		  @material_id				INT 		 
		, @emp_id					INT  
		, @from_location_id			INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE	  @mat_record_id_in				INT 
			, @mat_record_id_out			INT 
			, @outgoings_id					INT  
			, @outgoing_items_id			INT 
			, @day_id						INT
			, @get_date						DATETIME  = GETDATE()


  
	BEGIN TRANSACTION
	BEGIN TRY 
	 	
			EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
					  @TABLENAME		= 'material_records.id'	
					, @NEWID			= @mat_record_id_out OUTPUT			
			
			EXEC [StoredProcedureDB].[trans].[sp_get_day_id]
					  @DATE_VALUE		= @get_date
					, @ID				= @day_id OUTPUT


			UPDATE APCSProDB.trans.materials
			SET label_issue_state	= 1
				, updated_at		=  GETDATE()
				, updated_by		=  @emp_id 
			WHERE id =  @material_id
			
			INSERT INTO [APCSProDB].[trans].[material_records]
			(	  
					  [id]
					, [day_id]
					, [recorded_at]
					, [operated_by]
					, [record_class]
					, [material_id]
					, [barcode]
					, [material_production_id]
					, [step_no]
					, [in_quantity]
					, [quantity]
					, [fail_quantity]
					, [pack_count]
					, [limit_base_date]
					, [contents_list_id]
					, [is_production_usage]
					, [material_state]
					, [process_state]
					, [qc_state]
					, [first_ins_state]
					, [final_ins_state]
					, [limit_state]
					, [limit_date]
					, [extended_limit_date]
					, [open_limit_date1]
					, [open_limit_date2]
					, [wait_limit_date]
					, [location_id]
					, [acc_location_id]
					, [lot_no]
					, [qc_comment_id]
					, [qc_memo_id]
					, [arrival_material_id]
					, [parent_material_id]
					, [dest_lot_id]
					, [created_at]
					, [created_by] 
			)
			SELECT	  @mat_record_id_out AS [id]
					, @day_id
					, GETDATE() AS [recorded_at]
					, @emp_id
					, 1 AS [recored_class]
					, materials.[id] AS [material_id]
					, [barcode] 
					, [material_production_id]
					, [step_no]
					, [in_quantity]
					, [quantity]
					, [fail_quantity]
					, [pack_count]
					, [limit_base_date] AS [limit_base_date]
					, NULL AS [contents_list_id]
					, [is_production_usage]
					, [material_state] AS [material_state]
					, [process_state] AS [process_state]
					, [qc_state]
					, [first_ins_state]
					, [final_ins_state]
					, [limit_state]
					, [limit_date]
					, [extended_limit_date]
					, [open_limit_date1]
					, [open_limit_date2]
					, [wait_limit_date]
					, @from_location_id 
					, [acc_location_id]
					, [lot_no]
					, [qc_comment_id]
					, [qc_memo_id]
					, [arrival_material_id]
					, [parent_material_id]
					, [dest_lot_id]
					, materials.[created_at]
					, materials.[created_by]  
			FROM  APCSProDB.trans.materials  
			WHERE materials.id  = @material_id
			 

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
