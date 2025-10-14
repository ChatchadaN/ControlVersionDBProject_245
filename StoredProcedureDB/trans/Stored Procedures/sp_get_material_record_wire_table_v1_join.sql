-- =============================================
-- Author:		<Jakkapong Pureinsin>
-- Create date: <2/15/2022>
-- Description:	<For Wire Record Table Website.>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_record_wire_table_v1_join]
	@location as VARCHAR(30) = '%',
	@material_name as VARCHAR(250) ='%',
	@material_state as VARCHAR(250) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @table table ( 
		[barcode] [varchar](20) NOT NULL,
		[wireName] [nvarchar](50) NULL,
		[machineName] [nvarchar](50) NULL,
		[quantity] [decimal](18, 6) NULL,
		[material_state] [nvarchar](50) NULL,
		[ArriveDate] [datetime] NULL,
		[sendProcess] [datetime] NULL,
		[regProcess] [datetime] NULL,
		[toMachine] [datetime] NULL,
		[setupTime] [datetime] NULL,
		[returnTime] [datetime] NULL,
		[updated_at] [datetime] NULL,
		[tran_location] [int] NULL
	)

	DECLARE @table2 table ( 
		[barcode] [varchar](20) NOT NULL,
		[wireName] [nvarchar](50) NULL,
		[machineName] [nvarchar](50) NULL,
		[quantity] [decimal](18, 6) NULL,
		[material_state] [nvarchar](50) NULL,
		[ArriveDate] [datetime] NULL,
		[sendProcess] [datetime] NULL,
		[regProcess] [datetime] NULL,
		[toMachine] [datetime] NULL,
		[setupTime] [datetime] NULL,
		[returnTime] [datetime] NULL,
		[updated_at] [datetime] NULL,
		[tran_location] [int] NULL,
		[row] [int] NULL
	)

	--INSERT INTO @table
	--(
	--	barcode
	--	, wireName
	--	, machineName
	--	, quantity
	--	, material_state
	--	, ArriveDate
	--	, sendProcess
	--	, regProcess
	--	, toMachine
	--	, setupTime
	--	, returnTime
	--	, updated_at
	--	, tran_location
	--)
	--SELECT barcode
	--	, wireName
	--	, machineName
	--	, quantity
	--	, material_state
	--	, CONVERT(Char(16), ArriveDate ,20) as ArriveDate
	--	, CONVERT(Char(16), sendProcess ,20) as sendProcess
	--	, CONVERT(Char(16), regProcess ,20) as regProcess
	--	, CONVERT(Char(16), toMachine ,20) as toMachine
	--	, CONVERT(Char(16), setupTime ,20) as setupTime
	--	, CONVERT(Char(16), returnTime ,20) as returnTime
	--	, CONVERT(Char(16), updated_at ,20) as updated_at
	--	, tran_location 
	--FROM (
	--	SELECT *,COUNT(barcode) OVER (PARTITION BY barcode) as DublicateWH_regist 
	--	FROM -- Clear record,that dosen't have any movement(Progression)
	--	(
	--		SELECT DISTINCT barcode
	--			, updated_at
	--			, wireName
	--			, machineName
	--			, quantity
	--			, material_state
	--			, ArriveDate
	--			, [1] as sendProcess
	--			, LEAD([2],countProgress-(CRT+CST+CTM+CRP)) OVER (PARTITION BY barcode ORDER BY RankSameBarcode ASC) as regProcess
	--			, LEAD([3],countProgress-(CRT+CST+CTM)) OVER (PARTITION BY barcode ORDER BY RankSameBarcode ASC) as toMachine
	--			, LEAD([4],countProgress-(CST+(CRT))) OVER (PARTITION BY barcode ORDER BY RankSameBarcode ASC) as setupTime
	--			, LEAD([5],countProgress-CRT) OVER (PARTITION BY barcode ORDER BY RankSameBarcode ASC) as returnTime
	--			, tran_location 
	--		FROM 
	--			-- move record that have progression together.
	--			-- using ORDER BY RankSameBarcode becuase "RankSameBarcode"(full data row) will come last
	--			--SELECT DISTINCT clear null row
	--			-- select , Pro,RankSameBarcode column  for more detail.
	--		(
	--			SELECT *,RANK() OVER (PARTITION BY  barcode order by Pro,recordTimeRank ASC) as RankSameBarcode,
	--			COUNT(ALL Pro) OVER (PARTITION BY  barcode) as countProgress,
	--			COUNT(ALL [2]) OVER (PARTITION BY  barcode) as CRP,
	--			COUNT(ALL [3]) OVER (PARTITION BY  barcode) as CTM,
	--			COUNT(ALL [4]) OVER (PARTITION BY  barcode) as CST,
	--			COUNT(ALL [5]) OVER (PARTITION BY  barcode) as CRT
	--			FROM --Rank same barcode by timeRecord
	--			(
	--					SELECT *,Progression as Pro FROM --Find wire record, that have location movement. 
	--					(
	--						SELECT  
	--						recordMat.barcode,
	--						tranMat.location_id as tran_location,
	--						tranMat.updated_at,
	--						[material_codes].descriptions as material_state,
	--						reacordArr.recorded_at as ArriveDate,
	--						recordMat.record_class,
	--						recordMat.location_id,
	--						recordMat.to_location_id,
	--						recordMat.recorded_at,
	--						productions.name as wireName,
	--						machines.name as machineName,
	--						tranMat.quantity,
	--						RANK() OVER (PARTITION BY  recordMat.barcode,recordMat.record_class order by recordMat.recorded_at DESC ) as recordTimeRank, --Same Movement Type
	--						Case when recordMat.to_location_id IN (5,7) and recordMat.location_id in (1,2) and  recordMat.record_class = 2 then 1 
	--							when recordMat.to_location_id = 4 and recordMat.location_id in (7,5) and recordMat.record_class = 1 then 2
	--							when recordMat.to_location_id IN (9) and recordMat.location_id in (7,5) and recordMat.record_class = 2 then 3
	--							when recordMat.record_class = 5 and recordMat.location_id in (9) then 4
	--							when recordMat.record_class = 1 and recordMat.location_id in (9) and recordMat.to_location_id IN (7,5) then 5
	--						ELSE null END as Progression --Progression is degree of movement From WH to Machine
	--						FROM [APCSProDB].[trans].[material_records] as recordMat
	--						inner join [APCSProDB].[trans].[materials] as tranMat on recordMat.barcode = tranMat.barcode 
	--						inner join [APCSProDB].[trans].[material_arrival_records] as reacordArr on reacordArr.material_id = tranMat.arrival_material_id
	--						inner join  [APCSProDB].material.productions on tranMat.material_production_id = productions.id
	--						inner join [APCSProDB].[material].[categories] on productions.category_id = [categories].id
	--						inner join [APCSProDB].[material].[material_codes] on tranMat.material_state = [material_codes].code AND [material_codes].[group] = 'matl_state'
	--						left join [APCSProDB].[trans].[machine_materials] as machineMat on machineMat.material_id = recordMat.material_id
	--						left join [APCSProDB].mc.machines on machineMat.machine_id = machines.id
	--						where  [categories].name LIKE '%WIRE%' and recordMat.record_class in (1,2,5) 
	--						and [material_codes].descriptions LIKE @material_state and productions.name LIKE @material_name
	--					) as ProgressionTable where Progression is not null and record_class <> 0
	--				) as PivotTable
	--			PIVOT(
	--			MAX(recorded_at) 
	--			FOR Progression IN (
	--				[1], 
	--				[2], 
	--				[3], 
	--				[4],
	--				[5])
	--			) AS pivot_table

	--		) AS leadTable --where barcode = 012108260010	
	--	) AS countFindDub 
	--) AS Result 
	--where ((DublicateWH_regist = 1 and sendProcess is null) 
	--	OR (DublicateWH_regist >= 2 and (sendProcess is not null OR regProcess is not null OR toMachine is not null OR setupTime is not null)))  
	
	INSERT INTO @table
	(
		barcode
		, wireName
		, machineName
		, quantity
		, material_state
		, ArriveDate
		, sendProcess
		, regProcess
		, toMachine
		, setupTime
		, returnTime
		, updated_at
		, tran_location
	)
	SELECT barcode
		,wireName
		,machineName
		,quantity
		,material_state
		,CONVERT(Char(16), ArriveDate ,20) as ArriveDate
		,CONVERT(Char(16), sendProcess ,20) as sendProcess
		,CONVERT(Char(16), regProcess ,20) as regProcess
		,CONVERT(Char(16), toMachine ,20) as toMachine
		,CONVERT(Char(16), setupTime ,20) as setupTime
		,CONVERT(Char(16), returnTime ,20) as returnTime
		,CONVERT(Char(16), updated_at ,20) as updated_at
		,tran_location 
	FROM
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
							  and [material_codes].descriptions LIKE @material_state and productions.name LIKE @material_name
							  and tranmat.barcode = 012202020722
						   ) as ProgressionTable where Progression is not null OR record_class <> 0
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


	INSERT INTO @table2
	(
		barcode
		, wireName
		, machineName
		, quantity
		, material_state
		, ArriveDate
		, sendProcess
		, regProcess
		, toMachine
		, setupTime
		, returnTime
		, updated_at
		, tran_location
		, [row]
	)
	select [pro1].barcode
		, [pro1].wireName
		, [pro1].machineName
		, [pro1].quantity
		, [pro1].material_state
		, [pro1].ArriveDate
		, [pro1].sendProcess
		, [pro2].regProcess
		, [pro3].toMachine
		, [pro4].setupTime
		, [pro5].returnTime
		, [pro1].updated_at
		, [pro1].tran_location
		, [pro1].[Row]
	from (
		select barcode
			, wireName
			, machineName
			, quantity
			, material_state
			, ArriveDate
			, sendProcess
			, regProcess
			, toMachine
			, setupTime
			, returnTime
			, updated_at
			, tran_location
			, ROW_NUMBER() OVER(ORDER BY barcode,(case when sendProcess is not null then 0 else 1 end),sendProcess) as [row]
		from @table
	) as [pro1] 
	inner join (
		select barcode
			, wireName
			, machineName
			, quantity
			, material_state
			, ArriveDate
			, regProcess
			, updated_at
			, tran_location
			, ROW_NUMBER() OVER(ORDER BY barcode,(case when regProcess is not null then 0 else 1 end),regProcess) as [row]
		from @table
	) as [pro2] on [pro1].[barcode] = [pro2].[barcode]
		and [pro1].[wireName] = [pro2].[wireName]
		and [pro1].[row] = [pro2].[row]
	inner join (
		select barcode
			, wireName
			, machineName
			, quantity
			, material_state
			, ArriveDate
			, toMachine
			, updated_at
			, tran_location
			, ROW_NUMBER() OVER(ORDER BY barcode,(case when toMachine is not null then 0 else 1 end),toMachine) as [Row]
		from @table
	) as [pro3] on [pro1].[barcode] = [pro3].[barcode]
		and [pro1].[wireName] = [pro3].[wireName]
		and [pro1].[row] = [pro3].[row]
	inner join (
		select barcode
			, wireName
			, machineName
			, quantity
			, material_state
			, ArriveDate
			, setupTime
			, updated_at
			, tran_location
			, ROW_NUMBER() OVER(ORDER BY barcode,(case when setupTime is not null then 0 else 1 end),setupTime) as [Row]
		from @table
	) as [pro4] on [pro1].[barcode] = [pro4].[barcode]
		and [pro1].[wireName] = [pro4].[wireName]
		and [pro1].[row] = [pro4].[row]
	inner join (
		select barcode
			, wireName
			, machineName
			, quantity
			, material_state
			, ArriveDate
			, returnTime
			, updated_at
			, tran_location
			, ROW_NUMBER() OVER(ORDER BY barcode,(case when returnTime is not null then 0 else 1 end),returnTime) as [Row]
		from @table
	) as [pro5] on [pro1].[barcode] = [pro5].[barcode]
		and [pro1].[wireName] = [pro5].[wireName]
		and [pro1].[row] = [pro5].[row]
	

	select barcode
		, wireName
		, machineName
		, quantity
		, material_state
		, ArriveDate
		, sendProcess
		, regProcess
		, toMachine
		, setupTime
		, returnTime
		, [t1].updated_at
		--, tran_location
		, locations.name WireLoaction
		, [row] 
	from @table2 as [t1]
	inner join APCSProDB.material.locations on locations.id = [t1].tran_location
	WHERE tran_location LIKE @location
		--and barcode = 012108260010
	ORDER BY barcode asc,[row]

END

