-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_kk_get_lots_from_lotno]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select *
	from [APCSProDB].[trans].[lots] as l 
	where l.lot_no = @lot_no

END
