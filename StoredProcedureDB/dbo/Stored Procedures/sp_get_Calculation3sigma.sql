-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[sp_get_Calculation3sigma]
	-- Add the parameters for the stored procedure here
	@Package varchar (20) = '%' , 
	@Device varchar (50) = '%' , 
	@Date date = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select 
		TRIM(a.TYPE_NAME) as Package
		,TRIM(a.ROHM_MODEL_NAME) as Device
		,TRIM(a.FT_FLOW_NAME) as TestFlow
		,a.LCL_CONTROL as LCL_CONTROL
		,case when New_LCL < 0 then a.LCL_CONTROL
				when New_LCL > a.LCL_CONTROL then round(a.LCL_CONTROL,1)
				when New_LCL is null then round(a.LCL_CONTROL,1)
				else round(b.New_LCL,1) end as New_LCL
		--,Process_Name
FROM [DBx].[dbo].[IS_LCLMASTER] a
  left join (
		select * 
			from (select 
		Package
		,Device
		,TestFlow
		,LCL_CONTROL
		,case when avg(YLD) - stdev(YLD)*3 is null then b.LCL_CONTROL else format( avg(YLD) - (stdev(YLD)*3),'n2') end as New_LCL

from (select a.LotNo
		,Package
		,case WHEN  CHARINDEX('(', b.Device) > 0 THEN LEFT (b.Device,CHARINDEX('(', b.Device) -1)END + case when TapingDirection is null then '' else TapingDirection end as  Device
		,case when TestFlow is null then 'AUTO1' when TestFlow = '' then 'AUTO1' else TestFlow end as TestFlow
		,a.GoodAdjust as Total_Good
		, a.FTNGAdjust as  Total_NG
		,case when (GoodAdjust+FTNGAdjust)= 0 then null else CONVERT(float,GoodAdjust/CAST((GoodAdjust+FTNGAdjust) as float))*100  end as YLD
		--,Process_Name = 'FL'
		
from DBx.dbo.FLData a
inner join DBx.dbo.TransactionData b 
on a.LotNo = b.LotNo
where  case when (GoodAdjust+FTNGAdjust)= 0 then null else CONVERT(float,GoodAdjust/CAST((GoodAdjust+FTNGAdjust) as float))*100  end >= 95
and a.LotNo in (select LotNo from DBx.dbo.FLData where LotNo not like '%B%' and GoodAdjust != 0 and a.GoodAdjust is not null and a.FTNGAdjust is not null and LotEndTime between  case when  @Date = '' then  DATEADD(m, - 3, DATEADD(month, DATEDIFF(MONTH, 0, getdate()), 0)) else DATEADD(m, - 3, DATEADD(month, DATEDIFF(MONTH, 0, @Date), 0))end and	case when @Date = '' then DATEADD(MONTH, DATEDIFF(MONTH, 0, getdate()), -1) else DATEADD(MONTH, DATEDIFF(MONTH, 0, @Date), -1) end)
and case WHEN  CHARINDEX('-', b.Device) > 0 THEN LEFT (b.Device,CHARINDEX('-', b.Device) -1)  END in    
					
						(select DeviceName from dbx.dbo.OIS where   ProcessName like '%FL%' and DeviceName not in (select DeviceName 
																						FROM [DBx].[dbo].[OIS] 
																						where ProcessName like '%FT%' or DeviceName is not null and ProcessName like '%MAP%')) 
and GoodAdjust != 0
) as a
inner join dbx.dbo.IS_LCLMASTER b
on a.Device = b.ROHM_MODEL_NAME and a.TestFlow = b.FT_FLOW_NAME
--where YLD >= 95
group by Package,Device,TestFlow,LCL_CONTROL) as a

		union select * 
			from (select 
		 Package
		,Device
		,TestFlow
		,LCL_CONTROL	
		,case when avg(YLD) - stdev(YLD)*3 is null then b.LCL_CONTROL
				when avg(YLD) - stdev(YLD)*3 < 0 then b.LCL_CONTROL
				else format(avg(YLD) - stdev(YLD)*3,'n2') end as New_LCL 

from (select LotNo
		,CHK_ROHM_Model_Name as Device
		,Type_Name as Package
		,TestFlow = case when Process_Code = 891 then 'AUTO0' when Process_Code = 892 then 'AUTO1' when Process_Code = 893 then 'AUTO2' when Process_Code = 894 then 'AUTO3' when Process_Code = 895 then 'AUTO4'  when Process_Code = 896 then 'AUTO5'end 
		,GOOD_QTY as Total_Good
		,FT_NG_QTY as Total_NG
		,case when (GOOD_QTY+FT_NG_QTY)= 0 then null else CONVERT(float,GOOD_QTY/CAST((GOOD_QTY+FT_NG_QTY) as float))*100  end as YLD
		--,Process_Name = 'FT'
from DBx.dbo.IS_FT_W_REC
where  case when (GOOD_QTY+FT_NG_QTY)= 0 then null else CONVERT(float,GOOD_QTY/CAST((GOOD_QTY+FT_NG_QTY) as float))*100  end >= 95
and LotNo  in (select LotNo from DBx.dbo.TransactionData where LotNo not like '%B%' and  Date1 between  case when  @Date = '' then  DATEADD(m, - 3, DATEADD(month, DATEDIFF(MONTH, 0, getdate()), 0)) else DATEADD(m, - 3, DATEADD(month, DATEDIFF(MONTH, 0, @Date), 0))end and	case when @Date = '' then DATEADD(MONTH, DATEDIFF(MONTH, 0, getdate()), -1) else DATEADD(MONTH, DATEDIFF(MONTH, 0, @Date), -1) end)
and case WHEN  CHARINDEX('-', CHK_ROHM_Model_Name) > 0 THEN LEFT (CHK_ROHM_Model_Name,CHARINDEX('-', CHK_ROHM_Model_Name) -1)  END  in  (select DeviceName from dbx.dbo.OIS where   ProcessName like '%FT%' and DeviceName not in (select DeviceName FROM [DBx].[dbo].[OIS] where ProcessName like '%FL%' or DeviceName is not null and ProcessName like '%MAP%')  )
 and GOOD_QTY != 0
  )as a
 inner join dbx.dbo.IS_LCLMASTER b
on a.Device = b.ROHM_MODEL_NAME and a.TestFlow = b.FT_FLOW_NAME
group by Package,Device,TestFlow,LCL_CONTROL
) as b

		union select * 
			from (select Package
		,Device
		,TestFlow
		,LCL_CONTROL
		,case when New_LCL is null then LCL_CONTROL else New_LCL end as New_LCL 
		--,Process_Name
		--,test_varchar = 'No Input'
from (select 
		Package
		,Device+ case when TapingDirection = null then Device else TapingDirection end as Device
		,TestFlow
		,format(avg(YLD) - stdev(YLD)*3,'n2') as New_LCL
		--,Process_Name
from (select a.LotNo
		,Type_Name as Package
		,case WHEN  CHARINDEX('(', b.Device) > 0 THEN LEFT (b.Device,CHARINDEX('(', b.Device) -1)END  as  Device
		,TestFlow = case when Process_Code = 891 then NULL when Process_Code = 892 then 'AUTO1' when Process_Code = 893 then 'AUTO2' when Process_Code = 894 then 'AUTO3' when Process_Code = 895 then 'AUTO4'  when Process_Code = 896 then 'AUTO5'end 
		,GOOD_QTY as Total_Good
		,FT_NG_QTY as Total_NG
		,case when (GOOD_QTY+FT_NG_QTY)= 0 then null else CONVERT(float,GOOD_QTY/CAST((GOOD_QTY+FT_NG_QTY) as float))*100  end as YLD
		,TapingDirection
		--,Process_Name = 'MAP'
from DBx.dbo.IS_MAP_FT_W_REC a
inner join DBx.dbo.TransactionData b 
on a.LotNo = b.LotNo
where case when (GOOD_QTY+FT_NG_QTY)= 0 then null else CONVERT(float,GOOD_QTY/CAST((GOOD_QTY+FT_NG_QTY) as float))*100  end >= 95
and Date1 between  case when  @Date = '' then  DATEADD(m, - 3, DATEADD(month, DATEDIFF(MONTH, 0, getdate()), 0)) else DATEADD(m, - 3, DATEADD(month, DATEDIFF(MONTH, 0, @Date), 0))end and	case when @Date = '' then DATEADD(MONTH, DATEDIFF(MONTH, 0, getdate()), -1) else DATEADD(MONTH, DATEDIFF(MONTH, 0, @Date), -1) end 
and ROHM_Model_Name  in  (select DeviceName from dbx.dbo.OIS where   ProcessName like '%MAP%' and DeviceName not in (select DeviceName FROM [DBx].[dbo].[OIS] where ProcessName like '%FL%' or DeviceName is not null and ProcessName like '%FT%')  )
and GOOD_QTY != 0
and a.LotNo not like '%B%' 
 ) as a 
 where TestFlow is not null
 --and YLD >= 95
 group by Package,Device,TestFlow,TapingDirection
) as a
inner join dbx.dbo.IS_LCLMASTER b
on a.Device = b.ROHM_MODEL_NAME and a.TestFlow = b.FT_FLOW_NAME
) as c

) as b

on a.ROHM_MODEL_NAME = b.Device  and a.FT_FLOW_NAME = b.TestFlow and a.TYPE_NAME = b.Package and a.LCL_CONTROL = b.LCL_CONTROL


where ROHM_MODEL_NAME like '%'+@Device+'%' 
and TYPE_NAME like '%'+@Package+'%'
and a.ROHM_MODEL_NAME != ''
END
