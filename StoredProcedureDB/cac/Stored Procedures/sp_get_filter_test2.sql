-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_filter_test2]
	-- Add the parameters for the stored procedure here
	@lot_type varchar(1) = null
	, @package_group varchar(50) = null
	, @package varchar(50) = null
	, @device varchar(50) = null
	, @process varchar(50) = null
	, @filter int = 1 -- 1: Package Group, 2: Package, 3: Device, 4: Process, 5: Lot Type
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	---------------------------------------------------------------------------
	--(0)set parameter
    ---------------------------------------------------------------------------
	if (@lot_type = '%')
	begin 
		set @lot_type = null
	end

	if (@package_group = '%')
	begin 
		set @package_group = null
	end

	if (@package = '%')
	begin 
		set @package = null
	end

	if (@device = '%')
	begin 
		set @device = null
	end

	if (@process = '%')
	begin 
		set @process = null
	end
	---------------------------------------------------------------------------
	--(0)DECLARE
    ---------------------------------------------------------------------------
	DECLARE @sqltext NVARCHAR(max) = '';
	DECLARE @sqlwhere int = 0;
	DECLARE @sqland int = 0;

	SET @sqltext = N'';
	---------------------------------------------------------------------------
	--(1)sql select
    ---------------------------------------------------------------------------
	IF(@filter = 1)
	BEGIN
		SET @sqltext = @sqltext + N'select [package_groups].[name] as [filter_name] ';
	END
	IF(@filter = 2)
	BEGIN
		SET @sqltext = @sqltext + N'select [packages].[name] as [filter_name] ';
	END
	IF(@filter = 3)
	BEGIN
		SET @sqltext = @sqltext + N'select [device_names].[name] as [filter_name] ';
	END
	IF(@filter = 4)
	BEGIN
		SET @sqltext = @sqltext + N'select [processes].[name] as [filter_name] ';
	END
	IF(@filter = 5)
	BEGIN
		SET @sqltext = @sqltext + N'select substring([lots].[lot_no],5,1) as [filter_name] ';
	END
	---------------------------------------------------------------------------
	--(2)sql from
    ---------------------------------------------------------------------------
	SET @sqltext = @sqltext + N'from [APCSProDB].[trans].[lots] ';
	SET @sqltext = @sqltext + N'inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id] ';
	SET @sqltext = @sqltext + N'inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id] ';
	SET @sqltext = @sqltext + N'inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id] ';
	SET @sqltext = @sqltext + N'inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id] ';
	SET @sqltext = @sqltext + N'inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id] ';
	SET @sqltext = @sqltext + N'inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] ';
	SET @sqltext = @sqltext + N'inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id] ';
	SET @sqltext = @sqltext + N'inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id] ';
	---------------------------------------------------------------------------
	--(3)sql where
    ---------------------------------------------------------------------------
	IF (@package_group is not null and @package_group != '')
	BEGIN
		SET @sqltext = @sqltext + N'where [package_groups].[name] = ''' + @package_group + ''' ';
		SET @sqlwhere = 1;
		SET @sqland= 1;
	END

	IF (@package is not null and @package != '')
	BEGIN
		IF (@sqlwhere = 0)
		BEGIN
			SET @sqltext = @sqltext + N'where ';
		END

		IF (@sqland = 1)
		BEGIN
			SET @sqltext = @sqltext + N'and ';
		END
		SET @sqltext = @sqltext + N' [packages].[name] = ''' + @package + ''' ';
		SET @sqlwhere = 1;
		SET @sqland= 1;
	END

	IF (@device is not null and @device != '')
	BEGIN
		IF (@sqlwhere = 0)
		BEGIN
			SET @sqltext = @sqltext + N'where ';
		END

		IF (@sqland = 1)
		BEGIN
			SET @sqltext = @sqltext + N'and ';
		END
		SET @sqltext = @sqltext + N' [device_names].[name] = ''' + @device + ''' ';
		SET @sqlwhere = 1;
		SET @sqland= 1;
	END

	IF (@process is not null and @process != '')
	BEGIN
		IF (@sqlwhere = 0)
		BEGIN
			SET @sqltext = @sqltext + N'where ';
		END

		IF (@sqland = 1)
		BEGIN
			SET @sqltext = @sqltext + N'and ';
		END
		SET @sqltext = @sqltext + N' [processes].[name] = ''' + @process + ''' ';
		SET @sqlwhere = 1;
		SET @sqland= 1;
	END

	IF (@lot_type is not null and @lot_type != '')
	BEGIN
		IF (@sqlwhere = 0)
		BEGIN
			SET @sqltext = @sqltext + N'where ';
		END

		IF (@sqland = 1)
		BEGIN
			SET @sqltext = @sqltext + N'and ';
		END
		SET @sqltext = @sqltext + N' substring([lots].[lot_no],5,1) = ''' + @lot_type + ''' ';
	END
	---------------------------------------------------------------------------
	--(4)sql group by
    ---------------------------------------------------------------------------
	IF(@filter = 1)
	BEGIN
		SET @sqltext = @sqltext + N'group by [package_groups].[name] ';
	END
	IF(@filter = 2)
	BEGIN
		SET @sqltext = @sqltext + N'group by [packages].[name] ';
	END
	IF(@filter = 3)
	BEGIN
		SET @sqltext = @sqltext + N'group by [device_names].[name] ';
	END
	IF(@filter = 4)
	BEGIN
		SET @sqltext = @sqltext + N'group by [processes].[name] ';
	END
	IF(@filter = 5)
	BEGIN
		SET @sqltext = @sqltext + N'group by substring([lots].[lot_no],5,1) ';
	END
	---------------------------------------------------------------------------
	--(5)sql execute
    ---------------------------------------------------------------------------
	--select (@sqltext);
	EXECUTE (@sqltext);

END
