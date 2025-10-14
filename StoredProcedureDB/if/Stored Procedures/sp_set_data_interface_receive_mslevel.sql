-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_set_data_interface_receive_mslevel]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here

	IF EXISTS(SELECT TOP 1 [Product_Name] FROM [APCSProDWH].[atom].[mslevel_data_table])
	BEGIN
		DELETE FROM [APCSProDB].[method].[mslevel_data];

		INSERT INTO [APCSProDB].[method].[mslevel_data]
		SELECT * FROM [APCSProDWH].[atom].[mslevel_data_table];
 
		RETURN;
	END
	ELSE
	BEGIN
		RETURN;
	END
END