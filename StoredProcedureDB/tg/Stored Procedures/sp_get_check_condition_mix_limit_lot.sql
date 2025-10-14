
CREATE PROCEDURE [tg].[sp_get_check_condition_mix_limit_lot]
	-- Add the parameters for the stored procedure here
	@PackageGroup VARCHAR(10),
	@PackageName VARCHAR(20),
	@DeviceName VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS ( 
		SELECT TOP 1 [package_group] 
		FROM [APCSProDWH].[tg].[condition_mix_limit_lot] 
		WHERE [package_group] = @PackageGroup 
			AND [package_name] = @PackageName 
			AND [device_name] = @DeviceName 
			AND [is_enable] = 1 
	)
	BEGIN
		--# 1: Find package_group, package_name, device_name
		SELECT [limit_of_lot]
		FROM [APCSProDWH].[tg].[condition_mix_limit_lot]
		WHERE [package_group] = @PackageGroup
			AND [package_name] = @PackageName
			AND [device_name] = @DeviceName
			AND [is_enable] = 1;
	END
	ELSE IF EXISTS ( 
		SELECT TOP 1 [package_group] 
		FROM [APCSProDWH].[tg].[condition_mix_limit_lot] 
		WHERE [package_group] = @PackageGroup 
			AND [package_name] = @PackageName 
			AND [device_name] = 'ALL' 
			AND [is_enable] = 1 
	)
	BEGIN
		--# 2: Find package_group, package_name
		SELECT [limit_of_lot]
		FROM [APCSProDWH].[tg].[condition_mix_limit_lot]
		WHERE [package_group] = @PackageGroup
			AND [package_name] = @PackageName
			AND [device_name] = 'ALL'
			AND [is_enable] = 1;
	END
	ELSE IF EXISTS ( 
		SELECT TOP 1 [package_group] 
		FROM [APCSProDWH].[tg].[condition_mix_limit_lot] 
		WHERE [package_group] = @PackageGroup 
			AND [package_name] = 'ALL' 
			AND [device_name] = 'ALL' 
			AND [is_enable] = 1 
	)
	BEGIN
		--# 3: Find package_group
		SELECT [limit_of_lot]
		FROM [APCSProDWH].[tg].[condition_mix_limit_lot]
		WHERE [package_group] = @PackageGroup
			AND [package_name] = 'ALL'
			AND [device_name] = 'ALL'
			AND [is_enable] = 1;
	END
	ELSE
	BEGIN
		--# 4: Not found
		SELECT 10 AS [limit_of_lot];
	END
END
