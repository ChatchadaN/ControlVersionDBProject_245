-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_rack_flow]
	-- Add the parameters for the stored procedure here
	@LotNo varchar(20), @OPNoId int, @lotStatus varchar(1) = 0, @isCurrentStepNo bit = 0 --False
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	EXEC [dbo].[sp_get_rcs_rack_flow_v3]
		@LotNo				=	@LotNo
		,@OPNoId			=	@OPNoId
		,@lotStatus			=	@lotStatus
		,@isCurrentStepNo	=	@isCurrentStepNo

END