
-- =============================================
-- Author:		NUCHA
-- Create date: 2022/07/01
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_chipbank_orderwf_remain]

		@WFDATE DATE 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	-- ########## VERSION 001 ##########  
		EXEC [APIStoredProVersionDB].[material].sp_get_chipbank_orderwf_remain_001
			@WFDATE		 = 	 @WFDATE		
	-- ########## VERSION 001 ##########

END
