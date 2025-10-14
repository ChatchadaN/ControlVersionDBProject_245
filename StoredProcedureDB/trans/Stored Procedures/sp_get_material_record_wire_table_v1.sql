-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_record_wire_table_v1]
	@location as NVARCHAR(50) = '%',
	@material_id as NVARCHAR(30) = '',
	@material_state as NVARCHAR(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
	  SELECT *, RANK() OVER(PARTITION BY barcode order by setupTime DESC) AS ResultRank,
	  RANK() OVER(PARTITION BY barcode order by setupTime ASC,returnTime ASC) AS ResultRankReverse,
	  COUNT(barcode) OVER (PARTITION BY barcode) as CountByBarcode,
	  COUNT(regProcess) OVER (PARTITION BY barcode) as CountRP,
	  COUNT(toMachine) OVER (PARTITION BY barcode) as CountTM,
	  COUNT(setupTime) OVER (PARTITION BY barcode) as CountST,
	  COUNT(returnTime) OVER (PARTITION BY barcode) as CountRT
	  INTO #MyTemp FROM
	   (
	   SELECT barcode,wireName,machineName,quantity,material_state,CONVERT(Char(16), ArriveDate ,20) as ArriveDate
	  ,CONVERT(Char(16), sendProcess ,20) as sendProcess
	  ,CONVERT(Char(16), regProcess ,20) as regProcess
	  ,CONVERT(Char(16), toMachine ,20) as toMachine
	  ,CONVERT(Char(16), setupTime ,20) as setupTime
	  ,CONVERT(Char(16), returnTime ,20) as returnTime
	  ,CONVERT(Char(16), updated_at ,20) as updated_at,
	  tran_location FROM
	  (
		  SELECT *,COUNT(barcode) OVER (PARTITION BY barcode) as DublicateWH_regist FROM -- Clear record,that dosen't have any movement(Progression)
		  (
			  SELECT DISTINCT barcode,updated_at,wireName,machineName,quantity,material_state,ArriveDate,
					   [1] as sendProcess ,
					   LEAD([2],countProgress-(CRT+CST+CTM+CRP)) OVER (PARTITION BY barcode ORDER BY RankSameBarcode ASC) as regProcess ,
					   LEAD([3],countProgress-(CRT+CST+CTM)) OVER (PARTITION BY barcode ORDER BY RankSameBarcode ASC) as toMachine ,
					   LEAD([4],countProgress-(CST+(CRT))) OVER (PARTITION BY barcode ORDER BY RankSameBarcode ASC) as setupTime ,
					   LEAD([5],countProgress-CRT) OVER (PARTITION BY barcode ORDER BY RankSameBarcode ASC) as returnTime,
					   tran_location FROM 
					   -- move record that have progression together.
					   -- using ORDER BY RankSameBarcode becuase "RankSameBarcode"(full data row) will come last
					   --SELECT DISTINCT clear null row
					   -- select , Pro,RankSameBarcode column  for more detail.
			  (
				  SELECT *,RANK() OVER (PARTITION BY  barcode order by Pro,recordTimeRank ASC) as RankSameBarcode,
				  COUNT(ALL Pro) OVER (PARTITION BY  barcode) as countProgress,
				  COUNT(ALL [2]) OVER (PARTITION BY  barcode) as CRP,
				  COUNT(ALL [3]) OVER (PARTITION BY  barcode) as CTM,
				  COUNT(ALL [4]) OVER (PARTITION BY  barcode) as CST,
				  COUNT(ALL [5]) OVER (PARTITION BY  barcode) as CRT
				  FROM --Rank same barcode by timeRecord
				  (
						  SELECT *,Progression as Pro FROM --Find wire record, that have location movement. 
						  (
							  SELECT
							  recordMat.barcode,
							  tranMat.location_id as tran_location,
							  tranMat.updated_at,
							  [material_codes].descriptions as material_state,
							  reacordArr.recorded_at as ArriveDate,
							  recordMat.record_class,
							  recordMat.location_id,
							  recordMat.to_location_id,
							  recordMat.recorded_at,
							  productions.name as wireName,
							  machines.name as machineName,
							  tranMat.quantity,
							  RANK() OVER (PARTITION BY  recordMat.barcode,recordMat.record_class order by recordMat.recorded_at DESC ) as recordTimeRank, --Same Movement Type
							  Case when recordMat.to_location_id IN (5,7) and recordMat.location_id in (1,2) and  recordMat.record_class = 2 then 1 
								   when recordMat.to_location_id = 4 and recordMat.location_id in (7,5) and recordMat.record_class = 1 then 2
								   when recordMat.to_location_id IN (9) and recordMat.location_id in (7,5) and recordMat.record_class = 2 then 3
								   when recordMat.record_class = 5 and recordMat.location_id in (9) then 4
								   when recordMat.record_class = 1 and recordMat.location_id in (9) and recordMat.to_location_id IN (7,5) then 5
							  ELSE null END as Progression --Progression is degree of movement From WH to Machine
							  FROM [APCSProDB].[trans].[material_records] as recordMat
							  inner join [APCSProDB].[trans].[materials] as tranMat on recordMat.barcode = tranMat.barcode 
							  inner join [APCSProDB].[trans].[material_arrival_records] as reacordArr on reacordArr.material_id = tranMat.arrival_material_id
							  inner join  [APCSProDB].material.productions on tranMat.material_production_id = productions.id
							  inner join [APCSProDB].[material].[categories] on productions.category_id = [categories].id
							  inner join [APCSProDB].[material].[material_codes] on tranMat.material_state = [material_codes].code AND [material_codes].[group] = 'matl_state'
							  left join [APCSProDB].[trans].[machine_materials] as machineMat on machineMat.material_id = recordMat.material_id
							  left join [APCSProDB].mc.machines on machineMat.machine_id = machines.id
							  where  [categories].name LIKE '%WIRE%' and recordMat.record_class in (1,2,5) 
							  and [material_codes].descriptions LIKE @material_state and 
							  (productions.id IN ((SELECT * FROM STRING_SPLIT(@material_id, ','))) OR productions.id IN (IIF(@material_id = '',productions.id,0)))
							  and tranmat.location_id NOT IN ( 12) and tranMat.material_state != 0

						   ) as ProgressionTable where Progression is not null OR record_class in (1,2,5) --เอาตัวที่ไม่มีการเคลื่อนไหวด้วย ไม่มี Progression
					   ) as PivotTable
				   PIVOT(
					MAX(recorded_at) 
					FOR Progression IN (
						[1], 
						[2], 
						[3], 
						[4],
						[5])
					) AS pivot_table

				) AS leadTable -- where barcode = 012108260010	
			) AS countFindDub 
	) AS Result where ((DublicateWH_regist = 1 and sendProcess is null) 
		OR (DublicateWH_regist >= 2 and (sendProcess is not null OR regProcess is not null OR toMachine is not null OR setupTime is not null)))  
	) as ResultReverse -- where barcode = 012108260010	



	--SelfJoin Reverse Order
	--sql ordering DESC sendProcess not null meaning,it's a first row form ASC partition
	select LeftTable.barcode,
	locations.name WireLoaction,
	LeftTable.wireName,
	LeftTable.machineName,
	LeftTable.quantity,
	LeftTable.material_state,
	LeftTable.ArriveDate,
	LeftTable.sendProcess,
	LeftTable.regProcess,
	CASE WHEN LeftTable.CountRP = 1 then LeftTable.regProcess else
	LEAD(rightTable.regProcess,LeftTable.CountByBarcode-LeftTable.CountRP) OVER (PARTITION BY LeftTable.barcode ORDER BY RightTable.regProcess ASC) END as regProcess,
	--RightTable.toMachine,
	CASE WHEN LeftTable.CountTM = 1 then LeftTable.toMachine else
	LEAD(RightTable.toMachine,LeftTable.CountByBarcode-LeftTable.CountTM) OVER (PARTITION BY LeftTable.barcode ORDER BY RightTable.toMachine ASC) END as toMachine,
	--RightTable.setupTime,
	CASE WHEN LeftTable.CountST = 1 then LeftTable.setupTime else
	LEAD(RightTable.setupTime,LeftTable.CountByBarcode-LeftTable.CountST) OVER (PARTITION BY LeftTable.barcode ORDER BY RightTable.setupTime ASC) END as setupTime,
	--RightTable.returnTime
	CASE WHEN LeftTable.CountRT = 1 then LeftTable.returnTime else
	LEAD(RightTable.returnTime,LeftTable.CountByBarcode-LeftTable.CountRT) OVER (PARTITION BY LeftTable.barcode ORDER BY RightTable.returnTime ASC) END as returnTime
	,LeftTable.CountRP,LeftTable.CountByBarcode
	,LeftTable.updated_at 
	from #MyTemp as LeftTable
	inner join #MyTemp as RightTable on LeftTable.ResultRank = RightTable.ResultRankReverse and LeftTable.barcode = RightTable.barcode 
	inner join APCSProDB.material.locations on locations.id = LeftTable.tran_location
	where locations.name LIKE @location
	order by barcode DESC,sendProcess DESC
	--order by barcode DESC,ArriveDate ASC,sendProcess DESC,regProcess DESC,toMachine DESC,setupTime ASC

	drop table #MyTemp
END
