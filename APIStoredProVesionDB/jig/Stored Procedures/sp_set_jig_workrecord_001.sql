-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_workrecord_001]
	-- Add the parameters for the stored procedure here
		  @Package							AS VARCHAR(50)	= NULL 
		, @LOTNO							AS VARCHAR(10)	= NULL 
		, @KanagataName						AS VARCHAR(50)	= NULL 
		, @MCNO								AS VARCHAR(50)	= NULL 
		, @ShotCount						AS INT			= 0 
		, @OPNo								AS VARCHAR(50)	= NULL  
	 										
		, @UserID							AS VARCHAR(50)	= NULL 
		, @MCType							AS VARCHAR(50)	= NULL 
		, @TieBarPunchMax					AS INT			= 0
		, @TieBarDieMax						AS INT			= 0
		, @CurvePunchMax					AS INT			= 0
		, @LeadCutPunchMax					AS INT			= 0
		, @GuidePostMax						AS INT			= 0
		, @GuideBushuMax					AS INT			= 0
		, @LeadDieMax						AS INT			= 0   
		, @LeadDieEXMax						AS INT			= 0
	    , @SupportPunchMax					AS INT			= 0
		, @SupportDieMax					AS INT			= 0
		, @FinCutPunchMax					AS INT			= 0
		, @FinCutDieMax						AS INT			= 0
		, @CumMax							AS INT			= 0
		, @DieBlockMax						AS INT			= 0
		, @FlashPunchMax					AS INT			= 0
		, @SubGatePunchMax					AS INT			= 0
		--------// MP
		, @UpperMainCavityBlockMax			AS INT			= 0 
		, @UpperCullBlockMax				AS INT			= 0 
		, @UpperCullGateEjectorPinMax		AS INT			= 0 
		, @UpperFrameEjectorPinMax			AS INT			= 0 
		, @UpperPkgEjectorPinMax			AS INT			= 0 
		, @UpperPilotE_PinMax				AS INT			= 0    
		, @UpperResinStopperPieceMax		AS INT			= 0 
		, @LowerMainCavityBlockMax			AS INT			= 0 
		, @LowerPotBlockMax					AS INT			= 0 
		, @LowerCullGateEjectorPinMax		AS INT			= 0 
		, @LowerFrameEjectorPinMax			AS INT			= 0 
		, @LowerPkgEjectorPinMax			AS INT			= 0 
		, @LowerResinStopperPieceMax		AS INT			= 0 
		, @LowerRoundPilotPinMax			AS INT			= 0 
		, @LowerDia_CutPilotPinMax			AS INT			= 0
		--TC
		, @TieBarCutPunchMax				AS INT			= 0
		, @TieBarCutDieMax					AS INT			= 0
		, @GateCutDieMax					AS INT			= 0
		, @GateCutPunchMax					AS INT			= 0  
		, @FrameCutDieMax					AS INT			= 0
	    , @FrameCutPunchMax					AS INT			= 0
		, @StripperGuidePunchMax			AS INT			= 0
		, @PilotPinMax						AS INT			= 0
		, @OverHualMax						AS INT			= 0
		, @FinGateCutDieMax					AS INT			= 0
		, @TieBarGuidePunchMax				AS INT			= 0
		, @SupportGuidePunchMax				AS INT			= 0
		 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	 
	SET NOCOUNT ON;
	 
	-- Insert statements for procedure here
	DECLARE   @LOT_ID					AS INT
			, @LOT_Process				AS INT
			, @JIG_ID					AS INT
			, @JIG_Record_ID			AS INT
			, @OPID						AS INT 
			, @Process_Name				AS NVARCHAR(20) 
 
	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
 

		SELECT	TOP 1	  @JIG_ID				= jigs.id 
						, @JIG_Record_ID		= jig_records.id  
						, @Process_Name			=  processes.[name]
		FROM APCSProDB.trans.jigs 
		INNER JOIN APCSProDB.jig.productions 
		ON jigs.jig_production_id = productions.id 
		INNER JOIN APCSProDB.jig.categories 
		ON productions.category_id = categories.id 
		LEFT JOIN APCSProDB.method.processes
		ON processes.id  = categories.lsi_process_id
		INNER JOIN APCSProDB.trans.jig_records
		ON  jigs.id   = jig_records.jig_id
		WHERE qrcodebyuser = @KanagataName 
		AND categories.name = 'Kanagata Base'
		AND record_class =  15
		ORDER BY jig_records.record_at DESC
 

 IF (@Process_Name = 'MP')
 BEGIN 
		BEGIN TRY

				UPDATE APCSProDB.trans.jig_records 
				SET  extend_data = 	 (SELECT CONVERT(XML,(SELECT @Package as Package,@LOTNO as LotNo,@KanagataName as KanagataName,@MCNO as MCNo,@MCType as MCType,
										@ShotCount as ShotCount,
										@UpperMainCavityBlockMax as UpperMainCavityBlockMax,
										@UpperCullBlockMax as UpperCullBlockMax,
										@UpperCullGateEjectorPinMax as UpperCullGateEjectorPinMax,
										@UpperFrameEjectorPinMax as UpperFrameEjectorPinMax,
										@UpperPkgEjectorPinMax as UpperPkgEjectorPinMax,
										@UpperPilotE_PinMax as UpperPilotE_PinMax,
										@UpperResinStopperPieceMax as UpperResinStopperPieceMax,
										@LowerMainCavityBlockMax as LowerMainCavityBlockMax,
										@LowerPotBlockMax as LowerPotBlockMax,
										@LowerCullGateEjectorPinMax as LowerCullGateEjectorPinMax,
										@LowerFrameEjectorPinMax as LowerFrameEjectorPinMax, 
										@LowerPkgEjectorPinMax as LowerPkgEjectorPinMax,
										@LowerResinStopperPieceMax as LowerResinStopperPieceMax,
										@LowerRoundPilotPinMax as LowerRoundPilotPinMax,
										@LowerDia_CutPilotPinMax as LowerDia_CutPilotPinMax
										FOR XML RAW ('EndLot'),ROOT ('EndLots') ,ELEMENTS XSINIL )))
					, updated_at = GETDATE()
					, updated_by =  @OPID 
					WHERE id  =  @JIG_Record_ID
			 
							 

				SELECT		  'TRUE'					AS Is_Pass 
							, 'Success !!'				AS Error_Message_ENG
							, N'บันทึกข้อมูลเรียบร้อย !!'		AS Error_Message_THA
							, ''						AS Handling

				RETURN
						 
	END TRY
	BEGIN CATCH

			SELECT    'FALSE'							AS Is_Pass
					,'Function EndLot Error. !!'		AS Error_Message_ENG
					, N'การบันทึกการจบ Lot ผิดพลาด !!'		AS Error_Message_THA
					, N'กรุณาติดต่อ System'				AS Handling
	END CATCH

 END
 ELSE IF (@Process_Name = 'TC')
  BEGIN  

	BEGIN TRY

					UPDATE APCSProDB.trans.jig_records 
					SET  extend_data = 	 (SELECT  CONVERT(XML,(SELECT @Package as Package,@LOTNO as LotNo,@KanagataName as KanagataName,@MCNO as MCNo,@MCType as MCType,
							@ShotCount as ShotCount,
							@TieBarCutPunchMax as TieBarCutPunchMax,
							@TieBarCutDieMax as TieBarCutDieMax,
							@SupportDieMax as SupportDieMax,
							@SupportPunchMax as SupportPunchMax,
							@GateCutDieMax as GateCutDieMax,
							@GateCutPunchMax as GateCutPunchMax,
							@FrameCutDieMax as FrameCutDieMax,
							@FrameCutPunchMax as FrameCutPunchMax,
							@SubGatePunchMax as SubGatePunchMax,
							@StripperGuidePunchMax as StripperGuidePunchMax,
							@FlashPunchMax as FlashPunchMax, 
							@PilotPinMax as PilotPinMax,
							@OverHualMax as OverHualMax,
							@FinGateCutDieMax as FinGateCutDieMax,
							@FinCutPunchMax as FinCutPunchMax,
							@TieBarGuidePunchMax as TieBarGuidePunchMax,
							@SupportGuidePunchMax as SupportGuidePunchMax,
							@DieBlockMax as DieBlockMax 
							FOR XML RAW ('EndLot'),ROOT ('EndLots') ,ELEMENTS XSINIL ))
												)
					, updated_at = GETDATE()
					, updated_by =  @OPID 
					WHERE id  =  @JIG_Record_ID

					SELECT		  'TRUE'					AS Is_Pass 
								, 'Success !!'				AS Error_Message_ENG
								, N'บันทึกข้อมูลเรียบร้อย !!'		AS Error_Message_THA
								, ''						AS Handling
					RETURN
						 
	END TRY
	BEGIN CATCH

					SELECT    'FALSE'							AS Is_Pass
							,'Function EndLot Error. !!'		AS Error_Message_ENG
							, N'การบันทึกการจบ Lot ผิดพลาด !!'		AS Error_Message_THA
							, N'กรุณาติดต่อ System'				AS Handling

					RETURN
	END CATCH

END  

 BEGIN  

	BEGIN TRY

					UPDATE APCSProDB.trans.jig_records 
					SET  extend_data = 	 (SELECT  CONVERT(XML,(SELECT @Package as Package,@LOTNO as LotNo,@KanagataName as KanagataName,@MCNO as MCNo,@MCType as MCType,
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
												@SubGatePunchMax as SubGatePunchMax FOR XML RAW ('EndLot'),ROOT ('EndLots') ,ELEMENTS XSINIL ))
												)
					, updated_at = GETDATE()
					, updated_by =  @OPID 
					WHERE id  =  @JIG_Record_ID

					SELECT		  'TRUE'					AS Is_Pass 
								, 'Success !!'				AS Error_Message_ENG
								, N'บันทึกข้อมูลเรียบร้อย !!'		AS Error_Message_THA
								, ''						AS Handling
					RETURN
						 
	END TRY
	BEGIN CATCH

					SELECT    'FALSE'							AS Is_Pass
							,'Function EndLot Error. !!'		AS Error_Message_ENG
							, N'การบันทึกการจบ Lot ผิดพลาด !!'		AS Error_Message_THA
							, N'กรุณาติดต่อ System'				AS Handling

					RETURN
	END CATCH

END  

END
