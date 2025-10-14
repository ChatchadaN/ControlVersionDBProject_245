-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_data_to_is_by_task]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- ########## VERSION TEST (TESTDB) ##########
	--EXEC [StoredProcedureDB].[trans].[sp_set_data_to_is_by_task_001]
	---- ########## VERSION TEST (TESTDB) ##########

	---- ########## VERSION USING (ISDB) ##########
	--EXEC [StoredProcedureDB].[trans].[sp_set_data_to_is_by_task_002]
	---- ########## VERSION USING (ISDB) ##########

	---- ########## VERSION 003 ##########
	-- Add update QTY table WH_UKEBA
	--EXEC [StoredProcedureDB].[trans].[sp_set_data_to_is_by_task_003]
	---- ########## VERSION 003 ##########

	---- ########## VERSION 004 ##########
	-- Add Recall table
	EXEC [StoredProcedureDB].[trans].[sp_set_data_to_is_by_task_004]
	---- ########## VERSION 004 ##########
END
