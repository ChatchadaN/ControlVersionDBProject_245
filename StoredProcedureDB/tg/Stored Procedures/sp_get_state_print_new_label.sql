-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [tg].[sp_get_state_print_new_label]
	-- Add the parameters for the stored procedure here
	 @lotno varchar(10) = '' --'2319A6488V'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@lotno = '')
	BEGIN
		SELECT '' AS [Status];
		RETURN;
	END

	DECLARE @package VARCHAR(10)
		, @pc_code INT
		, @get_lotno VARCHAR(10)

	DECLARE @table TABLE (
		[package] [varchar](20),
		[date_open] [date]
	)

	--INSERT INTO @table
	--	( [package]
	--	, [date_open] )
	--VALUES 
	--	('HTSSOP-B20','2023-09-10')
	--	,('SSOP-B28W','2023-09-11')
	--	,('SSOP-B20W','2023-09-12')
	--	,('TO252-3','2023-09-26')
	--	,('WSOF6','2023-09-20')
	--	--,('SSON004R10','2023-09-20');

	SELECT @package = [packages].[short_name]
		, @pc_code = [lots].[pc_instruction_code]
		, @get_lotno = [lots].[lot_no]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
	WHERE [lots].[lot_no] = @lotno;


	--IF (@pc_code IN (13,1)) -- D-lot only update by Aomsin : 2024/01/09 time : 15.42 close : 2024/02/06 time : 10.33 by aomsin
	--BEGIN
	--	IF(SUBSTRING(@get_lotno,5,1) = 'D')
	--	BEGIN
	--		SELECT 'FALSE' AS [Status];  --ต้องขยาย new printer ครบก่อน ถึงจะเปิดใช้งาน New Label PC-Reuest ของ OGI และ TP
	--		RETURN;
	--	END
	--END

	IF EXISTS (
		SELECT [package] 
		FROM [APCSProDWH].[tg].[config_new_labels]  --update : 2023/12/14 time : 11.01
		WHERE [package] = @package
			AND [date_open] <= CONVERT(DATE, GETDATE())
	)
	BEGIN
		SELECT 'TRUE' AS [Status];
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS [Status];
		RETURN;
	END
END
