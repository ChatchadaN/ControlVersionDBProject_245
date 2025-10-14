-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_quality_state]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) = ''
	, @quality_state int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [APCSProDB].[trans].[lots]
		SET [quality_state] = @quality_state
	WHERE [lots].[lot_no] = @lot_no
END
