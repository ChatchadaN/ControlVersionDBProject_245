-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_mslevel_new_ver_002]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here

	IF EXISTS(SELECT TOP 1 [Product_Name] FROM [APCSProDWH].[atom].[mslevel_data_table])
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION Tran_MsLevel

			TRUNCATE TABLE [APCSProDB].[method].[mslevel_data]

			--DELETE FROM [APCSProDWH].[atom].[mslevel_data] WITH (HOLDLOCK)

			INSERT INTO [APCSProDB].[method].[mslevel_data]
			SELECT * FROM [APCSProDWH].[atom].[mslevel_data_table] WITH (HOLDLOCK)
 
			COMMIT TRANSACTION Tran_MsLevel
		END TRY 
		BEGIN CATCH
			ROLLBACK TRANSACTION Tran_MsLevel
		END CATCH

		--DELETE FROM [APCSProDWH].[atom].[mslevel_data_table]
		TRUNCATE TABLE [APCSProDWH].[atom].[mslevel_data_table];
	END
	ELSE
	BEGIN
		RETURN;
	END
END
