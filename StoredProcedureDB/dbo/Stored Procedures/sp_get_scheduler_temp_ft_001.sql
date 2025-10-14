-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_temp_ft_001] 
	-- Add the parameters for the stored procedure here
	@PKG VARCHAR(MAX) ='',
	@IsGDIC INT = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	if (@IsGDIC = 1)
	begin
		-------------------------------------------(@IsGDIC = 1)-------------------------------------------
		 select [temp].[MCNo]
			, [temp].[McId]
			, [temp].[oprate]
			, [temp].[setupid]
			, [temp].[LotNo]
			, [temp].[PackageName]
			, [temp].[DeviceName]
			, [temp].[ProgramName]
			, [temp].[TesterType]
			, [temp].[TestFlow]
			--, [temp].[TestBoxA]
			--, [temp].[TestBoxB]
			, case 
				when [temp].[TestBoxA] is not null or [temp].[TestBoxA] != '' then [temp].[TestBoxA]
				else [temp].[TestBoxB] end as [TestBord]
			--, [temp].[DutcardA]
			--, [temp].[DutcardB]
			, case 
				when [temp].[DutcardA] is not null or [temp].[DutcardA] != '' then [temp].[DutcardA]
				else [temp].[DutcardB] end as [DutName]
			, [temp].[OptionName1]
			, [temp].[OptionName2]
			, [temp].[Status]
			, [temp].[LOT1]
			, [temp].[LOT2]
			, [temp].[LOT3]
			, [temp].[LOT4]
			, [temp].[LOT5]
			, [temp].[LOT6]
			, [temp].[LOT7]
			, [temp].[LOT8]
			, [temp].[LOT9]
			, [temp].[LOT10]
			, [temp].[DEVICE1]
			, [temp].[DEVICE2]
			, [temp].[DEVICE3]
			, [temp].[DEVICE4]
			, [temp].[DEVICE5]
			, [temp].[DEVICE6]
			, [temp].[DEVICE7]
			, [temp].[DEVICE8]
			, [temp].[DEVICE9]
			, [temp].[DEVICE10]
			, [temp].[LOT2_RackAddress]
			, [temp].[LOT2_RackName]
			, [temp].[DelayLot]
			, [temp].[LOT1Date]
			, [temp].[LOT1SDate]
			--, [temp].[AdaptorA]
			--, [temp].[AdaptorB]
			, case 
				when [temp].[AdaptorA] is not null or [temp].[AdaptorA] != '' then [temp].[AdaptorA]
				else [temp].[AdaptorB] end as [Adaptor]
			, SUBSTRING([temp].[DeviceName] , 0,(CHARINDEX('-', [temp].[DeviceName]))) as [CustomDevice]
		from [DBxDW].[dbo].[scheduler_temp_ft]  as [temp]
		left join [APCSProDB].[trans].[lots] on [temp].[LotNo] = [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS
		left join [APCSProDB].[method].[device_names] on [device_names].[id] =  [lots].[act_device_name_id]
		where [temp].[PackageName] in (SELECT * from STRING_SPLIT ( @PKG , ',' ))
			and [device_names].[alias_package_group_id] = 33
			and [temp].[MCNo] not like '%-099%'
			and [temp].[MCNo] not like '%-000'
		-------------------------------------------(@IsGDIC = 1)-------------------------------------------
	end
	else begin
		-------------------------------------------(@IsGDIC = 0)-------------------------------------------
		select [temp].[MCNo]
			, [temp].[McId]
			, [temp].[oprate]
			, [temp].[setupid]
			, [temp].[LotNo]
			, [temp].[PackageName]
			, [temp].[DeviceName]
			, [temp].[ProgramName]
			, [temp].[TesterType]
			, [temp].[TestFlow]
			--, [temp].[TestBoxA]
			--, [temp].[TestBoxB]
			, case 
				when [temp].[TestBoxA] is not null or [temp].[TestBoxA] != '' then [temp].[TestBoxA]
				else [temp].[TestBoxB] end as [TestBord]
			--, [temp].[DutcardA]
			--, [temp].[DutcardB]
			, case 
				when [temp].[DutcardA] is not null or [temp].[DutcardA] != '' then [temp].[DutcardA]
				else [temp].[DutcardB] end as [DutName]
			, [temp].[OptionName1]
			, [temp].[OptionName2]
			, [temp].[Status]
			, [temp].[LOT1]
			, [temp].[LOT2]
			, [temp].[LOT3]
			, [temp].[LOT4]
			, [temp].[LOT5]
			, [temp].[LOT6]
			, [temp].[LOT7]
			, [temp].[LOT8]
			, [temp].[LOT9]
			, [temp].[LOT10]
			, [temp].[DEVICE1]
			, [temp].[DEVICE2]
			, [temp].[DEVICE3]
			, [temp].[DEVICE4]
			, [temp].[DEVICE5]
			, [temp].[DEVICE6]
			, [temp].[DEVICE7]
			, [temp].[DEVICE8]
			, [temp].[DEVICE9]
			, [temp].[DEVICE10]
			, [temp].[LOT2_RackAddress]
			, [temp].[LOT2_RackName]
			, [temp].[DelayLot]
			, [temp].[LOT1Date]
			, [temp].[LOT1SDate]
			--, [temp].[AdaptorA]
			--, [temp].[AdaptorB]
			, case 
				when [temp].[AdaptorA] is not null or [temp].[AdaptorA] != '' then [temp].[AdaptorA]
				else [temp].[AdaptorB] end as [Adaptor]
			, SUBSTRING([temp].[DeviceName] , 0,(CHARINDEX('-', [temp].[DeviceName]))) as [CustomDevice]
		from [DBxDW].[dbo].[scheduler_temp_ft]  as [temp]
		left join [APCSProDB].[trans].[lots] on [temp].[LotNo] = [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS
		left join [APCSProDB].[method].[device_names] on [device_names].[id] =  [lots].[act_device_name_id]
		where [temp].[PackageName] in (SELECT * from STRING_SPLIT ( @PKG , ',' ))
			and [device_names].[alias_package_group_id] != 33
			and [temp].[MCNo] not like '%-000'
			and [temp].[MCNo] not in ('FT-M-150','FT-M-167')
		-------------------------------------------(@IsGDIC = 0)-------------------------------------------
	end


END
