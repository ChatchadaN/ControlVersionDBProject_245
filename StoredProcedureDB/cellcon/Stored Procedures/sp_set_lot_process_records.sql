-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_lot_process_records]--ชื่อ
	-- Add the parameters for the stored procedure here
	@lot_id as int ,@p_nashi as int,@good as int, @ngadjust as int,@frontng as int, @marker as int,@cut_frame as int,  @lot_no as varchar(10), @job_id as int
	, @t_frontng as int, @t_marker as int, @t_p_nashi as int, @t_good as int, @t_ng as int, @specialFlow_id as int = 0 --สร้างตัวแปลที่ต้องการเรียกและกำหนดตัวแปล
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [cellcon].[sp_set_lot_process_records] @p_nashi = '''+ CAST(@p_nashi AS varchar) +  ''', @frontng = ''' + CAST(@frontng AS varchar)
		 + ''', @marker = '''  + CAST(@marker AS varchar) + ''', @ngadjust = ''' + CAST(@ngadjust AS varchar) + ''', @lot_no = ''' + CAST(@lot_no AS varchar) + ''', @job_id = ''' + CAST(@job_id AS varchar)  + ''''
		
	--DECLARE @TmpTable TABLE (lot_id INT)

	UPDATE TOP(1) APCSProDB.trans.lots
	SET qty_p_nashi = @t_p_nashi,
	qty_pass = @t_good,
	--qty_last_pass = @t_good,
	--qty_pass_step_sum = @t_good,
	qty_fail = @t_ng,
	--qty_last_fail = @t_ng,
	--qty_fail_step_sum = @t_ng,
	qty_front_ng = @t_frontng,
	qty_marker = @t_marker,
	qty_cut_frame = @cut_frame
	where lot_no = @lot_no
	--OUTPUT Inserted.id INTO @TmpTable


	--SELECT @lot_id = lot_id from @TmpTable

	--SELECT top(1000) * from APCSProDB.trans.lot_process_records
	--where lot_id = @lot_id and job_id = @job_id and record_class = '2' 
	--and id = (select MAX(id) from APCSProDB.trans.lot_process_records where lot_id = @lot_id and job_id = @job_id and record_class = '2')


	UPDATE TOP(1) APCSProDB.trans.lot_process_records
	SET  qty_p_nashi = @p_nashi,
	 --qty_last_pass=@good,
	 qty_pass_step_sum = @good,
	 --qty_last_fail = @ngadjust,
	 qty_fail_step_sum = @ngadjust,
	 qty_front_ng = @frontng,
	 qty_marker = @marker,
	 qty_cut_frame = @cut_frame
	where lot_id = @lot_id and job_id = @job_id and record_class = '2' 
	and id = (select MAX(id) from APCSProDB.trans.lot_process_records where lot_id = @lot_id and job_id = @job_id and record_class = '2')
	
	if (@specialFlow_id > 0)
	BEGIN
		UPDATE TOP(1) APCSProDB.trans.special_flows
		SET qty_fail = 0
		where APCSProDB.trans.special_flows.id = @specialFlow_id
	END

	 if	(@@ROWCOUNT > 0)
	 BEGIN	
		SELECT 'TRUE' AS Is_Pass
	 END
	 else 
	 BEGIN
	     SELECT 'FALSE' AS Is_Pass ,'UPDATE DATA FAIL' AS Error_Message_ENG,N'ไม่สามารถอัพเดทข้อมูลได้' AS Error_Message_THA,N'กรุณาติดต่อ system 83114' AS Handling
	 END
	--SELECT 'FALSE' AS Is_Pass,'Capillary recipe is invalid !!' AS Error_Message_ENG,N'Capillary recipe ไม่ถูกต้อง !!' AS Error_Message_THA,N'กรุณาตรวจสอบ Capillary recipe ที่เว็บไซต์ JIG' AS Handling
END
