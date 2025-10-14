
CREATE PROCEDURE [lsms].[sp_test]
	-- Add the parameters for the stored procedure here
	@master_lot VARCHAR(10)
	, @emp_id INT
	, @is_return INT --#0: no return, 1: retrun
	, @Is_Pass NVARCHAR(MAX) = NULL OUTPUT
	, @Error_Message_ENG NVARCHAR(MAX) = NULL OUTPUT
	, @Error_Message_THA NVARCHAR(MAX) = NULL OUTPUT
	, @Handling NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------------------------
	----- # create lot in trans.lot_combine, trans.lot_combine_records
	----------------------------------------------------------------------------
	SET @Is_Pass = 'TRUE';
	SET @Error_Message_ENG = 'Lot is combine !!';
	SET @Error_Message_THA = N'Lot นี้ถูกรวม Lot แล้ว';
	SET @Handling = N'กรุณาติดต่อ system';

	IF (@is_return = 1)
	BEGIN
		SELECT @Is_Pass AS [Is_Pass] 
			, @Error_Message_ENG AS [Error_Message_ENG]
			, @Error_Message_THA AS [Error_Message_THA] 
			, @Handling AS [Handling];
	END
	RETURN;
END
