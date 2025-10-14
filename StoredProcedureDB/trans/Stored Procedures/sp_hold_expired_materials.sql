CREATE PROCEDURE [trans].[sp_hold_expired_materials]
AS
BEGIN

DECLARE @DAY_ID AS INT
SET @DAY_ID = (SELECT [STOREDPROCEDUREDB].[MATERIAL].[FN_GETDAYID](GETDATE()));

	-- STOCK OUT --
	INSERT INTO [APCSPRODB].[trans].[material_records]
			   ([id]
			   ,[day_id]
			   ,[recorded_at]
			   ,[operated_by]
			   ,[record_class]
			   ,[material_id]
			   ,[barcode]
			   ,[material_production_id]
			   ,[step_no]
			   ,[in_quantity]
			   ,[quantity]
			   ,[fail_quantity]
			   ,[pack_count]
			   ,[limit_base_date]
			   ,[is_production_usage]
			   ,[material_state]
			   ,[process_state]
			   ,[qc_state]
			   ,[first_ins_state]
			   ,[final_ins_state]
			   ,[limit_state]
			   ,[limit_date]
			   ,[extended_limit_date]
			   ,[open_limit_date1]
			   ,[open_limit_date2]
			   ,[wait_limit_date]
			   ,[location_id]
			   ,[acc_location_id]
			   ,[lot_no]
			   ,[qc_comment_id]
			   ,[qc_memo_id]
			   ,[arrival_material_id]
			   ,[parent_material_id]
			   ,[dest_lot_id]
			   ,[created_at]
			   ,[created_by]
			   ,[updated_at]
			   ,[updated_by]
			   ,[to_location_id])
	SELECT		(SELECT id FROM [APCSPRODB].trans.numbers where [name] = 'material_records.id') + ROW_NUMBER() OVER(ORDER BY [id] ASC) As [id]
				,@DAY_ID
				,GETDATE() as [recorded_at]
				,0 as [operated_by]
				,2 as [record_class]
			   ,[id] as [material_id]
			   ,[barcode] 
			   ,[material_production_id]
			   ,[step_no]
			   ,[in_quantity]
			   ,[quantity]
			   ,[fail_quantity]
			   ,[pack_count]
			   ,[limit_base_date]
			   ,[is_production_usage]
			   ,[material_state]
			   ,[process_state]
			   ,[qc_state]
			   ,[first_ins_state]
			   ,[final_ins_state]
			   ,[limit_state]
			   ,[limit_date]
			   ,[extended_limit_date]
			   ,[open_limit_date1]
			   ,[open_limit_date2]
			   ,[wait_limit_date]
			   ,[location_id]
			   ,[acc_location_id]
			   ,[lot_no]
			   ,[qc_comment_id]
			   ,[qc_memo_id]
			   ,[arrival_material_id]
			   ,[parent_material_id]
			   ,[dest_lot_id]
			   ,[created_at]
			   ,[created_by]
			   ,[updated_at]
			   ,[updated_by]
			   ,(SELECT ID FROM [APCSPRODB].material.locations where wh_code = 'QI999') AS to_location_id
	FROM [APCSPRODB].TRANS.MATERIALS 
	--อั๋น Update Expired เพิ่มเช็ค Col Extended 2020/01-30
	WHERE   ((LIMIT_DATE <= GETDATE() and EXTENDED_LIMIT_DATE IS NULL) OR (LIMIT_DATE <= GETDATE() and EXTENDED_LIMIT_DATE <= GETDATE())) 
	--LIMIT_DATE <= GETDATE()
	AND limit_state = 0
	AND QUANTITY > 0 --update by อั๋น 2022/03/17
	AND location_id IN (SELECT ID FROM [APCSPRODB].material.locations where wh_code = 'QI900');

	UPDATE [APCSPRODB].trans.numbers SET ID = (SELECT MAX(ID) FROM [APCSPRODB].[trans].[material_records])
		where [name] = 'material_records.id';

	-- STOCK IN --
	INSERT INTO [APCSPRODB].[trans].[material_records]
			   ([id]
			   ,[day_id]
			   ,[recorded_at]
			   ,[operated_by]
			   ,[record_class]
			   ,[material_id]
			   ,[barcode]
			   ,[material_production_id]
			   ,[step_no]
			   ,[in_quantity]
			   ,[quantity]
			   ,[fail_quantity]
			   ,[pack_count]
			   ,[limit_base_date]
			   ,[is_production_usage]
			   ,[material_state]
			   ,[process_state]
			   ,[qc_state]
			   ,[first_ins_state]
			   ,[final_ins_state]
			   ,[limit_state]
			   ,[limit_date]
			   ,[extended_limit_date]
			   ,[open_limit_date1]
			   ,[open_limit_date2]
			   ,[wait_limit_date]
			   ,[location_id]
			   ,[acc_location_id]
			   ,[lot_no]
			   ,[qc_comment_id]
			   ,[qc_memo_id]
			   ,[arrival_material_id]
			   ,[parent_material_id]
			   ,[dest_lot_id]
			   ,[created_at]
			   ,[created_by]
			   ,[updated_at]
			   ,[updated_by]
			   ,[to_location_id])
	SELECT		(SELECT id FROM [APCSPRODB].trans.numbers where [name] = 'material_records.id') + ROW_NUMBER() OVER(ORDER BY [id] ASC) As [id]
				,@DAY_ID
				,GETDATE() as [recorded_at]
				,0 as [operated_by]
				,1 as [record_class]
			   ,[id] as [material_id]
			   ,[barcode] 
			   ,[material_production_id]
			   ,[step_no]
			   ,[in_quantity]
			   ,[quantity]
			   ,[fail_quantity]
			   ,[pack_count]
			   ,[limit_base_date]
			   ,[is_production_usage]
			   ,[material_state]
			   ,[process_state]
			   ,[qc_state]
			   ,[first_ins_state]
			   ,[final_ins_state]
			   ,[limit_state]
			   ,[limit_date]
			   ,[extended_limit_date]
			   ,[open_limit_date1]
			   ,[open_limit_date2]
			   ,[wait_limit_date]
			   ,(SELECT ID FROM [APCSPRODB].material.locations where wh_code = 'QI999') AS to_location_id
			   ,[acc_location_id]
			   ,[lot_no]
			   ,[qc_comment_id]
			   ,[qc_memo_id]
			   ,[arrival_material_id]
			   ,[parent_material_id]
			   ,[dest_lot_id]
			   ,[created_at]
			   ,[created_by]
			   ,[updated_at]
			   ,[updated_by]
			   ,[location_id]
	FROM [APCSPRODB].TRANS.MATERIALS 
	--อั๋น Update Expired เพิ่มเช็ค Col Extended 2020/01-30
	WHERE   ((LIMIT_DATE <= GETDATE() and EXTENDED_LIMIT_DATE IS NULL) OR (LIMIT_DATE <= GETDATE() and EXTENDED_LIMIT_DATE <= GETDATE())) 
	--LIMIT_DATE <= GETDATE() 
	AND limit_state = 0
	AND QUANTITY > 0 --update by อั๋น 2022/03/17
	AND location_id IN (SELECT ID FROM [APCSPRODB].material.locations where wh_code = 'QI900');

	UPDATE [APCSPRODB].trans.numbers SET ID = (SELECT MAX(ID) FROM [APCSPRODB].[trans].[material_records])
		where [name] = 'material_records.id';

	-- DATA INTERFACE / MIAO --
	INSERT INTO [APCSPRODB].[trans].[material_records]
			   ([id]
			   ,[day_id]
			   ,[recorded_at]
			   ,[operated_by]
			   ,[record_class]
			   ,[material_id]
			   ,[barcode]
			   ,[material_production_id]
			   ,[step_no]
			   ,[in_quantity]
			   ,[quantity]
			   ,[fail_quantity]
			   ,[pack_count]
			   ,[limit_base_date]
			   ,[is_production_usage]
			   ,[material_state]
			   ,[process_state]
			   ,[qc_state]
			   ,[first_ins_state]
			   ,[final_ins_state]
			   ,[limit_state]
			   ,[limit_date]
			   ,[extended_limit_date]
			   ,[open_limit_date1]
			   ,[open_limit_date2]
			   ,[wait_limit_date]
			   ,[location_id]
			   ,[acc_location_id]
			   ,[lot_no]
			   ,[qc_comment_id]
			   ,[qc_memo_id]
			   ,[arrival_material_id]
			   ,[parent_material_id]
			   ,[dest_lot_id]
			   ,[created_at]
			   ,[created_by]
			   ,[updated_at]
			   ,[updated_by]
			   ,[to_location_id])
	SELECT		(SELECT id FROM [APCSPRODB].trans.numbers where [name] = 'material_records.id') + ROW_NUMBER() OVER(ORDER BY [id] ASC) As [id]
				,@DAY_ID
				,GETDATE() as [recorded_at]
				,0 as [operated_by]
				,40 as [record_class]
			   ,[id] as [material_id]
			   ,[barcode] 
			   ,[material_production_id]
			   ,[step_no]
			   ,[in_quantity]
			   ,[quantity]
			   ,[fail_quantity]
			   ,[pack_count]
			   ,[limit_base_date]
			   ,[is_production_usage]
			   ,1 as [material_state]
			   ,[process_state]
			   ,[qc_state]
			   ,[first_ins_state]
			   ,[final_ins_state]
			   ,5 as [limit_state]
			   ,[limit_date]
			   ,[extended_limit_date]
			   ,[open_limit_date1]
			   ,[open_limit_date2]
			   ,[wait_limit_date]
			   ,(SELECT ID FROM [APCSPRODB].material.locations where wh_code = 'QI999') AS to_location_id
			   ,[acc_location_id]
			   ,[lot_no]
			   ,[qc_comment_id]
			   ,[qc_memo_id]
			   ,[arrival_material_id]
			   ,[parent_material_id]
			   ,[dest_lot_id]
			   ,[created_at]
			   ,[created_by]
			   ,[updated_at]
			   ,[updated_by]
			   ,[location_id]
	FROM [APCSPRODB].TRANS.MATERIALS 
	--อั๋น Update Expired เพิ่มเช็ค Col Extended 2020/01-30
	WHERE   ((LIMIT_DATE <= GETDATE() and EXTENDED_LIMIT_DATE IS NULL) OR (LIMIT_DATE <= GETDATE() and EXTENDED_LIMIT_DATE <= GETDATE())) 
	--LIMIT_DATE <= GETDATE()
	AND limit_state = 0
	AND QUANTITY > 0 --update by อั๋น 2022/03/17
	AND location_id IN (SELECT ID FROM [APCSPRODB].material.locations where wh_code = 'QI900');

	UPDATE [APCSPRODB].trans.numbers SET ID = (SELECT MAX(ID) FROM [APCSPRODB].[trans].[material_records])
		where [name] = 'material_records.id';
		
	UPDATE [APCSPRODB].TRANS.MATERIALS SET 
		MATERIAL_STATE = 1, 
		LIMIT_STATE = 5 ,
		LOCATION_ID = (SELECT ID FROM [APCSPRODB].MATERIAL.LOCATIONS WHERE WH_CODE = 'QI999'),
		UPDATED_AT = GETDATE(), --update by อั๋น 2022/03/08
		UPDATED_BY = 1 --update by อั๋น 2022/03/08
		--อั๋น Update Expired เพิ่มเช็ค Col Extended 2020/01-30
		WHERE   ((LIMIT_DATE <= GETDATE() and EXTENDED_LIMIT_DATE IS NULL) OR (LIMIT_DATE <= GETDATE() and EXTENDED_LIMIT_DATE <= GETDATE()))
		--LIMIT_DATE <= GETDATE()
		AND LIMIT_STATE = 0
		AND QUANTITY > 0 --update by อั๋น 2022/03/17
		AND LOCATION_ID IN (SELECT ID FROM [APCSPRODB].MATERIAL.LOCATIONS WHERE WH_CODE = 'QI900');
		
END

--EXEC [trans].[sp_hold_expired_materials]