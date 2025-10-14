-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20220318>
-- Description:	<Description,,For data lot recall save to surpluses table>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_recall_surpluses]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
	,@lot_no_master varchar(10)
	,@Empno_int_value INT = 0
	,@qty_hasuu_brfore INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @r int= 0;
	DECLARE @lot_id INT;
	DECLARE @qty_out INT;
	DECLARE @qty_hasuu INT;
	DECLARE @lotno_type char(1);
	DECLARE @qty_out_type_d_lot INT;
	DECLARE @PDCD char(5);
	DECLARE @Tomson3 char(4);
	DECLARE @MaskNo char(10);
	DECLARE @product_code_value varchar(5)
	DECLARE @qc_instruction_value char(20)
	DECLARE @mno_value char(20)
	DECLARE @user_code_value char(4)
	DECLARE @product_control_class_value char(3)
	DECLARE @product_class_value char(1)
	DECLARE @production_class_value char(1)
	DECLARE @rank_no_value char(6)
	DECLARE @hinsyu_class_value char(1)
	DECLARE @label_class_value char(1)
	DECLARE @stock_class char(2) = ''

    -- Insert statements for procedure here

	SELECT @lot_id = [lots].[id]
		, @qty_out = case when [lots].[qty_out] != 0 then [lots].[qty_out] else 
			(([lots].[qty_pass] + @qty_hasuu_brfore)/[device_names].[pcs_per_pack])*[device_names].[pcs_per_pack] end
		, @qty_out_type_d_lot = case when [lots].[qty_out] != 0 then [lots].[qty_out] else
			(([lots].[qty_pass])/[device_names].[pcs_per_pack])*[device_names].[pcs_per_pack] end
		, @qty_hasuu = ([lots].[qty_pass] + @qty_hasuu_brfore)%[device_names].[pcs_per_pack]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
		WHERE [lots].[lot_no] = @lot_no

	-- Set value it's same lot master
	select @PDCD = den_pyo.PROCESS_POST_CODE
		, @Tomson3 = den_pyo.TOMSON_INDICATION 
		, @MaskNo = den_pyo.MNO1 
		from APCSProDB.trans.lots
		LEFT JOIN APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lots.lot_no = den_pyo.LOT_NO_2
		WHERE [lots].[lot_no] = @lot_no_master

	select @lotno_type = SUBSTRING(@lot_no,5,1)

	-- LOG FILE TO STORE
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text]
	  , [lot_no])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [atom].[sp_set_recall_surpluses] @lotno_standard = ''' + @lot_no + ''', @hasuu_qty_before = ''' + CONVERT (varchar (10), @qty_hasuu_brfore) +  ''', @empno = ''' + CONVERT (varchar (10), @Empno_int_value) + ''',@qc_instruction = ''' + case when @qc_instruction_value is null then '' else @qc_instruction_value end + ''''
		,@lot_no

	IF EXISTS(SELECT * FROM [APCSProDB].[trans].[surpluses] WHERE lot_id = @lot_id)
	BEGIN
		UPDATE [APCSProDB].[trans].[surpluses]
		SET 
			  [pcs] = case when @lotno_type = 'D' then @qty_hasuu_brfore else @qty_hasuu end
			, [serial_no] = @lot_no
			, [in_stock] = '2'
			, [location_id] = ''
			, [acc_location_id] = ''
			, [updated_at] = GETDATE()
			, [updated_by] = @Empno_int_value
			, [pdcd] = @PDCD
		    --, [qc_instruction] = @qc_instruction_value
			, [qc_instruction] = @Tomson3
		    , [mark_no] = case when @lotno_type = 'D' or @lotno_type = 'F' then 'MX' else @MaskNo end
		    , [user_code] = @user_code_value
		    , [product_control_class] = @product_control_class_value
		    , [product_class] = @product_class_value
		    , [production_class] = @production_class_value
		    , [rank_no] = @rank_no_value
		    , [hinsyu_class] = @hinsyu_class_value
		    , [label_class] = @label_class_value
		WHERE [lot_id] = @lot_id

		UPDATE [APCSProDB].[trans].[lots]
		SET 
			  [qty_hasuu] = case when @lotno_type = 'D' then @qty_hasuu_brfore else @qty_hasuu end
			, [qty_out] = case when @lotno_type = 'D' then @qty_out_type_d_lot else @qty_out end
			, [qty_combined] = case when @lotno_type = 'D' then 0 else @qty_hasuu_brfore end
			--, [wip_state] = '100'
		WHERE [lot_no] = @lot_no
	END
	ELSE
	BEGIN
		-- INSERT LABEL
		INSERT INTO [APCSProDB].[trans].[surpluses]
		( [id]
		, [lot_id]
		, [pcs]
		, [serial_no]
		, [in_stock]
		, [location_id]
		, [acc_location_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
		, [pdcd]
		, [qc_instruction]
		, [mark_no]
		, [user_code]
		, [product_control_class]
		, [product_class]
		, [production_class]
		, [rank_no]
		, [hinsyu_class]
		, [label_class]
		, [stock_class]
		)
		--SELECT [nu].[id] - 1 + row_number() over (order by [surpluses].[id]) AS id
		SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
		, @lot_id AS lot_id
		, case when @lotno_type = 'D' then @qty_hasuu_brfore else @qty_hasuu end AS pcs
		, @lot_no AS serial_no
		, '2' AS in_stock
		, '' AS location_id
		, '' AS acc_location_id
		, GETDATE() AS created_at
		, @Empno_int_value AS created_by
		, GETDATE() AS updated_at
		, @Empno_int_value AS updated_by
		--, @product_code_value
		,@PDCD
		, @Tomson3
		, case when @lotno_type = 'D' or @lotno_type = 'F' then 'MX' else @MaskNo end
		, @user_code_value
		, @product_control_class_value
		, @product_class_value
		, @production_class_value
		, @rank_no_value
		, @hinsyu_class_value
		, @label_class_value
		, @stock_class
		FROM [APCSProDB].[trans].[surpluses]
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'

		UPDATE [APCSProDB].[trans].[lots]
		SET 
			  [qty_hasuu] = case when @lotno_type = 'D' then @qty_hasuu_brfore else @qty_hasuu end
			, [qty_out] = case when @lotno_type = 'D' then @qty_out_type_d_lot else @qty_out end
			, [qty_combined] = case when @lotno_type = 'D' then 0 else @qty_hasuu_brfore end
			--, [wip_state] = '100'
		WHERE [lot_no] = @lot_no
	END
	
	set @r = @@ROWCOUNT
	update [APCSProDB].[trans].[numbers]
	set id = id + @r 
	from [APCSProDB].[trans].[numbers]
	where name = 'surpluses.id'

END
