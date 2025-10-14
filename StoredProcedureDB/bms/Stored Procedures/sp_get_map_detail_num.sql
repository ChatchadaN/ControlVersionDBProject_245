-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_map_detail_num]
	-- Add the parameters for the stored procedure here
	@process varchar = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   IF(@process = 'FT')
   BEGIN
		select sum(case when StatusID not in(3,5) then 1 else 0 end ) RequestAll,
		sum(case when StatusID in(2,4,6) then 1 else 0 end) Repair,
		sum(case when StatusID in(1,7) then 1 else 0 end) Remain,
		sum(case when StatusID in(9) then 1 else 0 end) Monitor,
		sum(case when StatusID in(10) then 1 else 0 end) WaitRestart 
		from dbx.dbo.BMMaintenance 
		right join dbx.dbo.BMPM8Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM8Detail.BM_ID 
		where PMID in (8,9) and ( BMMaintenance.ProcessID = 'FT') 
		and(BMMaintenance.MachineID  In ('FT-EP-001','FT-EP-002','FT-EP-003','FT-EP-004','FT-EP-005','FT-EP-006','FT-EP-007','FT-EP-008','FT-EP-009','FT-EP-010','FT-T-001','FT-T-002','FT-T-003','FT-T-004','FT-T-005','FT-T-006','FT-T-007','FT-T-008','FT-T-009','FT-T-010','FT-T-011','FT-T-012','FT-T-013','FT-T-014','FT-T-015','FT-T-016','FT-T-017','FT-T-018','FT-T-019','FT-T-020','FT-T-021','FT-T-022','FT-T-023','FT-T-024','FT-T-025','FT-T-026','FT-T-027','FT-T-028','FT-T-029','FT-T-030','FT-T-031','FT-T-032','FT-T-033','FT-T-034','FT-Z-123','FT-Z-124','FT-IFZ-008','FT-IFZ-010','FT-MT-001','FT-T-035','FT-T-036'))
   END
   IF(@process = 'TP')
   BEGIN
		select sum(case when StatusID not in(3,5) then 1 else 0 end ) RequestAll,
		sum(case when StatusID in(2,4,6) then 1 else 0 end) Repair,
		sum(case when StatusID in(1,7) then 1 else 0 end) Remain,
		sum(case when StatusID in(9) then 1 else 0 end) Monitor,
		sum(case when StatusID in(10) then 1 else 0 end) WaitRestart 
		from dbx.dbo.BMMaintenance 
		right join dbx.dbo.BMPM8Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM8Detail.BM_ID 
		where PMID in (8,9) and ( BMMaintenance.ProcessID = 'TP') 
		and(BMMaintenance.MachineID In ('TP-TP-53','TP-TP-54','TP-TP-55','TP-TP-56','TP-TP-57','TP-TP-58','TP-LS-10','TP-LS-11','TP-OV-04','TP-OV-05','TP-TTM-01','TP-LS-12'))
   END
   IF(@process = 'MAP')
   BEGIN
		select sum(case when StatusID not in(3,5) then 1 else 0 end ) RequestAll,
		sum(case when StatusID in(2,4,6) then 1 else 0 end) Repair,
		sum(case when StatusID in(1,7) then 1 else 0 end) Remain,
		sum(case when StatusID in(9) then 1 else 0 end) Monitor,
		sum(case when StatusID in(10) then 1 else 0 end) WaitRestart 
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM8Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM8Detail.BM_ID 
		where PMID in (8,9) and ( BMMaintenance.ProcessID = 'MAP') 
		and (BMMaintenance.MachineID In ('MAP-BT-01','MAP-IPB-16','MAP-IPB-17','MAP-IPB-18','MAP-IPB-19','MAP-IPB-20','MAP-IPB-21','MAP-IPB-22','MAP-IPB-23','MAP-IPB-24','MAP-IPB-25','MAP-IPB-26','MAP-IPB-27','MAP-IPB-28','MAP-IPB-29','MAP-LA-01','MAP-LM-03','MAP-LM-04','MAP-BT-01','MAP-IPB-16','MAP-IPB-17','MAP-IPB-18','MAP-IPB-19','MAP-IPB-20','MAP-IPB-20','MAP-IPB-21','MAP-IPB-22','MAP-IPB-23','MAP-IPB-24','MAP-IPB-25','MAP-IPB-26','MAP-IPB-27','MAP-LA-01','MAP-LM-03','MAP-LM-04','MAP-MT-02','MAP-PS-02','MAP-PS-03','MAP-PS-04','MAP-PS-05','MAP-PS-06','MAP-PS-07','MAP-PS-08','MAP-PS-09','MAP-PS-10','MAP-RT-05','MAP-RT-06','MAP-RT-07','MAP-RT-08','MAP-RT-09','MAP-RT-10','MAP-RT-11','MAP-RT-12','MAP-RT-13','MAP-RT-14','MAP-RT-15','MAP-TT-02','MAP-MT-02','MAP-PS-02','MAP-PS-03','MAP-PS-04','MAP-PS-05','MAP-PS-06','MAP-PS-07','MAP-PS-08','MAP-PS-09','MAP-PS-10','MAP-RT-05','MAP-RT-06','MAP-RT-07','MAP-RT-08','MAP-RT-09','MAP-RT-10','MAP-RT-11','MAP-RT-12','MAP-RT-13','MAP-RT-14','MAP-RT-15','MAP-TT-02'))
   END
   IF(@process = '')
   BEGIN
		select sum(case when StatusID not in(3,5) then 1 else 0 end ) RequestAll,
		sum(case when StatusID in(2,4,6) then 1 else 0 end) Repair,
		sum(case when StatusID in(1,7) then 1 else 0 end) Remain,
		sum(case when StatusID in(9) then 1 else 0 end) Monitor,
		sum(case when StatusID in(10) then 1 else 0 end) WaitRestart 
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM8Detail on dbx.dbo.BMMaintenance.id = dbx.dbo.BMPM8Detail.BM_ID 
		where PMID in (8,9) and ( BMMaintenance.ProcessID = 'MAP' or BMMaintenance.ProcessID ='FT' or BMMaintenance.ProcessID ='TP') 
		and (BMMaintenance.MachineID  In ('FT-EP-001','FT-EP-002','FT-EP-003','FT-EP-004','FT-EP-005','FT-EP-006','FT-EP-007','FT-EP-008','FT-EP-009','FT-EP-010','FT-T-001','FT-T-002','FT-T-003','FT-T-004','FT-T-005','FT-T-006','FT-T-007','FT-T-008','FT-T-009','FT-T-010','FT-T-011','FT-T-012','FT-T-013','FT-T-014','FT-T-015','FT-T-016','FT-T-017','FT-T-018','FT-T-019','FT-T-020','FT-T-021','FT-T-022','FT-T-023','FT-T-024','FT-T-025','FT-T-026','FT-T-027','FT-T-028','FT-T-029','FT-T-030','FT-T-031','FT-T-032','FT-T-033','FT-T-034','FT-Z-123','FT-Z-124','FT-IFZ-008','FT-IFZ-010','FT-MT-001','TP-TP-53','TP-TP-54','TP-TP-55','TP-TP-56','TP-TP-57','TP-TP-58','TP-LS-10','TP-LS-11','TP-OV-04','TP-OV-05','TP-TTM-01','TP-LS-12','MAP-BT-01','MAP-IPB-16','MAP-IPB-17','MAP-IPB-18','MAP-IPB-19','MAP-IPB-20','MAP-IPB-21','MAP-IPB-22','MAP-IPB-23','MAP-IPB-24','MAP-IPB-25','MAP-IPB-26','MAP-IPB-27','MAP-IPB-28','MAP-IPB-29','MAP-LA-01','MAP-LM-03','MAP-LM-04','MAP-BT-01','MAP-IPB-16','MAP-IPB-17','MAP-IPB-18','MAP-MAP-IPB-19','MAP-IPB-20','MAP-IPB-20','MAP-IPB-21','MAP-IPB-22','MAP-IPB-23','MAP-IPB-24','MAP-IPB-25','MAP-IPB-26','MAP-IPB-27','MAP-IPB-28','MAP-IPB-29','MAP-LA-01','MAP-LM-03','MAP-LM-04','MAP-MT-02','MAP-PS-02','MAP-PS-03','MAP-PS-04','MAP-PS-05','MAP-PS-06','MAP-PS-07','MAP-PS-08','MAP-PS-09','MAP-PS-10','MAP-RT-05','MAP-RT-06','MAP-RT-07','MAP-RT-08','MAP-RT-09','MAP-RT-10','MAP-RT-11','MAP-RT-12','MAP-RT-13','MAP-RT-14','MAP-RT-15','MAP-TT-02','MAP-MT-02','MAP-PS-02','MAP-PS-03','MAP-PS-04','MAP-PS-05','MAP-PS-06','MAP-PS-07','MAP-PS-08','MAP-PS-09','MAP-PS-10','MAP-RT-05','MAP-RT-06','MAP-RT-07','MAP-RT-08','MAP-RT-09','MAP-RT-10','MAP-RT-11','MAP-RT-12','MAP-RT-13','MAP-RT-14','MAP-RT-15','MAP-TT-02','FT-T-035','FT-T-036')) 
   END
	
   
END
