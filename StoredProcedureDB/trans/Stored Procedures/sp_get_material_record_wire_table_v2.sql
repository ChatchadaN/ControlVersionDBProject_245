-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_record_wire_table_v2]
	-- Add the parameters for the stored procedure here
	@location as NVARCHAR(50) = '%',
	@material_id as NVARCHAR(30) = '',
	@material_state as NVARCHAR(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

					  
		SELECT barcode,wireName,machineName,quantity,tran_location,updated_at,material_state,ArriveDate,
		MAX([1]) as sendProcess,
		MAX([2]) as regProcess,
		MAX([3]) as toMachine,
		MAX([4]) as setupTime,
		MAX([5]) as returnTime,
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
					[material_codes].descriptions as material_state,
					reacordArr.created_at as ArriveDate,
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
		) AS AfterPivot GROUP BY barcode,tran_location,updated_at,material_state,ArriveDate,machineName,quantity,reuseCount,wireName


END
