-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_multichip_after_edit_FinalInsp]
	-- Add the parameters for the stored procedure here
	@child_Id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @master_Id int
	declare @master_pnashi int
	declare @master_frontNG int
	declare @master_lotNo varchar(10)
	declare @master_McNo varchar(10)
	declare @master_jobId int
    -- Insert statements for procedure here
	select @master_ID = lot_id from APCSProDB.trans.lot_multi_chips where child_lot_id = @child_Id
IF(@master_Id is null)
	BEGIN
		select 'False' as Is_Pass
	END
ELSE
	BEGIN
		select @master_pnashi = qty_p_nashi ,@master_lotNo = lot_no,@master_frontNG = qty_front_ng  from APCSProDB.trans.lots where id = @master_ID
		SELECT TOP (1)  @master_jobId = APCSProDB.trans.lot_process_records.job_id, @master_McNo = APCSProDB.mc.machines.name 
		FROM            APCSProDB.trans.lot_process_records INNER JOIN
								 APCSProDB.mc.machines ON APCSProDB.trans.lot_process_records.machine_id = APCSProDB.mc.machines.id
		WHERE        (APCSProDB.trans.lot_process_records.lot_id = @master_ID) AND (APCSProDB.trans.lot_process_records.record_class = 2) AND (APCSProDB.trans.lot_process_records.process_id = 2)
		ORDER BY APCSProDB.trans.lot_process_records.recorded_at DESC

		IF(@master_McNo is null or @master_jobId is null )
			BEGIN
				select 'False' as Is_Pass
			END
		ELSE
			BEGIN
				select 'True' as Is_Pass,@master_pnashi as DB1_p_nashi ,@master_frontNG as DB1_front_ng ,@master_lotNo as DB1_lotno,@master_McNo as DB1_mcno,@master_jobId as DB1_jobid ,@master_ID as DB1_lot_id
			END
	END
END
