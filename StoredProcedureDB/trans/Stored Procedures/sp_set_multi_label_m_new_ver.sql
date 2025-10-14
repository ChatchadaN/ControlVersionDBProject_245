-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_multi_label_m_new_ver]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here

	IF EXISTS(SELECT TOP 1 [ROHM_Model_Name] FROM [APCSProDWH].[atom].[multi_label_m_table])
	BEGIN
		DELETE FROM [APCSProDWH].[dbo].[MULTI_LABEL_M];

		INSERT INTO [APCSProDWH].[dbo].[MULTI_LABEL_M]
		SELECT * FROM [APCSProDWH].[atom].[multi_label_m_table];
 
		DELETE FROM [APCSProDWH].[atom].[multi_label_m_table];
		RETURN;
	END
	ELSE
	BEGIN
		RETURN;
	END
END
