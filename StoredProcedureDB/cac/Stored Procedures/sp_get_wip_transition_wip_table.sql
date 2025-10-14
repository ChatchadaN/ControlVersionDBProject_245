-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_transition_wip_table]
	-- Add the parameters for the stored procedure here
	@unit int = 1
	, @start_date date = NULL
	, @end_date date = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF (@unit = 1)
	BEGIN
		select *
		from
		(
			select [date_value]
				, [process]
				, SUM([total]) as [total]
			from [APCSProDWH].[cac].[wip_monitor_main]
			where [date_value] between @start_date and @end_date
			group by [date_value],[process]
		) as TEMP
		PIVOT
		(
			SUM([total])
			FOR [process] IN([DB]
			, [WB]
			, [MP]
			, [TC]
			, [PL]
			, [FL]
			, [FT]
			, [TP]
			, [O/G]
			, [QA]
			, [Singulation]
			)
		) AS TempPivot
	END

	IF (@unit = 2)
	BEGIN
		select *
		from
		(
			select [date_value]
				, [process]
				, SUM([total_pcs]) as [total]
			from [APCSProDWH].[cac].[wip_monitor_main]
			where [date_value] between @start_date and @end_date
			group by [date_value],[process]
		) as TEMP
		PIVOT
		(
			SUM([total])
			FOR [process] IN([DB]
			, [WB]
			, [MP]
			, [TC]
			, [PL]
			, [FL]
			, [FT]
			, [TP]
			, [O/G]
			, [QA]
			, [Singulation]
			)
		) AS TempPivot
	END
END
