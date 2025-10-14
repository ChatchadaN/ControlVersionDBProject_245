-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_wip_monitor_no_movement_lot] 
	-- Add the parameters for the stored procedure here
	  @status_id int
	, @lot_no varchar(10)
	, @status varchar(200) = NULL
	, @problem_point varchar(200) = NULL
	, @problem_point_id varchar(200) = NULL
	, @incharge varchar(50) = NULL	
	, @plan_date date = NULL
	, @contact_pic varchar(200) = NULL
	, @response_plant varchar(200) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@status_id = 1)
	BEGIN
		-----------------------------------------------------------------------------
		--------------------( wip_monitor_no_movement_lot_detail )--------------------
		IF EXISTS(select * from [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail] where lot_no = @lot_no)
		BEGIN
			IF (@problem_point_id IS NOT NULL)
			BEGIN
				UPDATE [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail]
				SET [status] = @status
					,[problem_point] = @problem_point
					,[problem_point_id] = CAST(@problem_point_id AS INT)
					,[incharge] = @incharge				
					,[plan_date] = @plan_date
					,[contact_pic_id] = @contact_pic
					,[response_plant_id] = @response_plant
				WHERE [lot_no] = @lot_no
			END
			ELSE
			BEGIN
				UPDATE [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail]
				SET [status] = @status
					,[problem_point] = @problem_point
					,[incharge] = @incharge				
					,[plan_date] = @plan_date
					,[contact_pic_id] = @contact_pic
					,[response_plant_id] = @response_plant
				WHERE [lot_no] = @lot_no
			END
		END
		ELSE BEGIN
			IF (@problem_point_id IS NOT NULL)
			BEGIN
				INSERT INTO [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail]
				( [lot_no]
				, [status]
				, [problem_point]
				, [incharge]			
				, [plan_date]
				, [problem_point_id]
				, [contact_pic_id]
				, [response_plant_id] )
				VALUES
				( @lot_no
				, @status
				, @problem_point
				, @incharge			
				, @plan_date
				, CAST(@problem_point_id AS INT)
				, @contact_pic
				, @response_plant )
			END
			ELSE
			BEGIN
				INSERT INTO [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail]
				( [lot_no]
				, [status]
				, [problem_point]
				, [incharge]			
				, [plan_date]
				, [contact_pic_id]
				, [response_plant_id] )
				VALUES
				( @lot_no
				, @status
				, @problem_point
				, @incharge			
				, @plan_date
				, @contact_pic
				, @response_plant )
			END

			
		END
		--------------------( wip_monitor_no_movement_lot_detail )--------------------

		--------------------( wip_monitor_delay_lot_condition_detail )--------------------
		IF EXISTS(select * from [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] where lot_no = @lot_no)
		BEGIN
			IF (@problem_point_id IS NOT NULL)
			BEGIN
				UPDATE [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail]
				SET [status] = @status
					,[problem_point] = @problem_point
					,[problem_point_id] = CAST(@problem_point_id AS INT)
					,[incharge] = @incharge
					,[occure_date] = @plan_date
					,[contact_pic_id] = @contact_pic
					,[response_plant_id] = @response_plant
				WHERE [lot_no] = @lot_no
			END
			ELSE
			BEGIN
				UPDATE [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail]
				SET [status] = @status
					,[problem_point] = @problem_point
					,[incharge] = @incharge
					,[occure_date] = @plan_date
					,[contact_pic_id] = @contact_pic
					,[response_plant_id] = @response_plant
				WHERE [lot_no] = @lot_no
			END
		END
		ELSE
		BEGIN
			IF (@problem_point_id IS NOT NULL)
			BEGIN
				INSERT INTO [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail]
				([lot_no]
				, [status]
				, [problem_point]
				, [problem_point_id]
				, [incharge]
				, [occure_date]
				, [plan_date]
				, [contact_pic_id]
				, [response_plant_id] )
				VALUES
				(@lot_no
				, @status
				, @problem_point
				, CAST(@problem_point_id AS INT)
				, @incharge
				, @plan_date
				, NULL
				, @contact_pic
				, @response_plant )
			END
			ELSE
			BEGIN
				INSERT INTO [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail]
				([lot_no]
				, [status]
				, [problem_point]
				, [incharge]
				, [occure_date]
				, [plan_date]
				, [contact_pic_id]
				, [response_plant_id] )
				VALUES
				(@lot_no
				, @status
				, @problem_point
				, @incharge			
				, @plan_date
				, NULL
				, @contact_pic
				, @response_plant )
			END
		END
		--------------------( wip_monitor_delay_lot_condition_detail )--------------------
		-----------------------------------------------------------------------------
	END
	ELSE BEGIN
		-----------------------------------------------------------------------------
		DELETE FROM [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail]
		WHERE [lot_no] = @lot_no
		-----------------------------------------------------------------------------	
	END
END
