-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_mc_lot_end] 
	-- Add the parameters for the stored procedure here
	@mc_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
		DECLARE @mc_name varchar(50) = (SELECT name FROM APCSProDB.mc.machines WHERE id = @mc_id)

		IF EXISTS(SELECT * FROM DBxDW.dbo.scheduler_mc_wait where mc_id = @mc_id)
			BEGIN
				UPDATE DBxDW.[dbo].[scheduler_mc_wait]
				SET [mc_end] = (SELECT GETDATE())
				WHERE mc_id = @mc_id
			END
		ELSE
			BEGIN
				INSERT INTO [DBxDW].[dbo].[scheduler_mc_wait]
					   ([mc_id]
					   ,[mc_name]
					   ,[mc_end])
				 VALUES
					   (@mc_id
					   ,@mc_name
					   ,(SELECT GETDATE()))
			END
END
