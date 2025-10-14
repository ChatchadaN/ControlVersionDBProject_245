-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_Detail] 
	-- Add the parameters for the stored procedure here

	@Package varchar (20),
	@Device varchar (50),
	@Flow varchar (6),
	@Date date 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
		select LotNo
		,Package
		,Device
		,TestFlow
		,Total_Good
		,Total_NG
		,YLD
		,LotEndTime
		,Process_Name

from (
(select	a.LotNo 
		,TRIM(Package) as Package
		,TRIM(case WHEN  CHARINDEX('(', b.Device) > 0 THEN LEFT (b.Device,CHARINDEX('(', b.Device) -1)END + case when TapingDirection is null then '' else TapingDirection end) as  Device
		,TRIM(case when TestFlow is null then 'AUTO1' when TestFlow = '' then 'AUTO1' else TestFlow end) as TestFlow
		,a.GoodAdjust as Total_Good
		,a.FTNGAdjust as  Total_NG
		,ROUND (case when (GoodAdjust+FTNGAdjust)= 0 then null else CONVERT(float,GoodAdjust/CAST((GoodAdjust+FTNGAdjust) as float))*100  end ,1) as YLD
		,LotEndTime
		,Process_Name = 'FL'
from DBx.dbo.FLData a
inner join DBx.dbo.TransactionData b 
on a.LotNo = b.LotNo
where  a.LotNo in (select LotNo from DBx.dbo.FLData where LotNo not like '%B%' and GoodAdjust != 0 and a.GoodAdjust is not null and a.FTNGAdjust is not null and case when CHARINDEX('-', b.Device) > 0 THEN LEFT (b.Device,CHARINDEX('-', b.Device) -1) end in
						(select DeviceName from dbx.dbo.OIS where   ProcessName like '%FL%' and DeviceName not in (select DeviceName FROM [DBx].[dbo].[OIS] where ProcessName like '%FT%' or DeviceName is not null and ProcessName like '%MAP%')))
and GoodAdjust != '0'
and case when (GoodAdjust+FTNGAdjust)= 0 then null else CONVERT(float,GoodAdjust/CAST((GoodAdjust+FTNGAdjust) as float))*100  end >= 95
)
		union (select LotNo
		,TRIM(Type_Name) as Package
		,TRIM(CHK_ROHM_Model_Name) as Device
		,TestFlow = TRIM(case when Process_Code = 891 then 'AUTO0' when Process_Code = 892 then 'AUTO1' when Process_Code = 893 then 'AUTO2' when Process_Code = 894 then 'AUTO3' when Process_Code = 895 then 'AUTO4'  when Process_Code = 896 then 'AUTO5'end) 
		,GOOD_QTY as Total_Good
		,FT_NG_QTY as Total_NG
		,ROUND(case when (GOOD_QTY+FT_NG_QTY)= 0 then null else CONVERT(float,GOOD_QTY/CAST((GOOD_QTY+FT_NG_QTY) as float))*100  end ,1)as YLD
		,Date1 as LotEndTime
		,Process_Name = 'FT'
from DBx.dbo.IS_FT_W_REC
where  LotNo not like '%B%'
and LotNo  in (select LotNo from DBx.dbo.TransactionData 
					where case WHEN  CHARINDEX('-', CHK_ROHM_Model_Name) > 0 THEN LEFT (CHK_ROHM_Model_Name,CHARINDEX('-', CHK_ROHM_Model_Name) -1)  END	
						in  (select DeviceName from dbx.dbo.OIS where   ProcessName like '%FT%' and DeviceName not in (select DeviceName FROM [DBx].[dbo].[OIS] where ProcessName like '%FL%' or DeviceName is not null and ProcessName like '%MAP%')))
and GOOD_QTY != '0'
and case when (GOOD_QTY+FT_NG_QTY)= 0 then null else CONVERT(float,GOOD_QTY/CAST((GOOD_QTY+FT_NG_QTY) as float))*100  end >= 95
)
	union (select a.LotNo
		,TRIM(Type_Name) as Package
		,TRIM(case WHEN  CHARINDEX('(', b.Device) > 0 THEN LEFT (b.Device,CHARINDEX('(', b.Device) -1)END + TapingDirection) as  Device
		,TestFlow = TRIM(case when Process_Code = 891 then NULL when Process_Code = 892 then 'AUTO1' when Process_Code = 893 then 'AUTO2' when Process_Code = 894 then 'AUTO3' when Process_Code = 895 then 'AUTO4'  when Process_Code = 896 then 'AUTO5'end )
		,GOOD_QTY as Total_Good
		,FT_NG_QTY as Total_NG
		,ROUND(case when (GOOD_QTY+FT_NG_QTY)= 0 then null else CONVERT(float,GOOD_QTY/CAST((GOOD_QTY+FT_NG_QTY) as float))*100  end ,1)as YLD
		,Date1 as LotEndTime
		,Process_Name = 'MAP'
from DBx.dbo.IS_MAP_FT_W_REC a
inner join DBx.dbo.TransactionData b 
on a.LotNo = b.LotNo
where  a.LotNo not like '%B%'
and ROHM_Model_Name  in  (select DeviceName from dbx.dbo.OIS where   ProcessName like '%MAP%' and DeviceName not in (select DeviceName FROM [DBx].[dbo].[OIS] where ProcessName like '%FL%' or DeviceName is not null and ProcessName like '%FT%')  )
and GOOD_QTY  != '0'
and case when (GOOD_QTY+FT_NG_QTY)= 0 then null else CONVERT(float,GOOD_QTY/CAST((GOOD_QTY+FT_NG_QTY) as float))*100  end >= 95
)
) as a
where LotEndTime between
	 case when  @Date = '' then  DATEADD(m, - 3, DATEADD(month, DATEDIFF(MONTH, 0, getdate()), 0)) 
		else DATEADD(m, - 3, DATEADD(month, DATEDIFF(MONTH, 0, @Date), 0))end
and  case when @Date = '' then DATEADD(MONTH, DATEDIFF(MONTH, 0, getdate()), -1)
		else DATEADD(MONTH, DATEDIFF(MONTH, 0, @Date), -1)end



and Device =  @Device
and Package = @Package
and TestFlow = @Flow


order by LotNo

END
