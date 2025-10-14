-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_materialsetlist]
	-- Add the parameters for the stored procedure here
	@matset AS int,
	@matid AS INT,
	@use_qty AS DECIMAL(18,6),
	@use_qty_unit AS INT,
	@limit_time_unit1 AS INT,
	@time_limit1 AS INT,
	@time_warn1 AS INT,
	@tomson_code AS INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE [APCSProDB].[method].[material_set_list]
		SET 
			use_qty =  @use_qty,
			use_qty_unit = @use_qty_unit,
			limit_time_unit1 = @limit_time_unit1,
			time_limit1 = @time_limit1,
			time_warn1 = @time_warn1, 
			tomson_code = @tomson_code
		WHERE id = @matset and material_group_id = @matid

		--HISTORY
		INSERT INTO [APCSProDB].method_hist.material_set_list_hist
		(
			  [category]
			  ,[id]
			  ,[idx]
			  ,[material_group_id]
			  ,[use_qty]
			  ,[use_qty_unit]
			  ,[limit_time_unit1]
			  ,[time_limit1]
			  ,[time_warn1]
			  ,[tomson_code]
		)
		(
		SELECT 2 -- Update
			,[id]
			,[idx]
			,[material_group_id]
			,[use_qty]
			,[use_qty_unit]
			,[limit_time_unit1]
			,[time_limit1]
			,[time_warn1]
			,[tomson_code]
		FROM [APCSProDB].[method].[material_set_list]
		WHERE id = @matset and material_group_id = @matid
		)

		SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
