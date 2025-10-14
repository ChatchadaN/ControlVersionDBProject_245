-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[INSERT_WORKS_HIST]
	-- Add the parameters for the stored procedure here
	@WORK_NO	INT,
	@RECORD_ID	INT,
	@USER_ID	INT

AS
BEGIN

	DECLARE @DAY_ID INT
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select @DAY_ID = D.id
	from APCSProDB.trans.days as D 
	where D.date_value = CONVERT(DATE,GETDATE())

	-- Insert statements for procedure here
	insert APCSProDB.trans.work_update_records
	(
		id,
		day_id,
		job_id,
		recorded_at,
		record_class,
		work_id,
		use_state,
		map_state
	)
	select
		@RECORD_ID,
		@DAY_ID,
		LO.act_job_id,
		GETDATE(),
		101,
		WK.id,
		WK.use_state,
		WK.map_state
	from APCSProDB.trans.works as WK
	inner join APCSProDB.trans.lots as LO on LO.id = WK.lot_id
	where WK.id = @WORK_NO

	return @@ROWCOUNT
END
