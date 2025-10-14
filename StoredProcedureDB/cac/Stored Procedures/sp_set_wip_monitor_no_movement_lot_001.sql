-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_wip_monitor_no_movement_lot_001] 
	-- Add the parameters for the stored procedure here
	  @status_id int
	, @lot_no varchar(10)
	, @status varchar(200) = NULL
	, @problem_point varchar(200) = NULL
	, @incharge varchar(50) = NULL	
	, @plan_date date = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@status_id = 1)
	BEGIN
		IF EXISTS(select * from [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail] where lot_no = @lot_no)
			BEGIN
				UPDATE [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail]
				SET [status] = @status
					,[problem_point] = @problem_point
					,[incharge] = @incharge				
					,[plan_date] = @plan_date
				WHERE [lot_no] = @lot_no
			END
		ELSE
			BEGIN
				INSERT INTO [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail]
				([lot_no]
				, [status]
				, [problem_point]
				, [incharge]			
				, [plan_date])
				VALUES
				(@lot_no
				, @status
				, @problem_point
				, @incharge			
				, @plan_date)
			END
	END
	ELSE
	BEGIN
		DELETE FROM [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail]
		WHERE [lot_no] = @lot_no
	END
END
