-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[GET_EDITABLE_BIN_CODE]
	-- Add the parameters for the stored procedure here
	@WORK_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select DISTINCT
		BD.id as BIN_ID,
		BD.bin_description as BIN_DEF,
		BD.die_quality as STATUS,
		BD.custom_display_color as DEFAULT_COLOR,
		BD.custom_display_color as CUSTOM_COLOR
	from APCSProDB.trans.works as WK with(nolock)
	inner join APCSProDB.trans.lots as LO with(nolock) on LO.id = WK.lot_id
	inner join APCSProDB.method.device_flows as DF with(nolock) on DF.device_slip_id = LO.device_slip_id and DF.step_no <= LO.step_no
	inner join APCSProDB.mc.model_bin_upload as MBU with(nolock) on MBU.bincode_set_id = DF.bincode_set_id
	inner join APCSProDB.mc.bin_definitions as BD with(nolock) on BD.id = MBU.bin_id
	where WK.id = @WORK_ID

	return @@ROWCOUNT
END
