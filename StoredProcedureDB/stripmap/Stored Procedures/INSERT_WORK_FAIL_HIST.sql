-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[INSERT_WORK_FAIL_HIST]
	-- Add the parameters for the stored procedure here
	@WORK_NO	INT,
	@BIN_ID		INT,
	@PCS		INT,
	@RECORD_ID	INT

AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	insert APCSProDB.trans.work_fail_records
	(
		update_record_id,
		work_id,
		job_id,
		fail_bin_id,
		pcs
	)
	select
		@RECORD_ID,
		WK.id,
		LO.act_job_id,
		@BIN_ID,
		@PCS
	from APCSProDB.trans.works as WK
	inner join APCSProDB.trans.lots as LO on LO.id = WK.lot_id
	where WK.id = @WORK_NO

	return @@ROWCOUNT
END
