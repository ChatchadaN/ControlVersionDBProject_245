-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_kanagata_endlot_FL_v2] 
	-- Add the parameters for the stored procedure here
		@Package as varchar(50) = NULL ,
		@LOTNO as varchar(10) = NULL,
		@KanagataName as varchar(50) = NULL,
		@MCNO as varchar(50) = NULL,
		@ShotCount as INT = 0,
		@UserID as varchar(50) = NULL,
		@MCType as varchar(50) = NULL,
		@TieBarPunchMax as INT = 0,
		@TieBarDieMax as INT = 0,
		@CurvePunchMax as INT = 0,
		@LeadCutPunchMax as INT = 0,
		@GuidePostMax as INT = 0,
		@GuideBushuMax as INT = 0,
		@LeadDieMax as INT = 0,   
		@LeadDieEXMax as INT = 0,
	    @SupportPunchMax as INT = 0,
		@SupportDieMax as INT = 0,
		@FinCutPunchMax as INT = 0,
		@FinCutDieMax as INT = 0,
		@CumMax as INT = 0,
		@DieBlockMax as INT = 0,
		@FlashPunchMax as INT = 0,
		@SubGatePunchMax as INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @LOT_ID as INT,
			@LOT_Process as INT,
			@JIG_ID as INT,
			@JIG_Record_ID as INT,
			@OPID AS INT

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @UserID)

	SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LOTNO)
	SET @LOT_Process = (SELECT TOP(1) id FROM APCSProDB.trans.lot_process_records WHERE lot_id = @LOT_ID order by id desc)

	SET @JIG_ID = (SELECT jigs.id FROM APCSProDB.trans.jigs INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
				INNER JOIN APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id WHERE qrcodebyuser = @KanagataName AND categories.name = 'Kanagata Base')

	BEGIN TRY
		INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,extend_data,lot_no,record_class,mc_no) 
					values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID,
					(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID),NULL, GETDATE(), @OPID, @UserID,'End Lot',
					CONVERT(XML,(SELECT @Package as Package,@LOTNO as LotNo,@KanagataName as KanagataName,@MCNO as MCNo,@MCType as MCType,
							@ShotCount as ShotCount,@TieBarPunchMax as TieBarPunchMax,
							@TieBarDieMax as TieBarDieMax,
							@CurvePunchMax as CurvePunchMax,
							@LeadCutPunchMax as LeadCutPunchMax,
							@GuidePostMax as GuidePostMax,
							@GuideBushuMax as GuideBushuMax,
							@LeadDieMax as LeadDieMax,   
							@LeadDieEXMax as LeadDieEXMax,
							@SupportPunchMax as SupportPunchMax,
							@SupportDieMax as SupportDieMax,
							@FinCutPunchMax as FinCutPunchMax,
							@FinCutDieMax as FinCutDieMax,
							@CumMax as CumMax,
							@DieBlockMax as DieBlockMax,
							@FlashPunchMax as FlashPunchMax,
							@SubGatePunchMax as SubGatePunchMax FOR XML RAW ('EndLot'),ROOT ('EndLots') ,ELEMENTS XSINIL )),@LOTNO,15,@MCNO)

		SET @JIG_Record_ID = (SELECT TOP(1) id FROM APCSProDB.trans.jig_records WHERE jig_id = @JIG_ID ORDER BY id DESC)
		--Select @JIG_Record_ID

		IF EXISTS (SELECT id FROM APCSProDB.trans.lots where lot_no = @LOTNO) BEGIN
			INSERT INTO APCSProDB.trans.lot_jigs VALUES (@LOT_Process,@JIG_ID,@JIG_Record_ID)
		END

		SELECT 'TRUE' AS Is_Pass
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass,'Function EndLot Error. !!' AS Error_Message_ENG
					,N'การบันทึกการจบ Lot ผิดพลาด !!' AS Error_Message_THA
					,N'กรุณาติดต่อ System' AS Handling
	END CATCH
END
