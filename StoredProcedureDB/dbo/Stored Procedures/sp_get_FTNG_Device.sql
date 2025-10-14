-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_FTNG_Device] 

AS
BEGIN
	select distinct a.Device,a.Package,FT_Good,FT_NG,OS_NG,Meka_NG,Vis_NG,Unk_NG,Thai_Bath,US_Dollar,Good_Amount,Ng_Amount,Problem,b.Group_PKG,a.Date
from(
	select a.Device,a.Package,FT_Good,FT_NG,OS_NG,Meka_NG,Vis_NG,Unk_NG,Thai_Bath,US_Dollar,Good_Amount,Ng_Amount,Problem = case when b.Mode is null then 'FactoryNG' else b.Mode end ,a.Date
	from(
		select a.Device,Package,FT_Good = sum(FT_Good) ,FT_NG = sum(FT_NG),OS_NG = sum(OS_NG),Meka_NG  = sum(Meka_NG),Vis_NG = sum(Vis_NG),Unk_NG = sum(Unk_NG)
				,Thai_Bath = format(avg(Thai_Bath),'N3'),US_Dollar = format(avg(US_Dollar),'N3'),Good_Amount = format(sum(FT_Good) * avg(Thai_Bath),'N3'),Ng_Amount = format(sum(FT_NG) * avg(Thai_Bath),'N3'), Date
		from(
				select * 
				-------- FL -----------
				from(
				

					select a.LotNo,b.Device,b.Package,FT_Good,FT_NG,OS_NG,Meka_NG,Vis_NG = 0,Unk_NG = 0,Date = format(LotStartTime,'yyyy-MM')
					from(
						select a.LotNo,FT_Good = b.GoodAdjust,FT_NG = a.TotalNGQty,a. OS_NG , Meka_NG ,a.LotStartTime
						from(
							select a.LotNo,TotalNGQty = sum(a.FTNGAdjust),OS_NG = sum(a.OSNGAdjust),Meka_NG = sum(a.MekaNGAdjust),LotStartTime = max(a.LotStartTime)
							from(
								select a.LotNo,FTNGAdjust = case when FTNGAdjust is null then 0 else FTNGAdjust end,OSNGAdjust = case when OSNGAdjust is null then 0 else OSNGAdjust end,MekaNGAdjust = case when MekaNGAdjust is null then 0 else MekaNGAdjust end,a.LotStartTime
								from(
									select LotNo,LotStartTime = max(LotStartTime)
									from dbx.dbo.FLData a
									where GoodAdjust <> 0
									and FTNGAdjust is not null 
									and LotEndTime is not null
									and LotNo like '%A%'
									group by LotNo
									) as a
								inner join dbx.dbo.FLData b
								on a.LotNo = b.LotNo and a.LotStartTime = b.LotStartTime
								where a.LotStartTime between format(DATEADD(month, -3, getdate()),'yyyy-MM-dd') and format(DATEADD(month, 0, getdate()-1),'yyyy-MM-dd')
							) as a
							inner join dbx.dbo.FLData b
							on a.LotNo = b.LotNo and a.LotStartTime = b.LotStartTime
							group by a.LotNo
						)as a 
						inner join dbx.dbo.FLData b
						on a.LotNo = b.LotNo and a.LotStartTime =b.LotStartTime
						--where GoodAdjust <> 0
					)as a
					inner join (SELECT distinct LotNo = LOT_NO_2,Device  = FT_MODEL_NAME_1 ,Package = FORM_NAME_3   FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] )as b
					on a.LotNo = b.LotNo


				) as a
				-------- FL -----------
				-------- FT -----------
				union 
				select * 
				from(

					select a.LotNo,a.Device,a.Package,FT_Good,FT_NG,OS_NG,Meka,Vis_NG,Unk_NG, Date = format(LotStartTime,'yyyy-MM')
								from(
									select a.LotNo,b.Device,b.Package,FT_Good,FT_NG,OS_NG,Meka,Vis_NG,Unk_NG,LotStartTime
									from(
										select a.LotNo,FT_Good = b.TotalGoodBin1Qty,FT_NG = a.TotalNGQty,OS_NG = 0 , Meka = 0,a.Vis_NG ,a.Unk_NG,a.LotStartTime
										from(
											select a.LotNo,TotalNGQty = sum(a.TotalNGQty),Vis_NG = sum(a.TotalMeka1Qty)+ sum(a.TotalMeka2Qty)+ sum(a.TotalMeka4Qty),Unk_NG = sum(a.TotalUnknowQty),LotStartTime = max(a.LotStartTime)
											from(
												select a.LotNo,TotalNGQty,TotalMeka1Qty,TotalMeka2Qty,TotalMeka4Qty = case when TotalMeka4Qty < 0 then 0 else TotalMeka4Qty end,TotalUnknowQty,a.LotStartTime
												from(
													select LotNo,LotStartTime = max(LotStartTime)
													from dbx.dbo.FTData a
													where TotalGoodBin1Qty > 360
													and LotNo like'%A%'
													or LotNo like '%F%'
													group by LotNo,TestFlowName
													) as a
												inner join dbx.dbo.FTData b
												on a.LotNo = b.LotNo and a.LotStartTime = b.LotStartTime
												where a.LotStartTime between format(DATEADD(month, -3, getdate()),'yyyy-MM-dd') and format(DATEADD(month, 0, getdate()-1),'yyyy-MM-dd')
											) as a
											inner join dbx.dbo.FTData b
											on a.LotNo = b.LotNo and a.LotStartTime = b.LotStartTime
											group by a.LotNo
										)as a 
										inner join dbx.dbo.FTData b
										on a.LotNo = b.LotNo and a.LotStartTime =b.LotStartTime
									)as a
									inner join (SELECT distinct LotNo = LOT_NO_2,Device  = FT_MODEL_NAME_1 ,Package = FORM_NAME_3   FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] )as b
									on a.LotNo = b.LotNo
									where Package not like '%sson%' and Package not like '%vson%' and Package not like '%uson%'
								) as a
								inner join ( select  distinct DeviceName from dbx.dbo.OIS where ProcessName like '%FT%' )as b
								on case WHEN  CHARINDEX('-',a.Device) > 0 THEN LEFT (a.Device,CHARINDEX('-', a.Device) -1)  else a.Device end  =  b.DeviceName  
						) as b
				-------- FT -----------
				-------- MAP -----------
				union 
				select * 
				from(
				
					select a.LotNo,b.Device,b.Package,FT_Good,FT_NG,OS_NG,Meka,Vis_NG,Unk_NG,Date = format(LotStartTime,'yyyy-MM')
						from(
							select a.LotNo,FT_Good = b.TotalGood,FT_NG = a.TotalNGQty,OS_NG = 0 , Meka = 0,Vis_NG = 0 ,Unk_NG = 0,a.LotStartTime
							from(
								select a.LotNo,TotalNGQty = sum(a.FTNG),LotStartTime = max(a.LotStartTime)
								from(
									select a.LotNo,FTNG,a.LotStartTime
									from(
										select LotNo,LotStartTime = max(LotStartTime)
										from dbx.dbo.MAPOSFTData a
										where LotNo like'%A%'
										or LotNo like '%F%'
										group by LotNo,Process
										) as a
									inner join dbx.dbo.MAPOSFTData b
									on a.LotNo = b.LotNo and a.LotStartTime = b.LotStartTime
									where a.LotStartTime between format(DATEADD(month, -3, getdate()),'yyyy-MM-dd') and format(DATEADD(month, 0, getdate()-1),'yyyy-MM-dd')
								) as a
								inner join dbx.dbo.MAPOSFTData b
								on a.LotNo = b.LotNo and a.LotStartTime = b.LotStartTime
								group by a.LotNo
							)as a 
							inner join dbx.dbo.MAPOSFTData b
							on a.LotNo = b.LotNo and a.LotStartTime =b.LotStartTime
						)as a
						inner join (SELECT distinct LotNo = LOT_NO_2,Device  = FT_MODEL_NAME_1 ,Package = FORM_NAME_3   FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] )as b
						on a.LotNo = b.LotNo
	

				) as c
				-------- MAP -----------
		) as a
		 left join dbx.dbo.FTNG_Price_Unit b
		on a.Device = b.Device
		group by a.Device,Package,Date
	) as a
	left join dbx.dbo.FTNGDeviceKanban b
	on a.Device = b.Device and a.Package = b.PackageGroup and a.Date = b.Date
) as a
inner join (select Package = AssyName ,Group_PKG = Name
			from dbx.dbo.Package a
			inner join dbx.dbo.PackageGroup b
			on a.PackageGroupID = b.ID
			where PackageGroupID is not null) b
on a.Package = b.Package
END
