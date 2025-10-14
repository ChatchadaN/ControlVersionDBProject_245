-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [trans].[sp_set_compare_label]
	-- Add the parameters for the stored procedure here
	  @lot_no VARCHAR(10)
	,@item_no VARCHAR(5)
	,@qr_code1 CHAR(114) = ''
	,@qr_code2 CHAR(114) = ''
	,@empno VARCHAR(6) = NULL 
	,@division_id INT = NULL
	,@source_type VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[trans].[sp_set_compare_label_001] 
     @lot_no = @lot_no
	,@item_no = @item_no
	,@qr_code1 = @qr_code1
	,@qr_code2 = @qr_code2
	,@empno  = @empno
	,@division_id = @division_id
	,@source_type = @source_type
	-- ########## VERSION 001 ##########

END
