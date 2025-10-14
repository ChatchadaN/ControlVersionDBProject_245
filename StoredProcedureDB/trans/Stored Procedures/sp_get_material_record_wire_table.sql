-- =============================================
-- Author:		<Jakkapong Pureinsin>
-- Create date: <2/15/2022>
-- Description:	<For Wire Record Table Website.>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_record_wire_table]
	@location as NVARCHAR(50) = '%',
	@material_id as NVARCHAR(30) = '',
	@material_state as NVARCHAR(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;




	SELECT AfterPivot.barcode,locations.name as WireLoaction,ProcessState.descriptions as process_state,wireName,machineName,AfterPivot.quantity,
		CONVERT(Char(16), AfterPivot.updated_at ,20) as updated_at,
		CONVERT(Char(16), AfterPivot.material_state ,20) as material_state,
		CONVERT(Char(16), ArriveDate ,20) as ArriveDate,
		--CONVERT(Char(16), MAX([1]) ,20) as sendProcess,
		case when AfterPivot.parent_material_id is null then CONVERT(Char(16), MAX([1]) ,20)
			when AfterPivot.parent_material_id is not null and Parent_StockOut.recorded_at is not null  then CONVERT(Char(16),Parent_StockOut.recorded_at ,20)
			when AfterPivot.parent_material_id is not null and Parent_StockOut.recorded_at is null then CONVERT(Char(16), MAX([1]),20)
		else 'Error' end as sendProcess,
		case when AfterPivot.parent_material_id is null then CONVERT(Char(16), MAX([2]) ,20)
			when AfterPivot.parent_material_id is not null and Parent_StockIn.recorded_at is not null  then CONVERT(Char(16),Parent_StockIn.recorded_at ,20)
			when AfterPivot.parent_material_id is not null and Parent_StockIn.recorded_at is null then CONVERT(Char(16), MAX([2]),20)
		else 'Error' end as regProcess,
		CONVERT(Char(16), MAX([3]) ,20)as toMachine,
		CONVERT(Char(16), MAX([4]) ,20) as setupTime,
		CONVERT(Char(16), MAX([5]) ,20) as returnTime,
		reuseCount
		FROM
		(
		SELECT *,RANK() OVER (PARTITION BY  barcode order by Pro,recordTimeRank ASC) as RankSameBarcode, COUNT([5]) OVER (PARTITION BY barcode) as reuseCount
		FROM --Rank same barcode by timeRecord
		(
				SELECT *,Progression as Pro FROM --Find wire record, that have location movement. 
				(
					SELECT
					recordMat.barcode,
					tranMat.location_id as tran_location,
					tranMat.updated_at,
					tranMat.parent_material_id,
					[material_codes].descriptions as material_state,
					reacordArr.recorded_at as ArriveDate,
					recordMat.record_class,
					recordMat.location_id,
					recordMat.to_location_id,
					recordMat.recorded_at,
					productions.name as wireName,
					machines.name as machineName,
					tranMat.quantity,
					tranMat.process_state,
					RANK() OVER (PARTITION BY  recordMat.barcode,recordMat.record_class order by recordMat.recorded_at DESC ) as recordTimeRank, --Same Movement Type
					Case when recordMat.to_location_id IN (5,7) and recordMat.location_id in (1,2) and  recordMat.record_class = 2 then 1 
						--when recordMat.to_location_id = 4 and recordMat.location_id in (7,5) and recordMat.record_class = 1 then 2 // Updata by Aun 29/01/2025
						when recordMat.to_location_id in (4,5)  and recordMat.location_id in (5,7) and recordMat.record_class in (1,9) then 2
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
					where  [categories].name LIKE '%WIRE%' and recordMat.record_class in (1,2,5,9) 
					and [material_codes].descriptions like @material_state and 
					(productions.id IN ((SELECT * FROM STRING_SPLIT(@material_id, ','))) OR productions.id IN (IIF(@material_id = '',productions.id,0)))
					and tranmat.location_id NOT IN ( 12) and tranMat.material_state != 0

				) as ProgressionTable where Progression is not null OR record_class in (1,2,5,9) --เอาตัวที่ไม่มีการเคลื่อนไหวด้วย ไม่มี Progression
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
		) AS AfterPivot
		inner join APCSProDB.material.locations on locations.id = AfterPivot.tran_location
		inner join [APCSProDB].[material].[material_codes] as ProcessState on process_state = ProcessState.code and ProcessState.[group] = 'process_state'
		--left join  [APCSProDB].[trans].[materials] as ParentMat on AfterPivot.parent_material_id = ParentMat.id
		left join [APCSProDB].[trans].[material_records] as Parent_StockOut on AfterPivot.parent_material_id = Parent_StockOut.material_id and Parent_StockOut.location_id = 1 and Parent_StockOut.to_location_id = 5 and Parent_StockOut.record_class = 2
		--left join [APCSProDB].[trans].[material_records] as Parent_StockIn on AfterPivot.parent_material_id = Parent_StockIn.material_id and Parent_StockIn.location_id = 5 and Parent_StockIn.to_location_id = 4 and Parent_StockIn.record_class = 1 --// Updata by Aun 29/01/2025
		left join [APCSProDB].[trans].[material_records] as Parent_StockIn on AfterPivot.parent_material_id = Parent_StockIn.material_id and Parent_StockIn.location_id = 5 and Parent_StockIn.to_location_id = 5 and Parent_StockIn.record_class = 9
		where locations.name like @location
		GROUP BY AfterPivot.barcode,locations.name,AfterPivot.updated_at,AfterPivot.material_state,ArriveDate,machineName,
		AfterPivot.quantity,reuseCount,wireName,ProcessState.descriptions,AfterPivot.parent_material_id,Parent_StockOut.recorded_at,
		Parent_StockIn.recorded_at


END

