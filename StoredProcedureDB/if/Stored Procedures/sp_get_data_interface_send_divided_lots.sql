-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_send_divided_lots]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT CAST([lots].[lot_no] AS VARCHAR(10)) AS [lot_no]
	FROM [APCSProDWH].[atom].[divided_lots]
	INNER JOIN [APCSProDB].[trans].[lots] ON [divided_lots].[lot_id] = [lots].[id]
	WHERE [divided_lots].[is_create_text] = 0;
END