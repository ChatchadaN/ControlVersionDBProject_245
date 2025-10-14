-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_clear_hold_lot]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [APCSProDB].[trans].[lots]
		SET [quality_state] = 0
	WHERE [lots].[lot_no] = @lot_no
	and [quality_state] = 3
END
