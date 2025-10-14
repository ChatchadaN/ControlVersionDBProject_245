-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_multichip_get_data_lot]
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
Declare @jobId int
Declare @ProcessId int
--DB1
Declare @Lotno_DB1 varchar(10)
Declare @lot_id_DB1 int
Declare @process_Id_DB1 int
Declare @qty_pass_DB1 int
Declare @Qty_fail_DB1 int
Declare @front_Ng_DB1 int
--DB2
declare @lot_id_DB2 int 
declare @lotNo_DB2 varchar(10)
declare @wipState_DB2 int
declare @processState_DB2 int
Declare @qty_pass_DB2 int
Declare @Qty_fail_DB2 int
Declare @front_Ng_DB2 int

select @ProcessId = act_process_id , @lot_id = id, @jobId = act_job_id,@process_State = process_state from APCSProDB.trans.lots  where lot_no = @LotNo

IF(@ProcessId = 2 )
	BEGIN
		IF (@jobId = 25 or @jobId = 65 or @jobId = 245 or @jobId = 318) -----DB,DB1,DB1(2),DB1(3)
			BEGIN
				SELECT 'TRUE' AS Is_Pass , 0 as qty_pass , 0 as qty_fail, 0 as qty_front_ng ,'DB1' as process_name,@LotNo as lot_no
			END
		ELSE IF (@jobId =67  or @jobId = 247  or @jobId =246  or @jobId =310 or @jobId =415 or @jobId =416) --DB2,DB2(6),DB2(3),DB2(4),DB2(2)
			BEGIN
				SET @lot_id_DB1 = (SELECT [lot_id] as DB1 FROM [APCSProDB].[trans].[lot_multi_chips] where [child_lot_id] = @lot_id)

				Select @process_Id_DB1 = act_process_id ,@qty_pass_DB1 = qty_pass, @Qty_fail_DB1 = qty_fail,@front_Ng_DB1 = qty_front_ng ,@Lotno_DB1 = lot_no
				from APCSProDB.trans.lots where id = @lot_id_DB1

				--เชคข้อมูล ทั้ง 2 เทเบิ้ลมีไหม
				IF(@lot_id_DB1 is null)
					BEGIN
						SELECT 'FALSE' AS Is_Pass ,N'ไม่มีข้อมูล DB1 ใน [lot_multi_chips]'AS Error_Message_THA,'DB2' as process_name
					END
				IF(@process_Id_DB1 is null)
					BEGIN
						SELECT 'FALSE' AS Is_Pass ,N'ไม่มีข้อมูล DB1 ใน [trans.lots]'AS Error_Message_THA,'DB2' as process_name
					END
				IF(@process_Id_DB1 > 2)
					BEGIN
						SELECT 'TRUE' AS Is_Pass, @qty_pass_DB1 as qty_pass , @Qty_fail_DB1 as qty_fail, @front_Ng_DB1 as qty_front_ng ,'DB2' as process_name ,@Lotno_DB1 as lot_no
					END
				ELSE
					BEGIN
						SELECT 'FALSE' AS Is_Pass ,N' กรุณาจบงาน Lot DB1 ก่อน Lot No' + @Lotno_DB1  AS Error_Message_THA,'DB2' as process_name
					END
			END
		ELSE IF (@jobId = 73 or @jobId =248  or @jobId = 309) --DB3,DB3(6)
			BEGIN
				--Lot DB3 หา ID DB1
				SELECT @lot_id_DB1= lot_id FROM APCSProDB.trans.lot_multi_chips AS lot_multi_chips_1 WHERE child_lot_id = @lot_id

				--DB 1 หา ID DB2   ได้ข้อมูล DB2 Tran.lots
				SELECT @lot_id_DB2 = id ,@lotNo_DB2 = lot_no ,@wipState_DB2 = wip_state,@processState_DB2 = process_state,
				@Qty_fail_DB2 = qty_fail,@qty_pass_DB2 = qty_pass ,@front_Ng_DB2 = qty_front_ng
				from  [APCSProDB].trans.lots where id in (select child_lot_id from [APCSProDB].trans.lot_multi_chips where lot_id = @lot_id_DB1) 
				and ([APCSProDB].trans.lots.act_job_id = 67 OR [APCSProDB].trans.lots.act_job_id = 247 OR [APCSProDB].trans.lots.act_job_id = 246 OR [APCSProDB].trans.lots.act_job_id = 310 OR [APCSProDB].trans.lots.act_job_id = 415
				OR [APCSProDB].trans.lots.act_job_id = 416)  --Add DB2(2)
				
				IF(@wipState_DB2 = 101) --  ต้องเป็น สถานะ SHIPED  =  จบ DB2 แล้ว
					BEGIN
						if(@front_Ng_DB2 is null)
						BEGIN
							set @front_Ng_DB2 = 0
						END
						SELECT 'TRUE' AS Is_Pass , @qty_pass_DB2 as qty_pass , @Qty_fail_DB2 as qty_fail, @front_Ng_DB2 as qty_front_ng,'DB3' as process_name ,@lotNo_DB2 as lot_no
					END
				ELSE
					BEGIN
						SELECT 'FALSE' AS Is_Pass ,N'กรุณาจบ Lot DB2 ก่อน' + @lotNo_DB2 AS Error_Message_THA,'DB3' as process_name
					END
			END
	END
ELSE
	BEGIN
		SELECT 'FALSE' AS Is_Pass ,N'ลอตนี้ไม่ใช่ Wip ของโปรเซสนี้'AS Error_Message_THA,'DB1' as process_name
	END
END