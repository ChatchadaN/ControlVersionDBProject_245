-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [trans].[sp_get_data_history_label]
	-- Add the parameters for the stored procedure here
	 @lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[trans].[sp_get_data_history_label_001] 
		 @lot_no = @lot_no
	-- ########## VERSION 001 ##########

END
