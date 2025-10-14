-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_materialsetlist]
	-- Add the parameters for the stored procedure here
	@matset AS int,
	@matid AS INT,
	@qty AS DECIMAL(18,6),
	@qtyunit AS INT,
	@timeunit AS INT,
	@time AS INT,
	@warn AS INT,
	@tomsoncode AS INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--Check Material Set Exists
	IF EXISTS(SELECT 1 FROM [APCSProDB].[method].[material_set_list] WHERE id = @matset AND material_group_id = @matid)BEGIN
		SELECT 'FALSE' AS Is_Pass,'Material is duplicate. !!' AS Error_Message_ENG,N'ไม่สามารถลงทะเบียน Material ซ้ำกันได้ !!' AS Error_Message_THA
		RETURN
	END
	
	BEGIN TRANSACTION
	BEGIN TRY

	DECLARE @idx AS INT
	SET @idx = (SELECT ISNULL(MAX(idx),0) +1 FROM [APCSProDB].[method].[material_set_list] WHERE id = @matset)

		INSERT INTO [APCSProDB].[method].[material_set_list]
			   ([id]
			   ,[idx]
			   ,[material_group_id]
			   ,[use_qty]
			   ,[use_qty_unit]
			   ,[limit_time_unit1]
			   ,[time_limit1]
			   ,[time_warn1]
			   ,[tomson_code])		   
		 VALUES
			   (@matset
			   ,@idx
			   ,@matid
			   ,@qty
			   ,@qtyunit
			   ,@timeunit
			   ,@time
			   ,@warn
			   ,CASE WHEN @tomsoncode = 0 THEN NULL ELSE @tomsoncode END)

		SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
