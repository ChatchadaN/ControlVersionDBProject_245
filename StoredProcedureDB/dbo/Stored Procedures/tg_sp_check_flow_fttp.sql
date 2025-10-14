-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_check_flow_fttp]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;

	--Check Flow FT-TP (job_id = 222), FT-TP SBLSYL (job_id = 409), OS+FT-TP (job_id = 401), OS+FT-TP SBLSYL (job_id = 414)
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [dbo].[tg_sp_check_flow_fttp] @lotno = ''' + @lotno + ''''

	
--IF  @lotno not in ('2506D5953V') --update 2025/02/10 time: 11.49 close function by Aomsin   
--BEGIN
 
	DECLARE @job_id INT
		, @record_class INT
		, @lot_id INT
	--DECLARE @lot_id INT

	--Get lot_id in tran.lots
	SELECT @lot_id = id FROM APCSProDB.trans.lots WHERE lot_no = @lotno

	DECLARE @job_flow TABLE (
		job_id INT
		, record_class INT NULL
	)

	INSERT INTO @job_flow

	SELECT TOP 1 job_id
		, record_class
	FROM (
		SELECT lots.id AS lot_id ,dv_flow.step_no, dv_flow.job_id
		FROM APCSProDB.trans.lots 
		INNER JOIN APCSProDB.method.device_flows  AS dv_flow ON lots.device_slip_id = dv_flow.device_slip_id
		WHERE lots.id = @lot_id
		UNION
		SELECT lots.id AS lot_id ,lot_special_flows.step_no, lot_special_flows.job_id 
		FROM APCSProDB.trans.lots 
		INNER JOIN APCSProDB.trans.special_flows ON lots.id = special_flows.lot_id
		INNER JOIN APCSProDB.trans.lot_special_flows ON special_flows.id = lot_special_flows.special_flow_id
		WHERE lots.id = @lot_id
	) AS g1
	OUTER APPLY (
		SELECT TOP 1 lpr.record_class 
		FROM APCSProDB.trans.lot_process_records AS lpr
		WHERE lpr.lot_id = g1.lot_id
			AND lpr.step_no = g1.step_no
			AND lpr.record_class = 2
	) AS g2
	WHERE job_id IN (222,409,401,414)
	ORDER BY step_no DESC  --add condition for check last flow only >> Modify : 2024/06/14 time : 08.11 by Aomsin <<

	---- not have flow
	IF NOT EXISTS (SELECT job_id FROM @job_flow)
	BEGIN
		SELECT 'TRUE' AS Is_Pass
			, 'No FT-TP, FT-TP SBLSYL' AS Error_Message_ENG
			, N'ไม่มี FT-TP, FT-TP SBLSYL' AS Error_Message_THA
			, N'กรุณาติดต่อ System' AS Handling
			, N'1' AS Is_Status
		RETURN;
	END

	---- have flow
	IF EXISTS (SELECT job_id FROM @job_flow WHERE record_class IS NULL)
	BEGIN
		---- not run
		--SELECT 'FALSE' AS Is_Pass
		--	, 'Not yet Run Flow FT-TP or FT-TP SBLSYL' AS Error_Message_ENG
		--	, N'ยังไม่มีการรัน Flow FT-TP, FT-TP SBLSYL' AS Error_Message_THA
		--	, N'กรุณาติดต่อ System' AS Handling
		--	, N'3' AS Is_Status
		--RETURN;
		--By pass #2025/02/11 time : 16.05 by Aomsin
		SELECT 'TRUE' AS Is_Pass
			, 'By pass codition check Have Run FT-TP or FT-TP SBLSYL' AS Error_Message_ENG
			, N'ข้ามการเช็ค Flow FT-TP, FT-TP SBLSYL เนื่องจากยังไม่มีการ Run Test จริงของหน้างาน' AS Error_Message_THA
			, N'กรุณาติดต่อ System Tel.4621' AS Handling
			, N'2' AS Is_Status
		RETURN;
	END
	ELSE
	BEGIN
		---- run
		SELECT 'TRUE' AS Is_Pass
			, 'Have Run FT-TP or FT-TP SBLSYL is Success' AS Error_Message_ENG
			, N'มีการรัน Flow FT-TP, FT-TP SBLSYL แล้ว' AS Error_Message_THA
			, N'กรุณาติดต่อ System' AS Handling
			, N'2' AS Is_Status
		RETURN;
	END
 END

--ELSE 
--	BEGIN
--		---- run
--		SELECT 'TRUE' AS Is_Pass
--			, 'Have Run FT-TP or FT-TP SBLSYL is Success' AS Error_Message_ENG
--			, N'มีการรัน Flow FT-TP, FT-TP SBLSYL แล้ว' AS Error_Message_THA
--			, N'กรุณาติดต่อ System' AS Handling
--			, N'2' AS Is_Status
--		RETURN;
--	END
--END

