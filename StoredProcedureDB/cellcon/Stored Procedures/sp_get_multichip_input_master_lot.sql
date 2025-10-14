-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_multichip_input_master_lot]
	-- Add the parameters for the stored procedure here
	    @inputLot			VARCHAR(10)
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM 
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 
	 DECLARE      @lotId				INT
				, @stepDB1				INT
				, @stepDB2				INT
				, @stepDB3				INT
				, @wipStateDB2			INT
				, @wipStateDB3			INT
				, @countChild			INT
				, @lotno_DB2			VARCHAR(10)
				, @lotno_DB3			VARCHAR(10)
				, @processState_DB1		INT
				, @processState_DB2		INT
				, @processState_DB3		INT


	--SET @inputLot = '2351A6426V' --Single
	--SET @inputLot = '2351A7023V' --DB1
	--SET @inputLot = '2351A7035V' --DB2
	--SET @inputLot = '2401A6194V' --DB1


SET @lotId = (SELECT id FROM  APCSProDB.trans.lots WHERE  lot_no = @inputLot)

--SELECT @lotId

	IF @lotId IS NULL  
	BEGIN 
		SELECT @inputLot as lotno, 'ไม่มีข้อมูลใน Trans lots'    -- ไม่มีข้อมูลใน Trans Lot
		RETURN
	END

	SET @countChild = (SELECT count(*) FROM  APCSProDB.trans.lot_multi_chips WHERE  lot_id = @lotId)

	IF( @countChild = 0)
		BEGIN
			SELECT  @inputLot as lotno,'Single and Lot ลูก ปกติ'  --Single and Lot ลูก
			RETURN
		END

	SELECT @stepDB1= step_no , @processState_DB1 =  process_state   FROM  APCSProDB.trans.lots WHERE  id = @lotId
	if (@stepDB1 = 100 and (@processState_DB1 = 0 or @processState_DB1 = 100))
		BEGIN
			SELECT @inputLot as lotno, 'Lot input'
			RETURN
		END

	IF (@countChild = 1 )  --DB1,DB2
		BEGIN
		--DB2 All job id = 67,247,310,246,415,416
		SELECT  @wipStateDB2 =  wip_state ,@lotno_DB2 = lot_no ,@processState_DB2 = process_state ,@stepDB2 = step_no FROM  APCSProDB.trans.lots WHERE  id in (SELECT child_lot_id FROM  APCSProDB.trans.lot_multi_chips WHERE  lot_id = @lotId) and act_job_id in (67,247,310,246,415,416)
		IF (@stepDB2 = 100 and (@processState_DB2 = 0 or @processState_DB2 = 100 ) and @wipStateDB2 != 101)
		BEGIN 
			SELECT @lotno_DB2 as lotno
			RETURN
		END

		SELECT @inputLot , 'DB1'
	END 
	ELSE IF (@countChild = 2 ) -- DB1,DB2,DB3
	BEGIN

		--DB2 All job id = 67,247,310,246,415,416
		SELECT  @wipStateDB2 =  wip_state ,@lotno_DB2 = lot_no ,@processState_DB2 = process_state ,@stepDB2 = step_no FROM  APCSProDB.trans.lots WHERE  id in (SELECT child_lot_id FROM  APCSProDB.trans.lot_multi_chips WHERE  lot_id = @lotId) and act_job_id in (67,247,310,246,415,416)
		
		IF (@stepDB2 = 100 and (@processState_DB2 = 0 or @processState_DB2 = 100 ) and @wipStateDB2 != 101)
		BEGIN 
			SELECT @lotno_DB2 as lotno ,'DB2'
			RETURN
		END

		--DB3 all job id = 73,309,248
		SELECT  @wipStateDB3 =  wip_state ,@lotno_DB3 = lot_no ,@processState_DB3 = process_state ,@stepDB3 = step_no 
		FROM  APCSProDB.trans.lots 
		WHERE  id in (SELECT child_lot_id FROM  APCSProDB.trans.lot_multi_chips WHERE  lot_id = @lotId) and act_job_id in (73,309,248)
		
		
		IF	(@stepDB3 = 100 and (@processState_DB3 = 0 or @processState_DB3 = 100 ) and @wipStateDB3 != 101)
		BEGIN
			SELECT @lotno_DB3 as lotno,'DB3'
			RETURN
		END

		SELECT @inputLot  as lotno, 'DB1'

	END 
END
