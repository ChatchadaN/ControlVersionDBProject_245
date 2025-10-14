-- =============================================
-- Author:		KITTITAT
-- =============================================
CREATE PROCEDURE [trans].[sp_set_exec_history_001]
	 @login_name VARCHAR(50)
	, @hostname VARCHAR(50)
	, @appname VARCHAR(50)
	, @command_text VARCHAR(MAX)
	, @lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	---------------------------------------------------------
	--- LOG
	---------------------------------------------------------
	--INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
	--(
	--	[record_at]
	--	, [record_class]
	--	, [login_name]
	--	, [hostname]
	--	, [appname]
	--	, [command_text]
	--	, [lot_no]
	--)
	SELECT GETDATE() AS [record_at]
		, 4 AS [record_class] --1 Insert,2 Update,3 Delete,4 StoredProcedure
		, @login_name AS [login_name]
		, @hostname AS [hostname]
		, @appname AS [appname]
		, @command_text AS [command_text]
		, @lot_no AS [lot_no]
	---------------------------------------------------------
END
