-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_lot_process_records]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
	,@emp_no varchar(6) = ''
	,@state int = 0  --1 = Combine , 2 = Cancel Fix code
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @update_by int = 0; --empno_id
	DECLARE @record_class tinyint = 0;
	DECLARE @r int = 0;
	DECLARE @lot_id int = 0;

	select @lot_id = id from APCSProDB.trans.lots where lot_no = @lotno
	select @update_by = id from APCSProDB.man.users where emp_num = @emp_no

	IF @state = 1
		BEGIN
			select @record_class = 46 --surpluses combine
		END
	ELSE IF @state = 2
		BEGIN
			select @record_class = 47 --cancel combine
		END

    -- Insert statements for procedure here
	IF @lotno != ''
	BEGIN
		INSERT INTO [APCSProDB].[trans].[lot_process_records]([id]
		  ,[day_id]
		  ,[recorded_at]
		  ,[operated_by]
		  ,[record_class]
		  ,[lot_id]
		  ,[process_id]
		  ,[job_id]
		  ,[step_no]
		  ,[qty_in]
		  ,[qty_pass]
		  ,[qty_fail]
		  ,[qty_last_pass]
		  ,[qty_last_fail]
		  ,[qty_pass_step_sum]
		  ,[qty_fail_step_sum]
		  ,[qty_divided]
		  ,[qty_hasuu]
		  ,[qty_out]
		  ,[recipe]
		  ,[recipe_version]
		  ,[machine_id]
		  ,[position_id]
		  ,[process_job_id]
		  ,[is_onlined]
		  ,[dbx_id]
		  ,[wip_state]
		  ,[process_state]
		  ,[quality_state]
		  ,[first_ins_state]
		  ,[final_ins_state]
		  ,[is_special_flow]
		  ,[special_flow_id]
		  ,[is_temp_devided]
		  ,[temp_devided_count]
		  ,[container_no]
		  ,[extend_data]
		  ,[std_time_sum]
		  ,[pass_plan_time]
		  ,[pass_plan_time_up]
		  ,[origin_material_id]
		  ,[treatment_time]
		  ,[wait_time]
		  ,[qc_comment_id]
		  ,[qc_memo_id]
		  ,[created_at]
		  ,[created_by]
		  ,[updated_at]
		  ,[updated_by])
		  SELECT [nu].[id] - 1 + row_number() over (order by [lots].[id])
		  , [days].[id] [day_id]
		  , GETDATE() as [recorded_at]
		  , @update_by as [updated_by]
		  , @record_class as [record_class]
		  , [lots].[id] as [lot_id]
		  , [act_process_id] as [process_id]
		  , [act_job_id] as [job_id]
		  , [step_no]
		  , [qty_in]
		  , [qty_pass]
		  , [qty_fail]
		  , [qty_last_pass]
		  , [qty_last_fail]
		  , [qty_pass_step_sum]
		  , [qty_fail_step_sum]
		  , [qty_divided]
		  , [qty_hasuu]
		  , [qty_out]
		  , NULL as [recipe]
		  , 1 as [recipe_version]
		  , [machine_id]
		  , NULL as [position_id]
		  , [process_job_id]
		  , 0 as [is_onlined]
		  , 0 as [dbx_id]
		  , [wip_state]
		  , [process_state]
		  , [quality_state]
		  , [first_ins_state]
		  , [final_ins_state]
		  , [is_special_flow]
		  , [special_flow_id]
		  , [is_temp_devided]
		  , [temp_devided_count]
		  , [container_no]
		  , NULL as [extend_data]
		  , [std_time_sum]
		  , [pass_plan_time]
		  , [pass_plan_time_up]
		  , [origin_material_id]
		  , NULL as [treatment_time]
		  , NULL as [wait_time]
		  , [qc_comment_id]
		  , [qc_memo_id]
		  , [created_at]
		  , [created_by]
		  , GETDATE() as [updated_at]
		  , @update_by as [updated_by]
		  FROM [APCSProDB].[trans].[lots] 
		  INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
		  INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
		  WHERE [lots].[id] = @lot_id

		  SET @r = @@ROWCOUNT
		  UPDATE [APCSProDB].[trans].[numbers]
		  SET [id] = [id] + @r
		  WHERE [name] = 'lot_process_records.id'

	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'Lotno Blank !!' AS Error_Message_ENG,N'ไม่มีข้อมูลของ lotno !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

END
