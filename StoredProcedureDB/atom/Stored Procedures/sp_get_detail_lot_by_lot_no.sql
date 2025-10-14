-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_detail_lot_by_lot_no]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	SELECT TRIM([lots].[lot_no]) AS lot_no
		, [packages].[name] AS [package_name]
		, [device_names].[name] AS [device_name]
		, [device_names].[assy_name] AS [assy_name]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	WHERE [lots].[lot_no] = @lot_no;
END
