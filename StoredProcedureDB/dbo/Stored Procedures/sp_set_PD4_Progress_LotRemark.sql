-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_PD4_Progress_LotRemark]
	-- Add the parameters for the stored procedure here

	@lot_no			char(20)
    ,@job_owner		nvarchar(20)
    ,@job_front		nvarchar(20)
    ,@remark		nvarchar(100)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS
	(
			SELECT * FROM [DBx].[dbo].[FL_DailyReport_LotRemark] 
			WHERE [lot_no] = @lot_no
			AND [job_owner] = @job_owner
			AND [job_front] = @job_front
	)

	BEGIN
			INSERT INTO [DBx].[dbo].[FL_DailyReport_LotRemark]
			(
				[lot_no]
				,[job_owner]
				,[job_front]
				,[remark]
				,[created_at]
				,[update_at]
			)
			 
			VALUES
			(
				@lot_no
				,@job_owner
				,@job_front
				,@remark
				,GETDATE()
				,GETDATE()
			)
	END

	ELSE
	BEGIN

			UPDATE [DBx].[dbo].[FL_DailyReport_LotRemark]
			SET 
					[lot_no]		= @lot_no
					,[job_owner]	= @job_owner
					,[job_front]	= @job_front
					,[remark]		= @remark
					,[update_at]	= GETDATE()
			
			WHERE 
					[lot_no] = @lot_no
					AND [job_owner] = @job_owner
					AND [job_front] = @job_front
	END
END
