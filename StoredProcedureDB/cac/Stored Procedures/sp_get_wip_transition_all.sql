-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_transition_all]
	-- Add the parameters for the stored procedure here
	@package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @lot_type varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
	-- Insert statements for procedure here
	select [date_value]
		,SUM([today_wip]) as [wip]
		,SUM([today_wip_pcs]) as [wip_pcs]
		,SUM([today_order_delay]) as [order_delay]
		,SUM([today_order_delay_pcs]) as [order_delay_pcs]
		,SUM([today_input]) as [input_result]
		,SUM([today_input_pcs]) as [input_result_pcs]
		,SUM([today_output]) as [output_result]
		,SUM([today_output_pcs]) as [output_result_pcs]
	from [APCSProDWH].[cac].[wip_transition_main] 
	where [package_group] like @package_group
	and [package] like @package
	and [lot_type] like @lot_type
	and [date_value] > GETDATE() - 15
	group by [date_value]
END
