-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_qyi_dailyreport_below80]
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
	@startdate date 
	,@endddate date
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 select  Number,No1 = ROW_NUMBER() OVER (ORDER BY FYI_IN,Device) 
			,Device
			,Flow
			,Rank
			,PGK
			,LotNo
			,WaferLotNo
			,WaferNo
			,TestNo
			,Yield
			,FYI_IN
			,ShipmentDate
			,Incharge = FirstName
			,IssueNo1
			,ATP
			,Date
			,Designer
			,InvoiceNo
			,Shipment_delayed
			,FYI_delayed
			,Plan_Answer
			,ReviseShipmentDate
			,FYI_out 
			,NextProcess 
			,Remark = case when SameModeIssue <> '' then SameModeIssue else Remark end
			,Remark2
			,status = case when FYI_out is not null  then case when FYI_out >= FORMAT(dateadd(day, datediff(day, 0, @endddate), 0)  ,'yyyy-MM-dd') then 'blue' else 'red' end 
							when FYI_IN between FORMAT(dateadd(day, datediff(day, 0, @startdate)-1, 0)  ,'yyyy-MM-dd') and FORMAT( dateadd(day, datediff(day, 0, @endddate), 0)   ,'yyyy-MM-dd') then 'blue' 
							when FYI_out is null then 'black'
					end
			,Incharge1 = incharge
			,TimeIn
			,TimeOut
from(
	select Number = No ,Device
			,Flow
			,Rank
			,PGK
			,a.LotNo
			,WaferLotNo
			,WaferNo
			,TestNo = NGTestNo
			,CAST( FORMAT( TRY_CONVERT(numeric(38,12),FTYield),'N2') +'%' as nvarchar) as Yield
			,FYI_IN = FORMAT(TimeIn, 'yyyy-MM-dd')
			,ShipmentDate = FORMAT(ShipmentDate, 'yyyy-MM-dd')
			,Incharge 
			,IssueNo1 
			,ATP = FORMAT(RKDate, 'yyyy-MM-dd')
			,Date = FORMAT(SampleDate, 'yyyy-MM-dd')
			,Designer
			,InvoiceNo
			,Shipment_delayed = DATEDIFF(DAY,  ShipmentDate,GETDATE() )
			,FYI_delayed = DATEDIFF(day,TimeIn,GETDATE())
			,Plan_Answer = FORMAT(TimeIn +7, 'yyyy-MM-dd')
			,ReviseShipmentDate = FORMAT(ReviseShipmentDate, 'yyyy-MM-dd')
			,FYI_out = FORMAT(TimeOut, 'yyyy-MM-dd')
			,NextProcess 
			,Remark = case when Mode like '%New Mode%' then 'NEW MODE'
					  when Mode like '%Same Mode%' then 'SAME MODE'+'('+IssueNo+')'
					   end 
			,Remark1
			,Mode
			,Mode1
			,LotStatus
			,Remark2
			,TimeIn
			,TimeOut
			,SameModeIssue
	from(
			select a.No ,Device =  case WHEN  CHARINDEX('(', OldDeviceName) > 0 THEN LEFT (OldDeviceName,CHARINDEX('(', OldDeviceName) -1) else OldDeviceName END 
												,Flow = Process+','+ case when TestFlow = 'AUTO1' then 'A1'								
																when TestFlow = 'AUTO2' then 'A2'	
																when TestFlow = 'AUTO3' then 'A3'	
																when TestFlow = 'AUTO4' then 'A4'	
																when TestFlow = 'AUTO5' then 'A5'	
															else TestFlow		
															end 				
						,Rank
						,PGK = OldPackage
						,LotNo 
						,WaferLotNo 
						,WaferNo
						,NGTestNo
						,FTYield 
						,Remark
						,TestFlow
						,b.Mode
						,IssueNo1 = SUBSTRING(IssueNo,11,4)
						,TimeIn = ReceiveDate
						,TimeOut
						,IssueNo
						,NextProcess = GotoProcess
						,ShipmentDate
						,Designer = SampleDesigner
						,InvoiceNo	
						,Incharge
						,Mode1 = a.Mode
						,LotStatus
						,SampleDate
						,ReviseShipmentDate
						,Remark1
						,Remark2
						,RKDate
						,SameModeIssue
				from DBx.QYI.QYICase  a													
				inner join DBx.QYI.QYILowYield b													
				on a.No = b.No
				where StatusFlowFYI = 'FYI'
				and LotNo not like '%B%'
	) as a
	where TimeOut is null
	and TimeIn is not null
	or (TimeIn between dateadd(day, datediff(day, 0, @startdate)-1, 0)   and dateadd(day, datediff(day, 0, @endddate), 0)  )
	OR (TimeOut between dateadd(day, datediff(day, 0, @startdate)-1, 0)   and dateadd(day, datediff(day, 0, @endddate), 0)  )
	and TimeOut <= dateadd(day, datediff(day, 0, @endddate), 0)  
)as a
left join dbx.dbo.MyUser b
on a.Incharge = b.ID
where Mode1 = 'Yield < 80 %' 
--order by  Device ,IssueNo1 ASC

END
