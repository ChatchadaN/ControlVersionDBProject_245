-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_New_LCL]

AS

BEGIN  
DELETE FROM [DBx].[dbo].[NEW_LCL]
END 

BEGIN
INSERT INTO [DBx].[dbo].[NEW_LCL]
           ([TYPE_NAME]
           ,[ROHM_MODEL_NAME]
           ,[FT_FLOW]
           ,[LCL_CONTROL]
           ,[NEW_LCL_CONTROL])
     (
	 select TYPE_NAME = case WHEN  CHARINDEX(' ', TYPE_NAME) > 0 THEN LEFT (TYPE_NAME ,CHARINDEX(' ', TYPE_NAME) -1) else TYPE_NAME  END 
	 , ROHM_MODEL_NAME = case WHEN  CHARINDEX(' ', b.Device) > 0 THEN LEFT (b.Device ,CHARINDEX(' ', b.Device) -1) else b.Device  END
	 ,FT_FLOW_NAME =CONVERT(varchar(10),case WHEN  CHARINDEX(' ', FT_FLOW_NAME) > 0 THEN LEFT (FT_FLOW_NAME ,CHARINDEX(' ', FT_FLOW_NAME) -1) else FT_FLOW_NAME  END)
	 ,LCL_CONTROL = round(b.LCL_CONTROL ,1)
	 ,NEW_LCL_CONTROL = case when New_LCL <0 then round(LCL_CONTROL,1) 
	when New_LCL > LCL_CONTROL then round(LCL_CONTROL,1)
	when New_LCL is null then round(LCL_CONTROL,1)
	when New_LCL < 80 then round(80.00,1)
	else round(New_LCL,1) end
from(
		select Device,Package ,New_LCL = AVG(a.FinalYield) - 3*(STDEV(a.FinalYield)) ,TestFlow
		from(
			select LotNo,LotStartTime,FinalYield,TestFlow
			from(
				select 
					LotNo
					,LotStartTime
					,FinalYield = case when (GoodAdjust + FTNGAdjust) = 0 then null else CONVERT(float,GoodAdjust/CAST((GoodAdjust + FTNGAdjust) as float))*100  end
					,TestFlow = case when TestFlow is null then 'AUTO1' when TestFlow = '' then 'AUTO1' when TestFlow like '%AUTO%' then 'AUTO1' else TestFlow end
				from dbx.dbo.FLData a
				where  FTNGAdjust is not null 
				and LotEndTime is not null
				and case when Remark is null then'' else Remark end not like '%ASI%' 
				and LotNo not like '%B%'
				and LotStartTime in (select LotStartTime = max(LotStartTime) from dbx.dbo.FLData where LotNo = a.LotNo group by LotNo)
				and GoodAdjust in (select GoodAdjust from dbx.dbo.FLData where LotNo = a.LotNo and LotStartTime = a.LotStartTime)
				and FTNGAdjust in (select FTNGAdjust from dbx.dbo.FLData where LotNo = a.LotNo and LotStartTime = a.LotStartTime)
			) as a
			union select LotNo,LotStartTime,FinalYield,TestFlow
					from(
						select  
								a.LotNo
								,LotStartTime
								,FinalYield = case when (TotalGoodBin1Qty + TotalNGQty) = 0 then null else CONVERT(float,TotalGoodBin1Qty/CAST((TotalGoodBin1Qty + TotalNGQty) as float))*100  end
								,TestFlow = TestFlowName
						from(select 
								LotNo
								,LotStartTime
								,TotalGoodBin1Qty
								,TotalNGQty
								,TestFlowName
							from dbx.dbo.FTData a
							where  TotalNGQty is not null 
							and LotEndTime is not null
							and case when Remark is null then'' else Remark end not like '%ASI%'  
							and LotNo not like '%B%'
							and TestFlowName <> 'AUTO0'
							and TotalGoodBin1Qty <> '0'
							and LotStartTime in (select LotStartTime = max(LotStartTime) from dbx.dbo.FTData where LotNo = a.LotNo group by LotNo,TestFlowName)
							and TotalGoodBin1Qty in (select TotalGoodBin1Qty from dbx.dbo.FTData where LotNo = a.LotNo and LotStartTime = a.LotStartTime)
							and TotalNGQty in (select TotalNGQty from dbx.dbo.FTData where LotNo = a.LotNo and LotStartTime = a.LotStartTime)
						) as a
						inner join [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]  b
						on a.LotNo = b.LOT_NO_2
						where FORM_NAME_3 not like '%vson%' and FORM_NAME_3 not like '%sson%' and FORM_NAME_3 not like '%uson%'


			) as b
			union select LotNo,LotStartTime,FinalYield,TestFlow
			from (
				select 
					LotNo
					,LotStartTime
					,FinalYield = case when (TotalGood + TotalNG) = 0 then null else CONVERT(float,TotalGood/CAST((TotalGood + TotalNG) as float))*100  end
					,TestFlow = case when Process = 'osft' then 'AUTO1' when Process = 'os/ft' then 'AUTO1' else Process end
				from dbx.dbo.MAPOSFTData a
				where LotEndTime is not null
				and case when Remark is null then'' else Remark end not like '%ASI%' 
				and LotNo not like '%B%'
				and TotalGood <> '0'
				and LotStartTime in (select LotStartTime = max(LotStartTime) from dbx.dbo.MAPOSFTData where LotNo = a.LotNo group by LotNo)
				and TotalGood in (select TotalGood from dbx.dbo.MAPOSFTData where LotNo = a.LotNo and LotStartTime = a.LotStartTime)
				and TotalNG in (select TotalNG from dbx.dbo.MAPOSFTData where LotNo = a.LotNo and LotStartTime = a.LotStartTime)

			) as c
	) as a
	inner join (SELECT distinct LotNo = LOT_NO_2
					,Device  = CASE  WHEN FT_MODEL_NAME_2 = 'BA00DD0WHFP' or FT_MODEL_NAME_2 ='BA00DD0WHFP-M3' 
					or FT_MODEL_NAME_2 = 'BD00C0AWFP' or FT_MODEL_NAME_2 ='BD00C0AWFP-C' 
					or FT_MODEL_NAME_2 ='BD9009HFP' or FT_MODEL_NAME_2 ='BD9009HFP-M'
					or FT_MODEL_NAME_2 ='BD9009HFP-BZM'  THEN  FT_MODEL_NAME_2
					WHEN  CHARINDEX('-', FT_MODEL_NAME_2) > 0 THEN LEFT (FT_MODEL_NAME_2,CHARINDEX('-', FT_MODEL_NAME_2) -1)
					ELSE FT_MODEL_NAME_2 END 
					,Package = FORM_NAME_3   
					,PACKAGE_FORM_NAME
					FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] )as b
	on a.LotNo = b.LotNo
	where LotStartTime between DATEADD(DAY,1,EOMONTH(getdate(),-4)) and  EOMONTH(getdate(),-1) 
	group by b.Device,b.Package,TestFlow
) as a
right join (select distinct
	Device  = CASE  WHEN Device = 'BA00DD0WHFP' or Device ='BA00DD0WHFP-M3' 
	or Device = 'BD00C0AWFP' or Device ='BD00C0AWFP-C' 
	or Device ='BD9009HFP' or Device ='BD9009HFP-M'
	or Device ='BD9009HFP-BZM'  THEN  Device
	WHEN  CHARINDEX('-', Device) > 0 THEN LEFT (Device,CHARINDEX('-', Device) -1)
	ELSE Device END 
	,TYPE_NAME
	,FT_FLOW_NAME
	,LCL_CONTROL
		from(
			select distinct 
			Device = CASE WHEN  CHARINDEX('-E2', ROHM_MODEL_NAME) > 0 THEN LEFT (ROHM_MODEL_NAME,CHARINDEX('-E2', ROHM_MODEL_NAME) -1) 
			WHEN  CHARINDEX('E2', ROHM_MODEL_NAME) > 0 THEN LEFT (ROHM_MODEL_NAME,CHARINDEX('E2', ROHM_MODEL_NAME) -1)
			WHEN  CHARINDEX('-TR', ROHM_MODEL_NAME) > 0 THEN LEFT (ROHM_MODEL_NAME,CHARINDEX('-TR', ROHM_MODEL_NAME) -1)
			WHEN  CHARINDEX('TR', ROHM_MODEL_NAME) > 0 THEN LEFT (ROHM_MODEL_NAME,CHARINDEX('TR', ROHM_MODEL_NAME) -1)
			ELSE ROHM_MODEL_NAME
			END
			,TYPE_NAME = case WHEN  CHARINDEX(' ', TYPE_NAME) > 0 THEN LEFT (TYPE_NAME ,CHARINDEX(' ', TYPE_NAME) -1) else TYPE_NAME  END 
			,FT_FLOW_NAME
			,LCL_CONTROL
			from dbx.dbo.IS_LCLMASTER
		)as a
) as b
on a.Device = b.Device and a.Package = b.TYPE_NAME and a.TestFlow = b.FT_FLOW_NAME
	)
END
