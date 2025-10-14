-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_flow_slip] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id int = 0
    -- Insert statements for procedure here

	select @lot_id = id from APCSProDB.trans.lots where lot_no = @lotno

	select [device_flows].[step_no]
		, [device_flows].[is_skipped]
		, [jobs].[name] as job_name
	from [APCSProDB].[method].[device_flows]
	inner join [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
	where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id)
	and [device_flows].[is_skipped] != 1

END
