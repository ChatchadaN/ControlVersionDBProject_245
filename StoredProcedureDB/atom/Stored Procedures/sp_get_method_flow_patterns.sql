-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_method_flow_patterns]
	-- Add the parameters for the stored procedure here
	@flow_pattern_id int = NULL
	, @assy_class char(1) = 'S'
	, @link_flow_no int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [flow_patterns].[id]
	, [flow_patterns].[link_flow_no]
	, [flow_patterns].[version_num]
	, [flow_details].[step_no] 
	, [jobs].[name] as job_name
	FROM [APCSProDB].[method].[flow_patterns] 
	inner join [APCSProDB].[method].[flow_details] on [flow_patterns].[id] = [flow_details].[flow_pattern_id]
	inner join [APCSProDB].[method].[jobs] on [flow_details].[job_id] = [jobs].[id]
	WHERE [flow_patterns].[assy_ft_class] = @assy_class 
	--and [flow_patterns].[id] = @flow_pattern_id
		and ([flow_patterns].[id] = @flow_pattern_id OR [flow_patterns].[link_flow_no] = @link_flow_no)
END
