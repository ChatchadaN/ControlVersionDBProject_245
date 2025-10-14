-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20211213>
-- Description:	<Description,,Reset wiptime control update 2 table>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_wiptime_control]
	-- Add the parameters for the stored procedure here
	@lot_id varchar(10)
	,@update_by varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @update_at varchar(50);
	DECLARE @r INT = 0;

	set @update_at = GETDATE();
    -- Insert statements for procedure here
	declare @limitcontrolid_max int;

	select @limitcontrolid_max = MAX(limit_control_id)
	FROM [APCSProDB].[trans].[lot_limits]
	where lot_id = @lot_id and is_enabled = 1;

	update [APCSProDB].[trans].[lot_limits]
	set [lot_limits].is_enabled = 0
	,[lot_limits].updated_at = @update_at
	,[lot_limits].updated_by = @update_by
	where lot_id = @lot_id 
	and is_enabled = 1 
	and limit_control_id = @limitcontrolid_max;

	update [APCSProDB].[trans].[lots] 
	set [lots].[quality_state] = 0
	where [lots].id = @lot_id;
END
