-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_label_issued_tg_V2]
	-- Add the parameters for the stored procedure here
	 @lot_no varchar(10)
	,@qty_hasuu_before INT = 0
	,@Empno_int_value INT = 0
	--add parameter stock class date modify : 2022/03/10 time : 14.55
	,@stock_class char(2) = ''
	,@machine_id_val int = null  --add parameter date modify : 2023/04/14 time : 09.30
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @r int= 0;
	DECLARE @lot_id INT;
	DECLARE @qty_out INT;
	DECLARE @qty_hasuu INT;
	--Add Column in surpluses Date : 2021/09/16 By Aomsin
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

	-- Insert statements for procedure here
	SELECT @lot_id = [lots].[id]
	, @qty_out = (([lots].[qty_pass] + @qty_hasuu_before)/[device_names].[pcs_per_pack])*[device_names].[pcs_per_pack]
	, @qty_hasuu = (([lots].[qty_pass] + @qty_hasuu_before)%[device_names].[pcs_per_pack])
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	WHERE [lots].[lot_no] = @lot_no

	DECLARE @Check_Record_Allocat int = 0
	select @Check_Record_Allocat = COUNT(*) from [APCSProDB].[method].[allocat] where LotNo = @lot_no
	--Add Condition Check Record in table Allocat --> Update 2022/11/17 Time : 13.05
	IF @Check_Record_Allocat <> 0
	BEGIN
		--Add Query Get Data Hasuu By Allocat Date : 2021/09/16
		select  @product_code_value = PDCD
		,@qc_instruction_value = ISNULL(Tomson3,'')
		,@mno_value = MNo
		,@user_code_value = User_Code
		,@product_control_class_value = Product_Control_Cl_1
		,@product_class_value = Product_Class
		,@production_class_value = Production_Class
		,@rank_no_value = Rank_No
		,@hinsyu_class_value = HINSYU_Class
		,@label_class_value = Label_Class
		from APCSProDB.method.allocat
		where LotNo = @lot_no
	END
	ELSE
	BEGIN
		select  @product_code_value = PDCD
		,@qc_instruction_value = ISNULL(Tomson3,'')
		,@mno_value = MNo
		,@user_code_value = User_Code
		,@product_control_class_value = Product_Control_Cl_1
		,@product_class_value = Product_Class
		,@production_class_value = Production_Class
		,@rank_no_value = Rank_No
		,@hinsyu_class_value = HINSYU_Class
		,@label_class_value = Label_Class
		from APCSProDB.method.allocat_temp
		where LotNo = @lot_no
	END

	--LOG FILE TO STORE Create 2020/12/23 end update 2021/12/09 time : 11.46
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
		--check null :2021/12/22 11:20
		,'EXEC [atom].[sp_set_label_issued_tg_V2] @lotno_standard = ''' + @lot_no + ''', @hasuu_qty_before = ''' + CONVERT (varchar (10), @qty_hasuu_before) +  ''', @empno = ''' + CONVERT (varchar (10), @Empno_int_value) + ''',@qc_instruction = ''' + ISNULL(@qc_instruction_value,'') +  ''''
		,@lot_no


	------------------------------------ Start Get EmpId Modify : 2024/12/26 ------------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = NULL

	SELECT  @GetEmpno = FORMAT(CAST(@Empno_int_value AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------------ End Get EmpId Modify : 2024/12/26 -------------------------------------

	IF(@qty_out = 0)
	BEGIN
		IF EXISTS(SELECT * FROM [APCSProDB].[trans].[surpluses] WHERE lot_id = @lot_id)
		BEGIN
			-- UPDATE HASUU WIP 70
			UPDATE [APCSProDB].[trans].[surpluses]
			SET 
				[pcs] = @qty_hasuu
				, [serial_no] = @lot_no
				, [in_stock] = '2'
				, [location_id] = ''
				, [acc_location_id] = ''
				, [updated_at] = GETDATE()
				, [updated_by] = @EmpnoId  --@Empno_int_value  new
				, [pdcd] = @product_code_value
			    , [qc_instruction] = @qc_instruction_value
			    , [mark_no] = @mno_value
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
				  [qty_hasuu] = @qty_hasuu
				, [qty_out] = @qty_out
				, [qty_combined] = @qty_hasuu_before
				--, [wip_state] = '100'
			WHERE [lot_no] = @lot_no
		END
		ELSE
		BEGIN
			-- INSERT HASUU WIP 70
			INSERT INTO [APCSProDB].[trans].[surpluses]
           ([id]
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
		   , [machine_id]
		   , [user_code]
		   , [product_control_class]
		   , [product_class]
		   , [production_class]
		   , [rank_no]
		   , [hinsyu_class]
		   , [label_class]
		   , [stock_class] --date modify : 2022/03/10 time : 14.55
		   )
			--SELECT [nu].[id] - 1 + row_number() over (order by [surpluses].[id]) AS id
			SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
			, @lot_id AS lot_id
			, @qty_hasuu AS pcs
			, @lot_no AS serial_no
			, '2' AS in_stock
			, '' AS location_id
			, '' AS acc_location_id
			, GETDATE() AS created_at
			--, @Empno_int_value AS created_by
			, @EmpnoId AS created_by  --new
			, GETDATE() AS updated_at
			--, @Empno_int_value AS updated_by
			, @EmpnoId AS updated_by  --new
			, @product_code_value
			, @qc_instruction_value
			, @mno_value
			, @machine_id_val  --date modify : 2023/04/14 time : 09.30
			, @user_code_value
			, @product_control_class_value
			, @product_class_value
			, @production_class_value
			, @rank_no_value
			, @hinsyu_class_value
			, @label_class_value
			, @stock_class  --date modify : 2022/03/10 time : 14.55
			FROM [APCSProDB].[trans].[surpluses]
			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'

			UPDATE [APCSProDB].[trans].[lots]
			SET 
				  [qty_hasuu] = @qty_hasuu
				, [qty_out] = @qty_out
				, [qty_combined] = @qty_hasuu_before
				--, [wip_state] = '100'
			WHERE [lot_no] = @lot_no
		END	
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT * FROM [APCSProDB].[trans].[surpluses] WHERE lot_id = @lot_id)
		BEGIN
			-- UPDATE LABEL
			UPDATE [APCSProDB].[trans].[surpluses]
			SET 
				[pcs] = @qty_hasuu
				, [serial_no] = @lot_no
				, [in_stock] = '2'
				, [location_id] = null
				, [acc_location_id] = null
				, [updated_at] = GETDATE()
				, [updated_by] = @EmpnoId --@Empno_int_value  --new
				, [pdcd] = @product_code_value
			    , [qc_instruction] = @qc_instruction_value
			    , [mark_no] = @mno_value
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
				  [qty_hasuu] = @qty_hasuu
				, [qty_out] = @qty_out
				, [qty_combined] = @qty_hasuu_before
				--, [wip_state] = '100'
			WHERE [lot_no] = @lot_no
		END
		ELSE
		BEGIN
			-- INSERT LABEL
			INSERT INTO [APCSProDB].[trans].[surpluses]
           ([id]
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
		   , [machine_id]
		   , [user_code]
		   , [product_control_class]
		   , [product_class]
		   , [production_class]
		   , [rank_no]
		   , [hinsyu_class]
		   , [label_class]
		   , [stock_class] --date modify : 2022/03/10 time : 14.55
		   )
			--SELECT [nu].[id] - 1 + row_number() over (order by [surpluses].[id]) AS id
			SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
			, @lot_id AS lot_id
			, @qty_hasuu AS pcs
			, @lot_no AS serial_no
			, '2' AS in_stock
			, null AS location_id
			, null AS acc_location_id
			, GETDATE() AS created_at
			--, @Empno_int_value AS created_by
			, @EmpnoId AS created_by  --new
			, GETDATE() AS updated_at
			--, @Empno_int_value AS updated_by
			, @EmpnoId AS updated_by  --new
			, @product_code_value
			, @qc_instruction_value
			, @mno_value
			, @machine_id_val   --date modify : 2023/04/14 time : 09.30
			, @user_code_value
			, @product_control_class_value
			, @product_class_value
			, @production_class_value
			, @rank_no_value
			, @hinsyu_class_value
			, @label_class_value
			, @stock_class  --date modify : 2022/03/10 time : 14.55
			FROM [APCSProDB].[trans].[surpluses]
			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'

			UPDATE [APCSProDB].[trans].[lots]
			SET 
				  [qty_hasuu] = @qty_hasuu
				, [qty_out] = @qty_out
				, [qty_combined] = @qty_hasuu_before
				--, [wip_state] = '100'
			WHERE [lot_no] = @lot_no
		END	
	END

	set @r = @@ROWCOUNT
	update [APCSProDB].[trans].[numbers]
	set id = id + @r 
	from [APCSProDB].[trans].[numbers]
	where name = 'surpluses.id'

END
