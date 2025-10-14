-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_multichip_lotchecking]
	-- Add the parameters for the stored procedure here
	@LotNo varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Declare @process_State int
	Declare @lot_id int
	Declare @processCheck int
	Declare @jobId int
	Declare @ProcessId int
	Declare @lot_id_DB1 int

	select @ProcessId = act_process_id , @lot_id = id, @jobId = act_job_id,@process_State = process_state from APCSProDB.trans.lots  where lot_no = @LotNo
	IF(@ProcessId = 2)   --Process Id  2  == DB Process
		BEGIN
			IF (@jobId = 25 or @jobId = 65 or @jobId = 245 or @jobId = 318) -----DB,DB1,DB1(2),DB1(3)
				BEGIN
					Select 'TRUE' AS Is_Pass ,
					N'JobId = ' + str( @jobId) as Error_Message_THA ,
					'' AS Error_Message_ENG , 
					'' AS Handling
				END
			ELSE IF (@jobId =67  or @jobId = 247  or @jobId =246  or @jobId =310 or @jobId = 415 or @jobId = 416 ) --DB2,DB2(6),DB2(3),DB2(4),DB2(2)
				BEGIN

					Declare @processId_DB1 int
					Declare @processState_DB1 int
					Declare @LotNo_DB1 varchar(10)
					SET @lot_id_DB1 = (SELECT [lot_id] as DB1 FROM [APCSProDB].[trans].[lot_multi_chips] where [child_lot_id] = @lot_id)
					IF(@lot_id_DB1 = null) -- ไม่พบ DB1
						BEGIN
							SELECT 'FALSE' AS Is_Pass ,
							N'Lot นี้ DB2 ไม่สามารถจับคู่ได้เนื่องจาก ไม่มีข้อมูล Lot DB1 ในระบบ กรุณาติดต่อ System' as Error_Message_THA,
							'' as Error_Message_ENG ,
							'' as Handling
						END
					ELSE
						select @LotNo_DB1= lot_no, @processId_DB1= act_process_id,@processState_DB1 = process_state from APCSProDB.trans.lots where id = @lot_id_DB1
						IF(@processId_DB1 = 2 ) -- เครื่อง ASM ต้อง DB1 ต้องไม่ใช่ WIP
							BEGIN
							IF(@processState_DB1 != 0 ) --ต้อง Input DB1 ก่อน Input DB2
								BEGIN
									SELECT 'TRUE' AS Is_Pass,
									N'ASM สามารถใช้งานได้' AS Error_Message_THA, 
									'' as Error_Message_ENG ,
									'' AS Handling
								End
							ELSE
								BEGIN
									SELECT 'FALSE'AS Is_Pass,
									N'กรุณา Input LotNo'+ @LotNo_DB1  +N' DB1 ก่อนที่จะInput LotNo'+ @LotNo + ' DB2' AS Error_Message_THA,
									'' AS Error_Message_ENG ,
									'' AS Handling
								END
							END
						ELSE iF (@processId_DB1 > 2 ) -- กรณีเครื่อง ESEC2100 ต้องจบ DB1(Next Process) ก่อน ถึงจะรัน DB2 ได้
							BEGIN
								IF(@process_State = 0 or @process_State = 100)
									BEGIN
										SELECT 'TRUE' AS Is_Pass,
										N'ESEC สามารถรันได้'  AS Error_Message_THA,
										'' AS Error_Message_ENG,
										'' AS Handling
									END
								ELSE
									BEGIN
										SELECT 'FALSE'AS Is_Pass,
										N'ESEC LotNo' + @LotNo+ N' นี้ไม่ได้อยู่ใน สถานะ WIP ไม่สามารถInputได้กรุณาตรวจสอบ' AS Error_Message_THA,
										'' as Error_Message_ENG,
										'' AS Handling	
									END
							END
						ELSE
							BEGIN
								SELECT 'FALSE' AS Is_Pass,
								N'LotNo '+ @LotNo_DB1 +N' DB1 ต้องอยู่ในโปรเซส DB หรือ โปรเซสถัดจาก DB' AS Error_Message_THA,
								'' as Error_Message_ENG,
								'' AS Handling
							END
				END
			ELSE IF (@jobId = 73 or @jobId =248  or @jobId = 309) --DB3,DB3(6)
				BEGIN

					declare @lot_id_DB2 int 
					declare @lotNo_DB2 varchar(10)
					declare @wipState_DB2 int
					declare @processState_DB2 int
					--Lot DB3 หา ID DB1
					SELECT @lot_id_DB1= lot_id FROM APCSProDB.trans.lot_multi_chips AS lot_multi_chips_1 WHERE child_lot_id = @lot_id
					--DB 1 หา ID DB2
					SELECT @lot_id_DB2 = id ,@lotNo_DB2 = lot_no ,@wipState_DB2 = wip_state,@processState_DB2 = process_state from  [APCSProDB].trans.lots where id in (select child_lot_id from [APCSProDB].trans.lot_multi_chips where lot_id = @lot_id_DB1) 
					and ([APCSProDB].trans.lots.act_job_id = 67 OR [APCSProDB].trans.lots.act_job_id = 247 OR [APCSProDB].trans.lots.act_job_id = 246 OR [APCSProDB].trans.lots.act_job_id = 310 OR [APCSProDB].trans.lots.act_job_id = 415  OR [APCSProDB].trans.lots.act_job_id = 416) -- Add DB2(4) 415 DB2(2) 416

					IF(@wipState_DB2 = 101) -- ESEC ต้องเป็น สถานะ SHIPED 
						BEGIN
							SELECT 'TRUE' AS Is_Pass ,N'DB2 Shiped แล้ว ESEC รันได้'AS Error_Message_THA,'' AS Error_Message_ENG,'' AS Handling
						END
					ELSE IF (@wipState_DB2 = 20 and @processState_DB2 != 0)  -- ASM งานจะรันพร้อมกัน จะไม่เป็น SHIPED แต่ Process ต้องไม่ใช่ WIP
						BEGIN
							SELECT 'TRUE' AS Is_Pass,N'DB 2 ไม่ใช่ Wip ASM สามารถรันได้'AS Error_Message_THA,'' AS Error_Message_ENG,'' AS Handling
						END
					ELSE IF (@wipState_DB2 = 20 and @processState_DB2 = 0)  -- ASM งานจะรันพร้อมกัน จะไม่เป็น SHIPED แต่ Process ต้องไม่ใช่ WIP
						BEGIN
							SELECT 'FALSE' AS Is_Pass,N'กรุณา Input Lot DB2 ' + @lotNo_DB2 AS Error_Message_THA ,'' AS Error_Message_ENG,'' AS Handling
						END
					ELSE IF (@lot_id_DB2 is NULL)
						BEGIN
							SELECT 'FALSE'AS Is_Pass,N'DB2 ไม่มีข้อมูลในระบบ หรือ DB2 อยู่ Previous process กรุณาตรวจสอบ DB2' AS Error_Message_THA,'' AS Error_Message_ENG,'' AS Handling
						END
					ELSE
						BEGIN
							SELECT 'FALSE'AS Is_Pass,N'เนื่องจาก DB2 ข้อมูลไม่ถูกต้อง กรุณาติดต่อ System' AS Error_Message_THA,'' AS Error_Message_ENG,'' AS Handling
						END
				END
			ELSE
				BEGIN
					SELECT 'FALSE'AS Is_Pass,N'LotNo ' +@LotNo + N' ไม่ใช่ DB1,DB2,DB3 กรุณาติดต่อ System'  AS Error_Message_THA,'' AS Error_Message_ENG,'' AS Handling
				END
		END
	ELSE IF (@ProcessId  is null)
		BEGIN
			SELECT 'FALSE'AS Is_Pass,'LotNo:'+ @LotNo +N' ไม่มี ข้อมูล' AS Error_Message_THA,'' AS Error_Message_ENG,'' AS Handling
		END
	ELSE
		BEGIN
			SELECT 'TRUE'AS Is_Pass,'Process ID ='+ str( @processId) + N' งานปกติ' AS Error_Message_THA,'' AS Error_Message_ENG,'' AS Handling
		END
	END
