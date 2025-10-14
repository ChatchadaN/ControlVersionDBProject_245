-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_device_name]
	-- Add the parameters for the stored procedure here
	@id	AS INT,
	@pcs_per_pack	AS INT,
	@is_incoming    AS INT,
	@updated_by		AS INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		 
			----///////////////// Update Device Name 
			UPDATE	[APCSProDB].[method].[device_names] 
			SET		[pcs_per_pack]	= @pcs_per_pack ,
					[is_incoming]	= @is_incoming , 
					[updated_at]	= GETDATE(),
					[updated_by]	= @updated_by	
			WHERE	[id] = @id

			--/////////////////// Insert History
			INSERT INTO [APCSProDB].[method_hist].[device_names_hist]
           (	 
				   [category]
				  ,[id]
				  ,[name]
				  ,[assy_name]
				  ,[ft_name]
				  ,[rank]
				  ,[tp_rank]
				  ,[package_id]
				  ,[based_assy_name_id]
				  ,[is_automotive]
				  ,[required_ul_logo]
				  ,[is_assy_only]
				  ,[number_of_chips]
				  ,[pcs_per_pack]
				  ,[official_number]
				  ,[mno]
				  ,[priority]
				  ,[strip_row_number]
				  ,[strip_column_number]
				  ,[alias_package_group_id]
				  ,[created_at]
				  ,[created_by]
				  ,[updated_at]
				  ,[updated_by]
				  ,[is_memory_device]
				  ,[universal_tp_rank]
				  ,[sub_material_set_id]
				  ,[is_incoming]
				  ,[master_device_name_id]
				  ,[master_branch_no]
		   )
		   (
			SELECT	 2 -- Update
				  ,[id]
				  ,[name]
				  ,[assy_name]
				  ,[ft_name]
				  ,[rank]
				  ,[tp_rank]
				  ,[package_id]
				  ,[based_assy_name_id]
				  ,[is_automotive]
				  ,[required_ul_logo]
				  ,[is_assy_only]
				  ,[number_of_chips]
				  ,[pcs_per_pack]
				  ,[official_number]
				  ,[mno]
				  ,[priority]
				  ,[strip_row_number]
				  ,[strip_column_number]
				  ,[alias_package_group_id]
				  ,[created_at]
				  ,[created_by]
				  ,[updated_at]
				  ,[updated_by]
				  ,[is_memory_device]
				  ,[universal_tp_rank]
				  ,[sub_material_set_id]
				  ,[is_incoming]
				  ,[master_device_name_id]
				  ,[master_branch_no]
			FROM   [APCSProDB].[method].[device_names] 
			WHERE  [id] = @id
			)

		COMMIT; 
		SELECT 'TRUE' AS Is_Pass, 'Successed !!' AS Error_Message_ENG, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA		
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass, 'Update Faild !!' AS Error_Message_ENG, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
