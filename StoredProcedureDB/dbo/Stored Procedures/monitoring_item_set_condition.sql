-- =============================================
-- Author:		<Jakkapong pureinsin>
-- Create date: <12/20/2021>
-- Description:	<Insert and update to monitoring condition>
-- =============================================
CREATE PROCEDURE [dbo].[monitoring_item_set_condition]
	@addValue INT,   
    @monitoring_id INT,
	@user INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @oldValue DECIMAL(9,1);

	

	IF(NOT EXISTS (select id from [APCSProDWH].[wip_control].[monitoring_item_conditions] where id = @monitoring_id))
	--IF NOT IN TABLE ADD TO TABLE
		BEGIN
			SET @oldValue = (SELECT target_value from APCSProDWH.wip_control.monitoring_items where id = @monitoring_id)
			INSERT INTO [APCSProDWH].[wip_control].[monitoring_item_conditions] ([id],[add_value],[old_value],[expire_date],[is_expired],[create_at] ,[create_by],[update_at] ,[update_by])
			VALUES (@monitoring_id,@addValue,@oldValue,DATEADD(day, 1, GETDATE()),0,GETDATE(),@user,GETDATE(),@user )
		END
	ELSE 
		BEGIN
			SET @oldValue = (SELECT old_value from [APCSProDWH].[wip_control].[monitoring_item_conditions] where id = @monitoring_id)
			UPDATE [APCSProDWH].[wip_control].[monitoring_item_conditions]
			SET add_value = @addValue,
				old_value = @oldValue,
				update_at = GETDATE(), 
				expire_date = DATEADD(day, 1, GETDATE()),
				update_by = @user,
				is_expired = 0	
			WHERE id = @monitoring_id
		END

	Update [APCSProDWH].[wip_control].[monitoring_items] 
	SET target_value = target_value + @addValue,
		alarm_value = alarm_value + @addValue
	where id = @monitoring_id
	
	--INSERT INTO RECORD LOG
	INSERT INTO [APCSProDWH].[wip_control].[monitoring_item_condition_records] ([item_id],[add_value],[old_value],[expire_date],[is_expired],[create_at] ,[create_by],[update_at] ,[update_by])
	VALUES(@monitoring_id,@addValue,@oldValue,DATEADD(day, 1, GETDATE()),0,GETDATE(),@user,GETDATE(),@user)
END
