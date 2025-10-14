-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_qyi_dailyreport_icburn]
	-- Add the parameters for the stored procedure here
	@startdate date
	,@endddate date
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	select	Number,No1 = ROW_NUMBER() OVER (ORDER BY Device,AbNo) 
			,Device
			,Flow
			,Rank
			,PGK
			,LotNo
			,WaferLotNo
			,WaferNo
			,TestNo = OST1
			,Yield
			,FQI_IN
			,ShipmentDate
			,Incharge = FirstName
			,AbNo
			,ATP
			,Date
			,Designer
			,InvoiceNo
			,Shipment_delayed
			,FQI_delayed
			,Plan_Answer
			,ReviseShipmentDate
			,FQI_out 
			,NextProcess 
			,Remark
			,Remark2
			,status = case when FQI_out is not null  then case when FQI_out >= FORMAT(dateadd(day, datediff(day, 0, @endddate), 0) ,'yyyy-MM-dd') then 'blue' else 'red' end 
							when FQI_IN between FORMAT(dateadd(day, datediff(day, 0, @startdate)-1, 0) ,'yyyy-MM-dd') and FORMAT( dateadd(day, datediff(day, 0, @endddate), 0) ,'yyyy-MM-dd') then 'blue' 
							when FQI_out is null then 'black'
					end
			,Incharge1 = incharge
			,TimeIn
			,TimeOut
from(
	select Number = No,Device
			,Flow
			,Rank
			,PGK
			,a.LotNo
			,WaferLotNo
			,WaferNo
			,OST1
			,CAST( FORMAT( TRY_CONVERT(numeric(38,12),FTYield),'N2') +'%' as nvarchar) as Yield
			,FQI_IN = FORMAT(TimeIn, 'yyyy-MM-dd')
			,ShipmentDate = FORMAT(ShipmentDate, 'yyyy-MM-dd')
			,Incharge 
			,AbNo 
			,ATP =   FORMAT(RKDate, 'yyyy-MM-dd')
			,Date = FORMAT(SampleDate, 'yyyy-MM-dd') --FORMAT(ShipmentDate, 'M/d')
			,Designer
			,InvoiceNo
			,Shipment_delayed = DATEDIFF(DAY,  ShipmentDate,GETDATE() )
			,FQI_delayed = DATEDIFF(day,TimeIn,GETDATE())
			,Plan_Answer = FORMAT(TimeIn +7, 'yyyy-MM-dd')
			,ReviseShipmentDate = FORMAT(ReviseShipmentDate, 'yyyy-MM-dd')
			,FQI_out = FORMAT(TimeOut, 'yyyy-MM-dd')
			,NextProcess 
			,Remark = FORMAT(AQIToQC, 'yyyy-MM-dd')
			,Remark2
			,LotStatus
			,TimeIn
			,TimeOut
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
						,OST1
						,FTYield 
						,Remark
						,TestFlow
						,RKDate
						,TimeIn --= ICBurnDate
						,TimeOut
						,AbNo
						,NextProcess = GotoProcess
						,ShipmentDate
						,Designer = SampleDesigner
						,InvoiceNo	
						,Incharge
						,Mode1 = a.Mode
						,LotStatus
						,SampleDate
						,ReviseShipmentDate
						,Remark2
						,AQIToQC
				from DBx.QYI.QYICase  a													
				inner join DBx.QYI.QYIICBurn b													
				on a.No = b.No	
				where  StatusFlowFYI = 'FYI' 
				and Mode = 'BIN29,BIN30,BIN31'
				
	) as a
	where TimeOut is null
	and TimeIn is not null
	or (TimeIn between dateadd(day, datediff(day, 0, @startdate)-1, 0) and dateadd(day, datediff(day, 0, @endddate), 0) )
	OR (TimeOut between dateadd(day, datediff(day, 0, @startdate)-1, 0)  and dateadd(day, datediff(day, 0, @endddate), 0) )
	and TimeOut <= dateadd(day, datediff(day, 0, @endddate), 0) 
)as a
left join dbx.dbo.MyUser b
on a.Incharge = b.ID
order by Device,AbNo  ASC
	
END
