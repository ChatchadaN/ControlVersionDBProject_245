-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_trc_machine_setting]
	-- Add the parameters for the stored procedure here
	@id int = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @id = CASE WHEN @id = 0 THEN NULL ELSE @id  END 

    -- Insert statements for procedure here
	BEGIN
	SELECT [machine_trc_settings].[id]
	,[abnormal_detail_id]
	,[abnormal_detail].[name]					AS abnormal_detail
	,[machine_model_id],[models].[name]			AS machine_model 
	,[is_default],[is_item_before]
	,[machine_trc_settings].[is_disable]
	,[machine_trc_settings].[created_at]
	,[machine_trc_settings].[updated_at] 
	,[user1].[emp_num]								AS[created_by]
	,[user2].[emp_num]								AS[updated_by]
	FROM [APCSProDB].[trans].[machine_trc_settings]
	LEFT JOIN[APCSProDB].[trans].[abnormal_detail] ON [machine_trc_settings].[abnormal_detail_id] = [abnormal_detail].[id]
	LEFT JOIN[APCSProDB].[mc].[models] ON [machine_trc_settings].[machine_model_id] = [models].[id]
	LEFT JOIN[APCSProDB].[man].[users] AS user1 ON [machine_trc_settings].[created_by] = [user1].[id]
	LEFT JOIN[APCSProDB].[man].[users] AS user2 ON [machine_trc_settings].[updated_by] = [user2].[id]
	WHERE [machine_trc_settings].[id] =  @id  OR  @id  IS NULL
	END
END
