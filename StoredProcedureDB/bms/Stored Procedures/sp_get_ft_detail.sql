-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [bms].[sp_get_ft_detail]
	-- Add the parameters for the stored procedure here
	@data varchar(50) = 'gettable'
	,@bmid int = 1
	--, @package varchar(50) = '%'
	--, @lotType varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@data ='getbymachine')
	BEGIN
	 select BMMachine.ID as NameMC,
	 BMMachine.ProcessID,
	 BMMachine.MCTypeID ,
	 BMMachine.Location,
	 BMMachine.McControl,
	 BMMaintenance.*,
	 BMPM8Detail.alarmNo,
	 BMPM8Detail.AlarmName,
	 Mccontrol  
     from DBx.dbo.BMMaintenance right join DBx.dbo.BMPM8Detail on DBx.dbo.BMMaintenance.id = DBx.dbo.BMPM8Detail.BM_ID INNER JOIN DBx.dbo.BMMachine ON DBx.dbo.BMMaintenance.MachineID = DBx.dbo.BMMachine.ID 
     where pmid = 8 and BMMaintenance.statusid not In (3,5) and ( BMMachine.MCTypeID not In ('K&S','IWBS')) and ( BMMachine.ProcessID = 'FT')  
	 and ( BMMaintenance.ProcessID = 'FT') and  (BMMaintenance.MachineID not In ('FT-EP-001','FT-EP-002','FT-EP-003','FT-EP-004','FT-EP-005','FT-EP-006','FT-EP-007','FT-EP-008','FT-EP-009','FT-EP-010','FT-T-001','FT-T-002','FT-T-003','FT-T-004','FT-T-005','FT-T-006','FT-T-007','FT-T-008','FT-T-009','FT-T-010','FT-T-011','FT-T-012','FT-T-013','FT-T-014','FT-T-015','FT-T-016','FT-T-017','FT-T-018','FT-T-019','FT-T-020','FT-T-021','FT-T-022','FT-T-023','FT-T-024','FT-T-025','FT-T-026','FT-T-027','FT-T-028','FT-T-029','FT-T-030','FT-T-031','FT-T-032','FT-T-033','FT-T-034','FT-Z-123','FT-Z-124','FT-IFZ-008','FT-IFZ-010','FT-MT-001','FT-T-035','FT-T-036')) 
	 and BMMaintenance.ID =@bmid
	 order by Urgent desc,TimeRequest desc
   END
   ELSE
   BEGIN
   select BMMachine.ID as NameMC,
   case when (dbx.dbo.BMMaintenance.[Urgent] = 2 and Mccontrol =1) then 'Super Keihin'
			when dbx.dbo.BMMaintenance.[Urgent] = 2 then 'Super' 
			when dbx.dbo.BMMaintenance.[Urgent] = 1 and Mccontrol = 1 then 'Special Keihin'
			when dbx.dbo.BMMaintenance.[Urgent] = 1 then 'Special'
			when Mccontrol =1 then 'Keihin' 
			else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) end AS RowID,
	case when (dbx.dbo.BMMaintenance.[Urgent] = 2 and Mccontrol =1) then '#ffff00'
			when dbx.dbo.BMMaintenance.[Urgent] = 2 then '#ffcccc' 
			when dbx.dbo.BMMaintenance.[Urgent] = 1 and Mccontrol = 1 then '#ffff00'
			when dbx.dbo.BMMaintenance.[Urgent] = 1 then '#ffcccc'
			when Mccontrol =1 then '#ffff00' 
			else convert( varchar(50), '') end AS Color,
   BMMachine.ProcessID,
   BMMachine.MCTypeID ,
   BMMachine.Location,
   BMMachine.McControl,
   BMMaintenance.*,
   BMMaintenance.Problem ,
   BMPM8Detail.alarmNo,
   BMPM8Detail.AlarmName,
   Mccontrol  
    from DBx.dbo.BMMaintenance right join DBx.dbo.BMPM8Detail on DBx.dbo.BMMaintenance.id = DBx.dbo.BMPM8Detail.BM_ID INNER JOIN DBx.dbo.BMMachine ON DBx.dbo.BMMaintenance.MachineID = DBx.dbo.BMMachine.ID 
    where pmid = 8 and BMMaintenance.statusid not In (3,5) and ( BMMachine.MCTypeID not In ('K&S','IWBS')) and ( BMMachine.ProcessID = 'FT')  
	and ( BMMaintenance.ProcessID = 'FT') and  (BMMaintenance.MachineID not In ('FT-EP-001','FT-EP-002','FT-EP-003','FT-EP-004','FT-EP-005','FT-EP-006','FT-EP-007','FT-EP-008','FT-EP-009','FT-EP-010','FT-T-001','FT-T-002','FT-T-003','FT-T-004','FT-T-005','FT-T-006','FT-T-007','FT-T-008','FT-T-009','FT-T-010','FT-T-011','FT-T-012','FT-T-013','FT-T-014','FT-T-015','FT-T-016','FT-T-017','FT-T-018','FT-T-019','FT-T-020','FT-T-021','FT-T-022','FT-T-023','FT-T-024','FT-T-025','FT-T-026','FT-T-027','FT-T-028','FT-T-029','FT-T-030','FT-T-031','FT-T-032','FT-T-033','FT-T-034','FT-Z-123','FT-Z-124','FT-IFZ-008','FT-IFZ-010','FT-MT-001','FT-T-035','FT-T-036')) 
	order by Urgent desc,TimeRequest desc
   END

END
