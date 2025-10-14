-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_divided_lots]
	-- Add the parameters for the stored procedure here
	--@type_check INT --1: get create_text ,2: get update send rohm
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	------ ########## VERSION 001 ##########
	--EXEC [StoredProcedureDB].[trans].[sp_get_divided_lots_ver_001] 
	--	@type_check = @type_check
	------ ########## VERSION 001 ##########

	---- ########## VERSION 002 ##########
	EXEC [StoredProcedureDB].[trans].[sp_get_divided_lots_ver_002] 
	---- ########## VERSION 002 ##########
END
