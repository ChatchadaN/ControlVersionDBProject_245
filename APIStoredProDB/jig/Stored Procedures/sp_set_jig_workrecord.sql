-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_workrecord]
	-- Add the parameters for the stored procedure here
		  @Package					AS VARCHAR(50)	= NULL 
		, @LOTNO					AS VARCHAR(10)	= NULL 
		, @KanagataName				AS VARCHAR(50)	= NULL 
		, @MCNO						AS VARCHAR(50)	= NULL 
		, @ShotCount				AS INT			= 0 
		, @OPNo						AS VARCHAR(50)	= NULL   
		, @UserID					AS VARCHAR(50)	= NULL 
		, @MCType					AS VARCHAR(50)	= NULL 

		, @TieBarPunchMax			AS INT			= 0
		, @TieBarDieMax				AS INT			= 0
		, @CurvePunchMax			AS INT			= 0
		, @LeadCutPunchMax			AS INT			= 0
		, @GuidePostMax				AS INT			= 0
		, @GuideBushuMax			AS INT			= 0
		, @LeadDieMax				AS INT			= 0   
		, @LeadDieEXMax				AS INT			= 0
	    , @SupportPunchMax			AS INT			= 0
		, @SupportDieMax			AS INT			= 0
		, @FinCutPunchMax			AS INT			= 0
		, @FinCutDieMax				AS INT			= 0
		, @CumMax					AS INT			= 0
		, @DieBlockMax				AS INT			= 0
		, @FlashPunchMax			AS INT			= 0
		, @SubGatePunchMax			AS INT			= 0

		, @TieBarCutPunchMax		AS INT			= 0
		, @TieBarCutDieMax			AS INT			= 0
		, @GateCutDieMax			AS INT			= 0
		, @GateCutPunchMax			AS INT			= 0  
		, @FrameCutDieMax			AS INT			= 0
	    , @FrameCutPunchMax			AS INT			= 0
		, @StripperGuidePunchMax	AS INT			= 0
		, @PilotPinMax				AS INT			= 0
		, @OverHualMax				AS INT			= 0
		, @FinGateCutDieMax			AS INT			= 0
		, @TieBarGuidePunchMax		AS INT			= 0
		, @SupportGuidePunchMax		AS INT			= 0
		 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[jig].[sp_set_jig_workrecord_001]
		   @Package					=  @Package				
		 , @LOTNO					=  @LOTNO				
		 , @KanagataName			=  @KanagataName			
		 , @MCNO					=  @MCNO					
		 , @ShotCount				=  @ShotCount			
		 , @OPNo					=  @OPNo					
		 , @UserID					=  @UserID				
		 , @MCType					=  @MCType				
		 , @TieBarPunchMax			=  @TieBarPunchMax		
		 , @TieBarDieMax			=  @TieBarDieMax			
		 , @CurvePunchMax			=  @CurvePunchMax		
		 , @LeadCutPunchMax			=  @LeadCutPunchMax		
		 , @GuidePostMax			=  @GuidePostMax			
		 , @GuideBushuMax			=  @GuideBushuMax		
		 , @LeadDieMax				=  @LeadDieMax			
		 , @LeadDieEXMax			=  @LeadDieEXMax			
		 , @SupportPunchMax			=  @SupportPunchMax		
		 , @SupportDieMax			=  @SupportDieMax		
		 , @FinCutPunchMax			=  @FinCutPunchMax		
		 , @FinCutDieMax			=  @FinCutDieMax			
		 , @CumMax					=  @CumMax				
		 , @DieBlockMax				=  @DieBlockMax			
		 , @FlashPunchMax			=  @FlashPunchMax		
		 , @SubGatePunchMax			=  @SubGatePunchMax		
		 , @TieBarCutPunchMax		=  @TieBarCutPunchMax	
		 , @TieBarCutDieMax			=  @TieBarCutDieMax		
		 , @GateCutDieMax			=  @GateCutDieMax		
		 , @GateCutPunchMax			=  @GateCutPunchMax		
		 , @FrameCutDieMax			=  @FrameCutDieMax		
		 , @FrameCutPunchMax		=  @FrameCutPunchMax		
		 , @StripperGuidePunchMax	=  @StripperGuidePunchMax
		 , @PilotPinMax				=  @PilotPinMax			
		 , @OverHualMax				=  @OverHualMax			
		 , @FinGateCutDieMax		=  @FinGateCutDieMax		
		 , @TieBarGuidePunchMax		=  @TieBarGuidePunchMax	
		 , @SupportGuidePunchMax	=  @SupportGuidePunchMax	 
END
