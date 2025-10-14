-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[UPDATE_SUB_WORKS_INFO]
	-- Add the parameters for the stored procedure here
	@WORK_NO	INT,
	@X			INT,
	@Y			INT,
	@BIN_ID		INT,
	@STEP_NO	INT,
	@RECORD_ID	INT,
	@USER_ID	INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update SW SET
		 SW.bin_id = @BIN_ID,
		 SW.job_id = DF.job_id,
		 SW.bin_id_histories = case when SW.bin_id_histories is null then CAST(@BIN_ID as varchar(10)) else SW.bin_id_histories + ',' + CAST(@BIN_ID as varchar(10)) end,
		 SW.update_record_id_histories = case when SW.update_record_id_histories is null then CAST(@RECORD_ID as varchar(10)) else SW.update_record_id_histories + ',' + CAST(@RECORD_ID as varchar(10)) end,
		 SW.updated_by = @USER_ID,
		 SW.updated_at = GETDATE()
	from APCSProDB.trans.sub_works as SW
	inner join APCSProDB.trans.works as WK on WK.id = SW.work_id
	inner join APCSProDB.trans.lots as LO on LO.id = WK.lot_id
	inner join APCSProDB.method.device_flows as DF on DF.device_slip_id = LO.device_slip_id and DF.step_no = @STEP_NO
    WHERE SW.work_id = @WORK_NO and SW.x = @X and SW.y = @Y
		
	return @@ROWCOUNT
END
