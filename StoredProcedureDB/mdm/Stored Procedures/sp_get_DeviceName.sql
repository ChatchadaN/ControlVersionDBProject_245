-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_DeviceName]
	-- Add the parameters for the stored procedure here
	  @device_names			NVARCHAR(MAX)	= NULL
	, @package				NVARCHAR(MAX)	= NULL
	, @assy_name			NVARCHAR(MAX)	= NULL
	, @ft_name				NVARCHAR(MAX)	= NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT [device_names].[id]
		  ,[packages].[name]		AS package 
		  ,[device_names].[name]	AS device_names
		  ,[assy_name]
		  ,[ft_name]
		  ,[rank]
		  ,[tp_rank]
		  ,ISNULL([pcs_per_pack],0) AS [pcs_per_pack]
		  ,ISNULL([is_incoming],0) AS [is_incoming]

		  ,[is_automotive]
		  ,[required_ul_logo]
		  ,[is_assy_only]
		  ,[number_of_chips]
		  ,[official_number]
		  ,[mno]
		  ,[priority]
		  ,[strip_row_number]
		  ,[strip_column_number]
		  ,[is_memory_device]
		  ,[universal_tp_rank]

	  FROM [APCSProDB].[method].[device_names]
	  INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
	   WHERE ([device_names].[name] = @device_names	 OR ISNULL(@device_names	,'') = '')
		AND ([packages].[name] = @package OR ISNULL(@package,'') = '')
		AND ([assy_name] = @assy_name OR ISNULL(@assy_name,'') = '')
		AND ([ft_name] = @ft_name OR ISNULL(@ft_name,'') = '')

	END
END
