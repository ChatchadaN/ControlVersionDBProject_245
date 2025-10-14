-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_map_detail]
	-- Add the parameters for the stored procedure here
	@process varchar =''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF(@process = 'FT')
	BEGIN
		select dbx.dbo.BMMaintenance.[ID]
		,case when (dbx.dbo.BMMaintenance.Urgent = 1 and  Mccontrol  = 1) then 'Special'									
			  when dbx.dbo.BMMaintenance.Urgent = 2 and  Mccontrol  = 1 then 'Special'
			  when Mccontrol= 1 then 'Special'
			  when dbx.dbo.BMMaintenance.Urgent = 1 or  Urgent = 2 then 'Special'	
			  else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) end AS RowID
	    ,case when (dbx.dbo.BMMaintenance.Urgent = 1 and  Mccontrol  = 1) then '#ffff00'									
			  when dbx.dbo.BMMaintenance.Urgent = 2 and  Mccontrol  = 1 then '#ffff00'
			  when Mccontrol= 1 then '#ffff00'
			  when dbx.dbo.BMMaintenance.Urgent = 1 or  Urgent = 2 then '#ffcccc'	
			  else convert( varchar(50), '') end AS Color,
			  dbx.dbo.BMMaintenance.PMID,
			  dbx.dbo.BMMaintenance.ProcessID,
			  dbx.dbo.BMMaintenance.Line,
			  dbx.dbo.BMMaintenance.MachineID,
			  dbx.dbo.BMMaintenance.LotNo,
		case  when DBx.dbo.BMMaintenance.Package is null or dbx.dbo.BMMaintenance.Package = '' then '-'
			  else dbx.dbo.BMMaintenance.Package end As Package,
		case  when DBx.dbo.BMMaintenance.Device is null or dbx.dbo.BMMaintenance.Device = '' then '-'
			  else dbx.dbo.BMMaintenance.Device end As Device,
			  dbx.dbo.BMMaintenance.Requestor,
			  dbx.dbo.BMMaintenance.TimeRequest,
			  dbx.dbo.BMMaintenance.TimeStart,
		case  when dbx.dbo.BMMaintenance.Inchanger is null or dbx.dbo.BMMaintenance.Inchanger = '' then '-'
			  else dbx.dbo.BMMaintenance.Inchanger end As Inchanger,
		--(case  when dbx.dbo.BMMaintenance.Problem = 'Periodical Check M/C' or dbx.dbo.BMMaintenance.Problem = 'Periodical Check M/C (Plan Stop)' then '-'
		--	   else 
		--			(case when alarmNo = '' or alarmNo ='Alarm No. -' and alarmName != ''  or alarmName != 'Alarm Name. -' then alarmName
		--				  when alarmName is null or alarmName = 'Alarm Name. -' and alarmNo != '' or alarmNo != 'Alarm No. -' then alarmNo 
		--				  else dbx.dbo.BMPM8Detail.alarmName + DBx.dbo.BMPM8Detail.alarmNo 
		--			 end)
		--end) As AlarmName,
		case when dbx.dbo.BMMaintenance.Problem is null then '-'
			 else dbx.dbo.BMMaintenance.Problem 
		end As Problem,
			  dbx.dbo.BMMaintenance.NGDescription,
			  dbx.dbo.BMMaintenance.StatusID,
			  dbx.dbo.BMMaintenance.CaseForPM13,
			  alarmName,alarmNo,
			  Mccontrol 
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM8Detail on BMMaintenance.id = BMPM8Detail.BM_ID 		
		left join dbx.dbo.BMMachine on BMMaintenance.MachineID = BMMachine.ID 
		and BMMachine.ProcessID = BMMaintenance.ProcessID 
		where (pmid in (8,9) )and BMMaintenance.statusid not In (3,5) 
		and ( BMMaintenance.ProcessID = 'FT') 
		and  (BMMaintenance.MachineID  In ('FT-EP-001','FT-EP-002','FT-EP-003','FT-EP-004','FT-EP-005','FT-EP-006','FT-EP-007','FT-EP-008','FT-EP-009','FT-EP-010','FT-T-001','FT-T-002','FT-T-003','FT-T-004','FT-T-005','FT-T-006','FT-T-007','FT-T-008','FT-T-009','FT-T-010','FT-T-011','FT-T-012','FT-T-013','FT-T-014','FT-T-015','FT-T-016','FT-T-017','FT-T-018','FT-T-019','FT-T-020','FT-T-021','FT-T-022','FT-T-023','FT-T-024','FT-T-025','FT-T-026','FT-T-027','FT-T-028','FT-T-029','FT-T-030','FT-T-031','FT-T-032','FT-T-033','FT-T-034','FT-Z-123','FT-Z-124','FT-IFZ-008','FT-IFZ-010','FT-MT-001','FT-T-035','FT-T-036'))
		order by ProcessID desc,Urgent desc, TimeRequest desc
	END
	IF(@process = 'TP')
	BEGIN
		select dbx.dbo.BMMaintenance.[ID]
		,case when (dbx.dbo.BMMaintenance.Urgent = 1 and  Mccontrol  = 1) then 'Special'									
			  when dbx.dbo.BMMaintenance.Urgent = 2 and  Mccontrol  = 1 then 'Special'
			  when Mccontrol= 1 then 'Special'
			  when dbx.dbo.BMMaintenance.Urgent = 1 or  Urgent = 2 then 'Special'	
			  else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) end AS RowID
	    ,case when (dbx.dbo.BMMaintenance.Urgent = 1 and  Mccontrol  = 1) then '#ffff00'									
			  when dbx.dbo.BMMaintenance.Urgent = 2 and  Mccontrol  = 1 then '#ffff00'
			  when Mccontrol= 1 then '#ffff00'
			  when dbx.dbo.BMMaintenance.Urgent = 1 or  Urgent = 2 then '#ffcccc'	
			  else convert( varchar(50), '') end AS Color,
			  dbx.dbo.BMMaintenance.PMID,
			  dbx.dbo.BMMaintenance.ProcessID,
			  dbx.dbo.BMMaintenance.Line,
			  dbx.dbo.BMMaintenance.MachineID,
			  dbx.dbo.BMMaintenance.LotNo,
		case  when DBx.dbo.BMMaintenance.Package is null or dbx.dbo.BMMaintenance.Package = '' then '-'
			  else dbx.dbo.BMMaintenance.Package end As Package,
		case  when DBx.dbo.BMMaintenance.Device is null or dbx.dbo.BMMaintenance.Device = '' then '-'
			  else dbx.dbo.BMMaintenance.Device end As Device,
			  dbx.dbo.BMMaintenance.Requestor,
			  dbx.dbo.BMMaintenance.TimeRequest,
			  dbx.dbo.BMMaintenance.TimeStart,
		case  when dbx.dbo.BMMaintenance.Inchanger is null or dbx.dbo.BMMaintenance.Inchanger = '' then '-'
			  else dbx.dbo.BMMaintenance.Inchanger end As Inchanger,
		--(case  when dbx.dbo.BMMaintenance.Problem = 'Periodical Check M/C' or dbx.dbo.BMMaintenance.Problem = 'Periodical Check M/C (Plan Stop)' then '-'
		--	   else 
		--			(case when alarmNo = '' or alarmNo ='Alarm No. -' and alarmName != ''  or alarmName != 'Alarm Name. -' then alarmName
		--				  when alarmName is null or alarmName = 'Alarm Name. -' and alarmNo != '' or alarmNo != 'Alarm No. -' then alarmNo 
		--				  else dbx.dbo.BMPM8Detail.alarmName + DBx.dbo.BMPM8Detail.alarmNo 
		--			 end)
		--end) As AlarmName,
		case when dbx.dbo.BMMaintenance.Problem is null then '-'
			 else dbx.dbo.BMMaintenance.Problem 
		end As Problem,
			  dbx.dbo.BMMaintenance.NGDescription,
			  dbx.dbo.BMMaintenance.StatusID,
			  dbx.dbo.BMMaintenance.CaseForPM13,
			  alarmName,alarmNo,
			  Mccontrol 
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM8Detail on BMMaintenance.id = BMPM8Detail.BM_ID 		
		left join dbx.dbo.BMMachine on BMMaintenance.MachineID = BMMachine.ID 
		and BMMachine.ProcessID = BMMaintenance.ProcessID 
		where (pmid in (8,9) )and BMMaintenance.statusid not In (3,5)  
		and ( BMMaintenance.ProcessID = 'TP') 
		and (BMMaintenance.MachineID In ('TP-TP-53','TP-TP-54','TP-TP-55','TP-TP-56','TP-TP-57','TP-TP-58','TP-LS-10','TP-LS-11','TP-OV-04','TP-OV-05','TP-TTM-01','TP-LS-12'))
		order by ProcessID desc,Urgent desc, TimeRequest desc
	END
	IF(@process = 'MAP')
	BEGIN
		select dbx.dbo.BMMaintenance.[ID]
		,case when (dbx.dbo.BMMaintenance.Urgent = 1 and  Mccontrol  = 1) then 'Special'									
			  when dbx.dbo.BMMaintenance.Urgent = 2 and  Mccontrol  = 1 then 'Special'
			  when Mccontrol= 1 then 'Special'
			  when dbx.dbo.BMMaintenance.Urgent = 1 or  Urgent = 2 then 'Special'	
			  else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) end AS RowID
	    ,case when (dbx.dbo.BMMaintenance.Urgent = 1 and  Mccontrol  = 1) then '#ffff00'									
			  when dbx.dbo.BMMaintenance.Urgent = 2 and  Mccontrol  = 1 then '#ffff00'
			  when Mccontrol= 1 then '#ffff00'
			  when dbx.dbo.BMMaintenance.Urgent = 1 or  Urgent = 2 then '#ffcccc'	
			  else convert( varchar(50), '') end AS Color,
			  dbx.dbo.BMMaintenance.PMID,
			  dbx.dbo.BMMaintenance.ProcessID,
			  dbx.dbo.BMMaintenance.Line,
			  dbx.dbo.BMMaintenance.MachineID,
			  dbx.dbo.BMMaintenance.LotNo,
		case  when DBx.dbo.BMMaintenance.Package is null or dbx.dbo.BMMaintenance.Package = '' then '-'
			  else dbx.dbo.BMMaintenance.Package end As Package,
		case  when DBx.dbo.BMMaintenance.Device is null or dbx.dbo.BMMaintenance.Device = '' then '-'
			  else dbx.dbo.BMMaintenance.Device end As Device,
			  dbx.dbo.BMMaintenance.Requestor,
			  dbx.dbo.BMMaintenance.TimeRequest,
			  dbx.dbo.BMMaintenance.TimeStart,
		case  when dbx.dbo.BMMaintenance.Inchanger is null or dbx.dbo.BMMaintenance.Inchanger = '' then '-'
			  else dbx.dbo.BMMaintenance.Inchanger end As Inchanger,
		--(case  when dbx.dbo.BMMaintenance.Problem = 'Periodical Check M/C' or dbx.dbo.BMMaintenance.Problem = 'Periodical Check M/C (Plan Stop)' then '-'
		--	   else 
		--			(case when alarmNo = '' or alarmNo ='Alarm No. -' and alarmName != ''  or alarmName != 'Alarm Name. -' then alarmName
		--				  when alarmName is null or alarmName = 'Alarm Name. -' and alarmNo != '' or alarmNo != 'Alarm No. -' then alarmNo 
		--				  else dbx.dbo.BMPM8Detail.alarmName + DBx.dbo.BMPM8Detail.alarmNo 
		--			 end)
		--end) As AlarmName,
		case when dbx.dbo.BMMaintenance.Problem is null then '-'
			 else dbx.dbo.BMMaintenance.Problem 
		end As Problem,
			  dbx.dbo.BMMaintenance.NGDescription,
			  dbx.dbo.BMMaintenance.StatusID,
			  dbx.dbo.BMMaintenance.CaseForPM13,
			  alarmName,alarmNo,
			  Mccontrol 
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM8Detail on BMMaintenance.id = BMPM8Detail.BM_ID 		
		left join dbx.dbo.BMMachine on BMMaintenance.MachineID = BMMachine.ID 
		and BMMachine.ProcessID = BMMaintenance.ProcessID 
		where (pmid in (8,9) )and BMMaintenance.statusid not In (3,5) 
		and ( BMMaintenance.ProcessID = 'MAP') 
		and (BMMaintenance.MachineID In ('MAP-BT-01','MAP-IPB-16','MAP-IPB-17','MAP-IPB-18','MAP-IPB-19','MAP-IPB-20','MAP-IPB-21','MAP-IPB-22','MAP-IPB-23','MAP-IPB-24','MAP-IPB-25','MAP-IPB-26','MAP-IPB-27','MAP-IPB-28','MAP-IPB-29','MAP-LA-01','MAP-LM-03','MAP-LM-04','MAP-BT-01','MAP-IPB-16','MAP-IPB-17','MAP-IPB-18','MAP-IPB-19','MAP-IPB-20','MAP-IPB-20','MAP-IPB-21','MAP-IPB-22','MAP-IPB-23','MAP-IPB-24','MAP-IPB-25','MAP-IPB-26','MAP-IPB-27','MAP-LA-01','MAP-LM-03','MAP-LM-04','MAP-MT-02','MAP-PS-02','MAP-PS-03','MAP-PS-04','MAP-PS-05','MAP-PS-06','MAP-PS-07','MAP-PS-08','MAP-PS-09','MAP-PS-10','MAP-RT-05','MAP-RT-06','MAP-RT-07','MAP-RT-08','MAP-RT-09','MAP-RT-10','MAP-RT-11','MAP-RT-12','MAP-RT-13','MAP-RT-14','MAP-RT-15','MAP-TT-02','MAP-MT-02','MAP-PS-02','MAP-PS-03','MAP-PS-04','MAP-PS-05','MAP-PS-06','MAP-PS-07','MAP-PS-08','MAP-PS-09','MAP-PS-10','MAP-RT-05','MAP-RT-06','MAP-RT-07','MAP-RT-08','MAP-RT-09','MAP-RT-10','MAP-RT-11','MAP-RT-12','MAP-RT-13','MAP-RT-14','MAP-RT-15','MAP-TT-02'))  
		order by ProcessID desc,Urgent desc, TimeRequest desc
	END
	IF(@process = '')
	BEGIN
		select dbx.dbo.BMMaintenance.[ID]
		,case when (dbx.dbo.BMMaintenance.Urgent = 1 and  Mccontrol  = 1) then 'Special'									
			  when dbx.dbo.BMMaintenance.Urgent = 2 and  Mccontrol  = 1 then 'Special'
			  when Mccontrol= 1 then 'Special'
			  when dbx.dbo.BMMaintenance.Urgent = 1 or  Urgent = 2 then 'Special'	
			  else convert( varchar(50), ROW_NUMBER() OVER(ORDER BY Urgent desc)) end AS RowID
	    ,case when (dbx.dbo.BMMaintenance.Urgent = 1 and  Mccontrol  = 1) then '#ffff00'									
			  when dbx.dbo.BMMaintenance.Urgent = 2 and  Mccontrol  = 1 then '#ffff00'
			  when Mccontrol= 1 then '#ffff00'
			  when dbx.dbo.BMMaintenance.Urgent = 1 or  Urgent = 2 then '#ffcccc'	
			  else convert( varchar(50), '') end AS Color,
			  dbx.dbo.BMMaintenance.PMID,
			  dbx.dbo.BMMaintenance.ProcessID,
			  dbx.dbo.BMMaintenance.Line,
			  dbx.dbo.BMMaintenance.MachineID,
			  dbx.dbo.BMMaintenance.LotNo,
		case  when DBx.dbo.BMMaintenance.Package is null or dbx.dbo.BMMaintenance.Package = '' then '-'
			  else dbx.dbo.BMMaintenance.Package end As Package,
		case  when DBx.dbo.BMMaintenance.Device is null or dbx.dbo.BMMaintenance.Device = '' then '-'
			  else dbx.dbo.BMMaintenance.Device end As Device,
			  dbx.dbo.BMMaintenance.Requestor,
			  dbx.dbo.BMMaintenance.TimeRequest,
			  dbx.dbo.BMMaintenance.TimeStart,
		case  when dbx.dbo.BMMaintenance.Inchanger is null or dbx.dbo.BMMaintenance.Inchanger = '' then '-'
			  else dbx.dbo.BMMaintenance.Inchanger end As Inchanger,
		--(case  when dbx.dbo.BMMaintenance.Problem = 'Periodical Check M/C' or dbx.dbo.BMMaintenance.Problem = 'Periodical Check M/C (Plan Stop)' then '-'
		--	   else 
		--			(case when alarmNo = '' or alarmNo ='Alarm No. -' and alarmName != ''  or alarmName != 'Alarm Name. -' then alarmName
		--				  when alarmName is null or alarmName = 'Alarm Name. -' and alarmNo != '' or alarmNo != 'Alarm No. -' then alarmNo 
		--				  else dbx.dbo.BMPM8Detail.alarmName + DBx.dbo.BMPM8Detail.alarmNo 
		--			 end)
		--end) As AlarmName,
		case when dbx.dbo.BMMaintenance.Problem is null then '-'
			 else dbx.dbo.BMMaintenance.Problem 
		end As Problem,
			  dbx.dbo.BMMaintenance.NGDescription,
			  dbx.dbo.BMMaintenance.StatusID,
			  dbx.dbo.BMMaintenance.CaseForPM13,
			   alarmName,alarmNo,
			  Mccontrol
		from dbx.dbo.BMMaintenance right join dbx.dbo.BMPM8Detail on BMMaintenance.id = BMPM8Detail.BM_ID 		
		left join dbx.dbo.BMMachine on BMMaintenance.MachineID = BMMachine.ID 
		and BMMachine.ProcessID = BMMaintenance.ProcessID 
		where (pmid in (8,9) )and BMMaintenance.statusid not In (3,5) 
		and ( BMMaintenance.ProcessID = 'MAP' or BMMaintenance.ProcessID ='FT' or BMMaintenance.ProcessID ='TP') 
		and (BMMaintenance.MachineID  In ('FT-EP-001','FT-EP-002','FT-EP-003','FT-EP-004','FT-EP-005','FT-EP-006','FT-EP-007','FT-EP-008','FT-EP-009','FT-EP-010','FT-T-001','FT-T-002','FT-T-003','FT-T-004','FT-T-005','FT-T-006','FT-T-007','FT-T-008','FT-T-009','FT-T-010','FT-T-011','FT-T-012','FT-T-013','FT-T-014','FT-T-015','FT-T-016','FT-T-017','FT-T-018','FT-T-019','FT-T-020','FT-T-021','FT-T-022','FT-T-023','FT-T-024','FT-T-025','FT-T-026','FT-T-027','FT-T-028','FT-T-029','FT-T-030','FT-T-031','FT-T-032','FT-T-033','FT-T-034','FT-Z-123','FT-Z-124','FT-IFZ-008','FT-IFZ-010','FT-MT-001','TP-TP-53','TP-TP-54','TP-TP-55','TP-TP-56','TP-TP-57','TP-TP-58','TP-LS-10','TP-LS-11','TP-OV-04','TP-OV-05','TP-TTM-01','TP-LS-12','MAP-BT-01','MAP-IPB-16','MAP-IPB-17','MAP-IPB-18','MAP-IPB-19','MAP-IPB-20','MAP-IPB-21','MAP-IPB-22','MAP-IPB-23','MAP-IPB-24','MAP-IPB-25','MAP-IPB-26','MAP-IPB-27','MAP-IPB-28','MAP-IPB-29','MAP-LA-01','MAP-LM-03','MAP-LM-04','MAP-BT-01','MAP-IPB-16','MAP-IPB-17','MAP-IPB-18','MAP-MAP-IPB-19','MAP-IPB-20','MAP-IPB-20','MAP-IPB-21','MAP-IPB-22','MAP-IPB-23','MAP-IPB-24','MAP-IPB-25','MAP-IPB-26','MAP-IPB-27','MAP-IPB-28','MAP-IPB-29','MAP-LA-01','MAP-LM-03','MAP-LM-04','MAP-MT-02','MAP-PS-02','MAP-PS-03','MAP-PS-04','MAP-PS-05','MAP-PS-06','MAP-PS-07','MAP-PS-08','MAP-PS-09','MAP-PS-10','MAP-RT-05','MAP-RT-06','MAP-RT-07','MAP-RT-08','MAP-RT-09','MAP-RT-10','MAP-RT-11','MAP-RT-12','MAP-RT-13','MAP-RT-14','MAP-RT-15','MAP-TT-02','MAP-MT-02','MAP-PS-02','MAP-PS-03','MAP-PS-04','MAP-PS-05','MAP-PS-06','MAP-PS-07','MAP-PS-08','MAP-PS-09','MAP-PS-10','MAP-RT-05','MAP-RT-06','MAP-RT-07','MAP-RT-08','MAP-RT-09','MAP-RT-10','MAP-RT-11','MAP-RT-12','MAP-RT-13','MAP-RT-14','MAP-RT-15','MAP-TT-02','FT-T-035','FT-T-036'))
		order by ProcessID desc,Urgent desc, TimeRequest desc
	END

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [bms].[sp_get_map_detail] @process = '''+@process +''''


END
