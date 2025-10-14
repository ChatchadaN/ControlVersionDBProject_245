-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [bms].[sp_get_fl_detail_num]
	-- Add the parameters for the stored procedure here
	@package int = 0
	-- 0 = all,1 = sop,2 = small
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF(@package = 0)
	BEGIN
		select sum(case when StatusID not in(3,5) then 1 else 0 end) RequestAll
		,sum(case when StatusID in(2,4,6) then 1 else 0 end) Repair
		,sum(case when StatusID in(1,7) then 1 else 0 end) Remain
		,sum(case when StatusID in(9) then 1 else 0 end) Monitor
		,sum(case when StatusID in(10) then 1 else 0 end) WaitRestart
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM6Detail on BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID
		where pmid='6' or pmid='7'
	END
	IF(@package = 1)
	BEGIN
		select sum(case when StatusID not in(3,5) then 1 else 0 end) RequestAll
		,sum(case when StatusID in(2,4,6) then 1 else 0 end) Repair
		,sum(case when StatusID in(1,7) then 1 else 0 end) Remain
		,sum(case when StatusID in(9) then 1 else 0 end) Monitor
		,sum(case when StatusID in(10) then 1 else 0 end) WaitRestart
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM6Detail on BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID
		where pmid='6'
	END
	IF(@package = 2)
	BEGIN
		select sum(case when StatusID not in(3,5) then 1 else 0 end) RequestAll
		,sum(case when StatusID in(2,4,6) then 1 else 0 end) Repair
		,sum(case when StatusID in(1,7) then 1 else 0 end) Remain
		,sum(case when StatusID in(9) then 1 else 0 end) Monitor
		,sum(case when StatusID in(10) then 1 else 0 end) WaitRestart
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM6Detail on BMMaintenance.id = dbx.dbo.BMPM6Detail.BM_ID
		where pmid='7'
	END
END
