-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_divided_lots]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10),
	@type_action INT, --1: update create text , 2: update send text, 3: update send text (error)
	@comment VARCHAR(100) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	------ ########## VERSION 001 ##########
	--EXEC [StoredProcedureDB].[trans].[sp_set_divided_lots_ver_001] 
	--	@lot_no = @lot_no
	--	, @type_action = @type_action
	------ ########## VERSION 001 ##########

	------ ########## VERSION 002 ##########
	--EXEC [StoredProcedureDB].[trans].[sp_set_divided_lots_ver_002] 
	--	@lot_no = @lot_no
	--	, @type_action = @type_action
	------ ########## VERSION 002 ##########

	---- ########## VERSION 003 ##########
	EXEC [StoredProcedureDB].[trans].[sp_set_divided_lots_ver_003] 
		@lot_no = @lot_no
		, @type_action = @type_action
		, @comment = @comment
	---- ########## VERSION 003 ##########
END
