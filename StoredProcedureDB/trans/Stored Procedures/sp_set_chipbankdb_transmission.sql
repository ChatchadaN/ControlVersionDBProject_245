-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_chipbankdb_transmission]
AS
BEGIN

	SET NOCOUNT ON;

	-- DECLARE @test_loop INT = 0;
	DECLARE @material_id INT;
	DECLARE @day_id INT;
	DECLARE @record_class INT;

	-- Column from CHIPZAIKO_Hist
	DECLARE @seqno CHAR(10), @location_id CHAR(6), @wf_count DECIMAL(4,0), @chipcount DECIMAL(8,0), @remainflag CHAR(1), @preoutflag CHAR(1), @staff_no CHAR(5);
	
	IF CURSOR_STATUS('global', 'ChipHistCursor') >= -1
	BEGIN
		CLOSE ChipHistCursor;
		DEALLOCATE ChipHistCursor;
	END

	DECLARE ChipHistCursor CURSOR FOR
    SELECT [SEQNO], [LOCATION], [WFCOUNT], [CHIPCOUNT], REMAINFLAG, PREOUTFLAG, STAFFNO
	FROM [APCSProDB_lsi_110].[dbo].[CHIPZAIKO_Hist]
	WHERE SENDFLAG = 0;

	OPEN ChipHistCursor;
	FETCH NEXT FROM ChipHistCursor INTO @seqno, @location_id, @wf_count, @chipcount, @remainflag, @preoutflag, @staff_no;

	WHILE @@FETCH_STATUS = 0
    BEGIN

		BEGIN TRANSACTION
        BEGIN TRY
	
			-- Get material id
			SELECT @material_id = material_id FROM APCSProDB_lsi_110.trans.wf_details
			WHERE seq_no = @seqno;

			IF (@preoutflag = '' AND @remainflag = '1')
			BEGIN
				UPDATE APCSProDB_lsi_110.trans.wf_details 
				SET chip_remain = @chipcount, updated_at = GETDATE(), updated_by = @staff_no
				WHERE material_id = @material_id;

				UPDATE APCSProDB_lsi_110.trans.materials
				SET quantity = @wf_count, location_id = 16, updated_at = GETDATE(), updated_by = @staff_no
				WHERE id = @material_id;

				SET @record_class = 80;
			END
			ELSE IF (@preoutflag = '1')
			BEGIN
				UPDATE APCSProDB_lsi_110.trans.materials
				SET location_id = 9, updated_at = GETDATE(), updated_by = @staff_no
				WHERE id = @material_id;

				SET @record_class = 2;
			END

			-- Insert into material records
			SELECT @day_id = [id] FROM [APCSProDB_lsi_110].[trans].[days] WHERE date_value = CAST(GETDATE() AS DATE)

			DECLARE @material_records_id INT;
			EXEC	[trans].[sp_get_number_id]
					@TABLENAME = N'material_records.id',
					@NEWID = @material_records_id OUTPUT

			INSERT INTO APCSProDB_lsi_110.trans.material_records
			SELECT @material_records_id, @day_id, GETDATE(), @staff_no, @record_class,
			id, barcode, material_production_id, step_no, in_quantity, quantity, fail_quantity,pack_count, limit_base_date, contents_record_id, is_production_usage,
			material_state, process_state, qc_state, first_ins_state, final_ins_state, limit_state, limit_date, extended_limit_date, open_limit_date1, open_limit_date2,
			wait_limit_date, location_id, acc_location_id, lot_no, qc_comment_id, qc_memo_id, arrival_material_id, parent_material_id, dest_lot_id, created_at,
			created_by, updated_at, updated_by, null
			FROM [APCSProDB_lsi_110].[trans].[materials]
			WHERE id = @material_id

			-- Update send fleg in CHIPZAIKO
			UPDATE [APCSProDB_lsi_110].[dbo].[CHIPZAIKO_Hist] SET SENDFLAG = 1 WHERE SEQNO = @seqno

			COMMIT;
			-- SET @test_loop = 1;
		END TRY
		BEGIN CATCH
			ROLLBACK;
			-- SET @test_loop = 2;
		END CATCH
		
        -- Read next row
        FETCH NEXT FROM ChipHistCursor INTO @seqno, @location_id, @wf_count, @chipcount, @remainflag, @preoutflag, @staff_no;

    END

    -- Close and Delete Cursor
    CLOSE ChipHistCursor;
    DEALLOCATE ChipHistCursor;

	-- SELECT @test_loop;

END
