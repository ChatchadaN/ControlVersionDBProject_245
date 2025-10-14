
CREATE PROCEDURE [dbo].[bm_pm3_report]
	-- Add the parameters for the stored procedure here
		@mcno as varchar(15) ='%'
		,@Date as  datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		select BMMaintenance.*,BMMaintenance.Approver as EmpApprove,BMEmployee.name,bmstatus.*,BMPM6Detail.* 
		from [DBx].[dbo].BMMaintenance inner join [DBx].[dbo].BMEmployee on BMMaintenance.Requestor = BMEmployee.id 
		inner join [DBx].[dbo].bmstatus on BMMaintenance.statusid = bmstatus.statusid 
		inner join [DBx].[dbo].BMPM6Detail on BMMaintenance.ID = BMPM6Detail.BM_ID 
		where pmid='1' and BMMaintenance.CaseForPM13 is null
		and BMMaintenance.MachineID = @mcno
		and TimeRequest between FORMAT(@Date,'yyyy/MM/dd 08:00')  and FORMAT(@Date+1,'yyyy/MM/dd 07:59:59')
		 order by TimeStart
END

