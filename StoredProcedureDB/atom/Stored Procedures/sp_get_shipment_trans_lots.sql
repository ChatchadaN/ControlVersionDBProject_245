
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_shipment_trans_lots]	-- Add the parameters for the stored procedure here	
(
	@LotId INT = null

)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	select [lots].[id] as LotId
	, [lots].[lot_no] as LotNo
	, [packages].[name] as Package 
	, [device_names].[assy_name] as Device
	, CONCAT([device_names].[tp_rank], ' Ver ' , CONVERT(varchar(3),[device_slips].[version_num])) as TPRank
	, [package_groups].[name] as Package_Group
	 
	from [APCSProDB].[method].[package_groups] with (NOLOCK) 
	inner join [APCSProDB].[method].[packages] with (NOLOCK) 
	on [packages].[package_group_id] = [package_groups].[id]
	inner join [APCSProDB].[method].[device_names] with (NOLOCK)
	on [device_names].[package_id] = [packages].[id]
	inner join [APCSProDB].[trans].[lots] with (NOLOCK) 
	on [lots].[act_device_name_id] = [device_names].[id]
	inner join [APCSProDB].[method].[device_slips] with (NOLOCK) 
	on [device_slips].[device_slip_id] = [lots].[device_slip_id]

	WHERE lots.id =  @LotId
	order by [lots].[lot_no]
END
