-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[sp_get_scheduler_bm] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT BM.LotNo as LotNo, Bm.MachineID as MCName ,bm.ProcessID as Process,MIN(bm.TimeRequest ) as TimeRequest
		,case when bm.CategoryID  = 1 THEN MIN( bm.TimeRequest)
			when bm.CategoryID  = 2 THEN MIN(bm.TimeStart)
			ELSE max( bm.TimeStart)
			END as TimeStart
		--,bm.TimeStart
		,MIN(bm.TimeFinish) as TimeFinish,bm.CategoryID 
	from DBx.dbo.BMMaintenance as BM
	where BM.TimeFinish is null and CategoryID in (1,2)
	group by Bm.MachineID ,BM.LotNo ,bm.CategoryID ,bm.ProcessID
END
