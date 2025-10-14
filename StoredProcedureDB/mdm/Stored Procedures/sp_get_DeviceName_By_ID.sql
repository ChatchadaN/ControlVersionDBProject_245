-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_DeviceName_By_ID]
	-- Add the parameters for the stored procedure here
	@id	AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		SELECT [device_names].[id]
		  ,[packages].[name]		AS package 
		  ,[device_names].[name]	AS device_names
		  ,[assy_name]
		  ,[ft_name]
		  ,[tp_rank]
		  ,ISNULL([pcs_per_pack],0) AS [pcs_per_pack]
		  ,ISNULL([is_incoming],0) AS [is_incoming]
	  FROM [APCSProDB].[method].[device_names]
	  INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
	  WHERE [device_names].[id] = @id 
END
