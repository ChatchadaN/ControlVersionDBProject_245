-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [bms].[sp_get_ft_detail_num]
	-- Add the parameters for the stored procedure here
	--@unit varchar(50) = 'Lots'
	--,@lbGroup varchar(50) = '%'
	--, @package varchar(50) = '%'
	--, @lotType varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 select sum(case when StatusID not in(3,5) then 1 else 0 end) RequestAll,
                       sum(case when StatusID in(2,4,6) then 1 else 0 end) Repair,
                       sum(case when StatusID in(1,7) then 1 else 0 end) Remain,
                       sum(case when StatusID in(9) then 1 else 0 end) Monitor,
                       sum(case when StatusID in(10) then 1 else 0 end) WaitRestart 
                       from DBx.dbo.BMMaintenance right join DBx.dbo.BMPM8Detail on DBx.dbo.BMMaintenance.id = DBx.dbo.BMPM8Detail.BM_ID 
                       where PMID = 8 and ( BMMaintenance.ProcessID = 'FT')
					   and  (BMMaintenance.MachineID not In ('FT-EP-001','FT-EP-002','FT-EP-003','FT-EP-004','FT-EP-005','FT-EP-006','FT-EP-007','FT-EP-008','FT-EP-009','FT-EP-010','FT-T-001','FT-T-002','FT-T-003','FT-T-004','FT-T-005','FT-T-006','FT-T-007','FT-T-008','FT-T-009','FT-T-010','FT-T-011','FT-T-012','FT-T-013','FT-T-014','FT-T-015','FT-T-016','FT-T-017','FT-T-018','FT-T-019','FT-T-020','FT-T-021','FT-T-022','FT-T-023','FT-T-024','FT-T-025','FT-T-026','FT-T-027','FT-T-028','FT-T-029','FT-T-030','FT-T-031','FT-T-032','FT-T-033','FT-T-034','FT-Z-123','FT-Z-124','FT-IFZ-008','FT-IFZ-010','FT-MT-001','FT-T-035','FT-T-036'))
END
