-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_divided_lots] 
	-- Add the parameters for the stored procedure here
	@lotno VARCHAR(10) = '%',
	@package_group VARCHAR(10) = '%',
	@package VARCHAR(20) = '%',
	@device VARCHAR(20) = '%',
	@status INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	IF (@status = 0)
	BEGIN
		SELECT [lots].[lot_no]
			, [packages].[name] AS [PackageName]
			, [device_names].[name] AS [DeviceName]
			, [lots].[qty_in]
			--, [divided_lots].[comment]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
		INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
		INNER JOIN [APCSProDB].[method].[package_groups] ON [packages].[package_group_id] = [package_groups].[id]
		INNER JOIN [APCSProDB].[trans].[days] AS [day_indate] ON [day_indate].[id] = [lots].[in_plan_date_id]
		LEFT JOIN [APCSProDWH].[atom].[divided_lots] ON [divided_lots].[lot_id]	= [lots].[id]
		WHERE [divided_lots].[lot_id] IS NULL
			AND SUBSTRING([lots].[lot_no],5,1) IN ('A','F','E','V','W','X','5','6','7','8')
			AND [lots].[wip_state] IN (0,10,20)
			--AND [day_indate].[date_value] > CONVERT(DATE, GETDATE())
			--AND [day_indate].[date_value] > CONVERT(DATE, DATEADD(DAY, -3, GETDATE()))
			AND YEAR([day_indate].[date_value]) <= YEAR(CONVERT(DATE, GETDATE()))
			AND [package_groups].[id] NOT IN (1, 35)
			AND [package_groups].[name] LIKE @package_group
			AND [packages].[name] LIKE @package 
			AND [device_names].[name] LIKE @device 
			AND TRIM([lots].[lot_no]) LIKE @lotno + '%';
	END
	ELSE IF (@status = 1)
	BEGIN
		SELECT [lots].[lot_no]
			, [packages].[name] AS [PackageName]
			, [device_names].[name] AS [DeviceName]
			, IIF([divided_lots].[is_create_text] = 1,'Pass','Wait') AS [is_create_text]
			, IIF([divided_lots].[is_send_text] = 1,'Pass','Wait') AS [is_send_text] 
			, [users].[name] AS [NameCreate]
			, [divided_lots].[created_at]
			--, [LOT_DIVIDE].[FLAG]
			, [divided_lots].[is_create_text] AS [FLAG]
			, [lots].[qty_in]
			, [divided_lots].[comment]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
		INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
		INNER JOIN [APCSProDB].[method].[package_groups] ON [packages].[package_group_id] = [package_groups].[id]
		INNER JOIN [APCSProDWH].[atom].[divided_lots] ON [divided_lots].[lot_id] = [lots].[id]
		LEFT JOIN [APCSProDB].[man].[users] ON [divided_lots].[created_by] = [users].[id]
		--LEFT JOIN [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] ON [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS = [LOT_DIVIDE].[LOT_NO] COLLATE SQL_Latin1_General_CP1_CI_AS
		WHERE SUBSTRING([lots].[lot_no],5,1) IN ('A','F','E','V','W','X','5','6','7','8')
			AND [package_groups].[name] LIKE @package_group
			AND [packages].[name] LIKE @package 
			AND [device_names].[name] LIKE @device 
			AND TRIM([lots].[lot_no]) LIKE @lotno + '%'
		ORDER BY [divided_lots].[created_at] ASC;
	END
END