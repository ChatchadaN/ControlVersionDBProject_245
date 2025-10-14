-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20223101>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_step_no] 
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare	@step_no int = null
   
	select @step_no = isnull([lot_special_flows].[step_no],[lots].[step_no]) ---as [step_no]
	from [APCSProDB].[trans].[lots]                                                                                   
	left join [APCSProDB].[trans].[special_flows] on [lots].[is_special_flow] = 1                                    
		and [lots].[special_flow_id] = [special_flows].[id]                                                            
	left join [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id] 
		and [special_flows].[step_no] = [lot_special_flows].[step_no]                                                 
	where [lot_no] = @lot_no;

	select @step_no as step_no 
	--select 200 as step_no 
END
