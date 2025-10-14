-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_multichip_balance_input_for_setup]
	-- Add the parameters for the stored procedure here
	@lotno_input varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @lotid_input int
declare @jobid_input int
declare @qtypass_input int
declare @rowcount int 
declare @qtyfail_input int

declare @lotno_DB1 varchar(10)
declare @lotid_DB1 int
declare @chipPerIC_DB1 int
declare @qtypass_DB1 int
declare @jobid_DB1 int
declare @processID_DB1 int
declare @qtyfail_DB1 int

declare @lotno_DB2 varchar(10)
declare @lotid_DB2 int
declare @chipPerIC_DB2 int
declare @qtypass_DB2 int
declare @jobid_DB2 int
declare @wipstate_DB2 int

declare @lotno_DB3 varchar(10)
declare @lotid_DB3 int
declare @chipPerIC_DB3 int
declare @qtypass_DB3 int
declare @jobid_DB3 int

declare @qtypass_min int

select @lotid_input = id, @jobid_input = act_job_id, @qtypass_input = qty_pass ,@qtyfail_input = qty_fail from APCSProDB.trans.lots where lot_no = @lotno_input
IF(@jobid_input = 25)
	Begin
		SELECT 'TRUE' as Is_Pass ,@qtypass_input as qty_pass , ''  as Error_Message_THA
		RETURN
	END
ELSE IF(@jobid_input = 65) --DB1
	BEGIN
	    --Support DB 1 New Design       1 pad = 2 chip of DB1     P' Mamu Req    2022/09/23
		IF(@lotno_input = '2238E2012V' or @lotno_input = '2238E2013V' or @lotno_input = '2238E2014V' or @lotno_input = '2238E2015V' or @lotno_input = '2238E2016V')
			BEGIN
				SELECT 'TRUE' as Is_Pass ,@qtypass_input as qty_pass , 'Special Support'  as Error_Message_THA
				RETURN
			END
        ----------------------------------------------------------
		set @lotno_DB1 = @lotno_input
		set @chipPerIC_DB1 = 1 
		set @qtypass_DB1 = @qtypass_input
		set @lotid_DB1 = @lotid_input
		set @jobid_DB1 = @jobid_input
		set @qtyfail_DB1 = @qtyfail_input
	END
ELSE IF (@jobid_input = 245) --DB1(3)
	BEGIN
		set @lotno_DB1 = @lotno_input
		set @chipPerIC_DB1 = 3
		set @qtypass_DB1 = @qtypass_input/@chipPerIC_DB1
		set @lotid_DB1 = @lotid_input
		set @jobid_DB1 = @jobid_input
		set @qtyfail_DB1 = @qtyfail_input
	END
ELSE IF (@jobid_input = 318) --DB1(2)
	BEGIN
		set @lotno_DB1 = @lotno_input
		set @chipPerIC_DB1 = 2
		set @qtypass_DB1 = @qtypass_input/@chipPerIC_DB1
		set @lotid_DB1 = @lotid_input
		set @jobid_DB1 = @jobid_input
		set @qtyfail_DB1 = @qtyfail_input
	END
ELSE
	BEGIN
		SELECT @lotid_DB1 = lot_id from APCSProDB.trans.lot_multi_chips where child_lot_id = @lotid_input
		SELECT @lotno_DB1 = lot_no, @jobid_DB1 = act_job_id, @qtypass_DB1 = qty_pass ,@processID_DB1 = act_process_id ,@qtyfail_DB1 = qty_fail from APCSProDB.trans.lots where id = @lotid_DB1
		IF(@jobid_DB1 = 65) --DB1
			BEGIN
				set @chipPerIC_DB1 = 1 
				set @qtypass_DB1 = @qtypass_DB1
			END
		ELSE IF (@jobid_DB1 = 245) --DB1(3)
			BEGIN
				set @chipPerIC_DB1 = 3
				set @qtypass_DB1 = @qtypass_DB1/@chipPerIC_DB1
			END
		ELSE IF (@jobid_DB1 = 318) --DB1(2)
			BEGIN
				set @chipPerIC_DB1 = 2
				set @qtypass_DB1 = @qtypass_DB1/@chipPerIC_DB1
			END
		ELSE IF (@processID_DB1 >2)
			BEGIN
				--set @qtypass_DB1 = @qtypass_DB1
				set @qtypass_DB1 = @qtypass_DB1 + @qtyfail_DB1   -- Fix bug 24/11/2021
			END
		ELSE
			BEGIN
				SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'DB1 มีเงื่อนไขมากกว่าที่กำหนด กรุณาติดต่อ SYSTEM'  as Error_Message_THA
				RETURN
			END
	END
IF(@lotno_DB1 != '')
	BEGIN
--      2022/05/13 แก้ไขโปรแกรม  
--		select @rowcount = count(*) from APCSProDB.trans.lot_multi_chips where lot_id =   @lotid_DB1 แก้ไขเพราะมีการแบ่ง ลอตแม่เป็นลอตลูก V-Lot ไม่สามารถใช้เงื่อนไขนี้ได้

		SELECT       @rowcount = count(*)
		FROM            APCSProDB.trans.lot_multi_chips INNER JOIN
                         APCSProDB.trans.lots ON APCSProDB.trans.lot_multi_chips.child_lot_id = APCSProDB.trans.lots.id
		WHERE        (APCSProDB.trans.lot_multi_chips.lot_id =  @lotid_DB1) and ( production_category = 0 or production_category = 30 or production_category = 40  or production_category = 50)	


		if(@rowcount = 2) --มีแค่ DB1 DB2 DB3
			BEGIN
				--หา DB2
				SELECT       @lotid_DB2= APCSProDB.trans.lot_multi_chips.child_lot_id,@jobid_DB2= APCSProDB.trans.lots.act_job_id, @qtypass_DB2= APCSProDB.trans.lots.qty_pass,@lotno_DB2 = APCSProDB.trans.lots.lot_no,@wipstate_DB2=wip_state
				FROM            APCSProDB.trans.lot_multi_chips INNER JOIN
										 APCSProDB.trans.lots ON APCSProDB.trans.lot_multi_chips.child_lot_id = APCSProDB.trans.lots.id
				WHERE        (APCSProDB.trans.lot_multi_chips.lot_id = @lotid_DB1) and ((APCSProDB.trans.lots.act_job_id = 67) OR (APCSProDB.trans.lots.act_job_id = 247) OR 
				(APCSProDB.trans.lots.act_job_id = 310) OR (APCSProDB.trans.lots.act_job_id = 246) OR (APCSProDB.trans.lots.act_job_id = 415)or (APCSProDB.trans.lots.act_job_id = 416))

				--หาDB3
				SELECT       @lotid_DB3 = APCSProDB.trans.lot_multi_chips.child_lot_id,@jobid_DB3 = APCSProDB.trans.lots.act_job_id,@qtypass_DB3 = APCSProDB.trans.lots.qty_pass, @lotno_DB3= APCSProDB.trans.lots.lot_no
				FROM            APCSProDB.trans.lot_multi_chips INNER JOIN
										 APCSProDB.trans.lots ON APCSProDB.trans.lot_multi_chips.child_lot_id = APCSProDB.trans.lots.id
				WHERE        (APCSProDB.trans.lot_multi_chips.lot_id = @lotid_DB1) and ((APCSProDB.trans.lots.act_job_id = 73) OR (APCSProDB.trans.lots.act_job_id = 248) OR 
				(APCSProDB.trans.lots.act_job_id = 309))

				IF(@wipstate_DB2 = 101)     --ESEC2100
					BEGIN 
						--SET @qtypass_DB2 = @qtypass_DB2
						SET @qtypass_DB2 = @qtypass_DB1 + @qtyfail_DB1  -- Fix bug 24/11/2021
					END
				ELSE IF(@jobid_DB2 = 67) --DB2
					BEGIN
						SET @qtypass_DB2 = @qtypass_DB2/1
					END
				ELSE IF(@jobid_DB2 = 416) --DB2(2)
					BEGIN
						SET @qtypass_DB2 = @qtypass_DB2/2
					END
				ELSE IF (@jobid_DB2 = 247 or @jobid_DB2 = 310) --DB2(3) --ESEC2100
					BEGIN
						SET @qtypass_DB2 = @qtypass_DB2/3
					END
				ELSE IF (@jobid_DB2 = 246) --DB2(6)   --ESEC2100
					BEGIN 
						SET @qtypass_DB2 = @qtypass_DB2/6
					END
				ELSE IF (@jobid_DB2 = 415) --DB2(4)   --ESEC2100
					BEGIN 
						SET @qtypass_DB2 = @qtypass_DB2/4
					END
				ELSE
					BEGIN
						SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'DB2 มี job id มากกว่าที่กำหนดไว้ กรุณาติดต่อ System'  as Error_Message_THA
						RETURN
					END

				IF(@jobid_DB3 = 73) --DB3
					BEGIN
						SET @qtypass_DB3 = @qtypass_DB3/1
					END
				ELSE IF (@jobid_DB3 = 248 or @jobid_DB3 = 309) --DB3(6)  --ESEC2100
					BEGIN
						SET @qtypass_DB3 = @qtypass_DB3/6
					END
				ELSE
					BEGIN
						SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'DB3 มี job id มากกว่าที่กำหนดไว้ กรุณาติดต่อ System'  as Error_Message_THA
						RETURN
					END
			END
		ELSE if (@rowcount = 1)  --มีแค่ DB1 DB2
			BEGIN
				--หา DB2
				SELECT       @lotid_DB2= APCSProDB.trans.lot_multi_chips.child_lot_id,@jobid_DB2= APCSProDB.trans.lots.act_job_id, @qtypass_DB2= APCSProDB.trans.lots.qty_pass,@lotno_DB2 = APCSProDB.trans.lots.lot_no
				FROM            APCSProDB.trans.lot_multi_chips INNER JOIN
										 APCSProDB.trans.lots ON APCSProDB.trans.lot_multi_chips.child_lot_id = APCSProDB.trans.lots.id
				WHERE        (APCSProDB.trans.lot_multi_chips.lot_id = @lotid_DB1) and ((APCSProDB.trans.lots.act_job_id = 67) OR (APCSProDB.trans.lots.act_job_id = 247) OR 
				(APCSProDB.trans.lots.act_job_id = 310) OR (APCSProDB.trans.lots.act_job_id = 246) or (APCSProDB.trans.lots.act_job_id = 415) or 
				(APCSProDB.trans.lots.act_job_id = 416))  -- ADd DB2(2)

				IF(@jobid_DB2 = 67) --DB2
					BEGIN
						SET @qtypass_DB2 = @qtypass_DB2/1
					END
				ELSE IF(@jobid_DB2 = 416) --DB2(2)
					BEGIN
						SET @qtypass_DB2 = @qtypass_DB2/2
					END
				ELSE IF (@jobid_DB2 = 247 or @jobid_DB2 = 310) --DB2(3) --ESEC2100
					BEGIN
						SET @qtypass_DB2 = @qtypass_DB2/3
					END
				ELSE IF (@jobid_DB2 = 246) --DB2(6)  --ESEC2100
					BEGIN 
						SET @qtypass_DB2 = @qtypass_DB2/6
					END
				ELSE IF (@jobid_DB2 = 415) --DB2(4)  --New
					BEGIN 
						SET @qtypass_DB2 = @qtypass_DB2/4
					END
				ELSE
					BEGIN
						SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'DB2 มี jobid มากกว่าที่กำหนดไว้ กรุณาติดต่อ System'  as Error_Message_THA
						RETURN
					END
			END
		ELSE
			BEGIN
				SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'ลอตนี้มีการผลิตมากกว่า DB3 หรือ Table multi chip มีปัญหา กรุณาติดต่อ SYSTEM'  as Error_Message_THA
				RETURN
			END
	END

if(@lotno_DB1 != '' and @lotno_DB2 != '' and @lotno_DB3 is null)
	BEGIN
		if(@qtypass_DB1 = 0)
			BEGIN
				SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'DB1 จำนวนงาน = 0 LotNo '+ @lotno_DB1+ ' Lot Out'  as Error_Message_THA
				RETURN
			END
		ELSE IF (@qtypass_DB2 = 0)
			BEGIN
				SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'DB2 จำนวนงาน = 0 LotNo '+ @lotno_DB2+ ' Lot Out'  as Error_Message_THA
				RETURN
			END
		ELSE
			BEGIN
				SET @qtypass_min = (SELECT MIN(DATACOUNT) FROM (SELECT @qtypass_DB1 AS DATACOUNT
				UNION ALL
				SELECT @qtypass_DB2 AS DATACOUNT) as B)

				SELECT 'TRUE' as Is_Pass ,@qtypass_min as qty_pass , ''  as Error_Message_THA
			END
	END
ELSE if(@lotno_DB1 != '' and @lotno_DB2 != '' and @lotno_DB3 != '')
	BEGIN
		if(@qtypass_DB1 = 0)
			BEGIN
				SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'DB1 จำนวนงาน = 0 LotNo '+ @lotno_DB1+ ' Lot Out'  as Error_Message_THA
				RETURN
			END
		ELSE IF (@qtypass_DB2 = 0)
			BEGIN
				SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'DB2 จำนวนงาน = 0 LotNo '+ @lotno_DB2+ ' Lot Out'  as Error_Message_THA
				RETURN
			END
		ELSE IF (@qtypass_DB3 = 0)
			BEGIN
				SELECT 'FALSE' as Is_Pass ,0 as qty_pass , N'DB3 จำนวนงาน = 0 LotNo '+ @lotno_DB3+ ' Lot Out'  as Error_Message_THA
				RETURN
			END
		ELSE
			BEGIN
				SET @qtypass_min = (SELECT MIN(DATACOUNT) FROM ((SELECT @qtypass_DB1 AS DATACOUNT
				UNION ALL
				SELECT @qtypass_DB2 AS DATACOUNT)
				UNION ALL SELECT @qtypass_DB3 AS DATACOUNT) as A)

				SELECT 'TRUE' as Is_Pass ,@qtypass_min as qty_pass , ''  as Error_Message_THA
			END
	END
END
