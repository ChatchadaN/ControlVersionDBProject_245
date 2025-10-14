-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_wb_hse_lifetime]
	-- Add the parameters for the stored procedure here
	@Barcode varchar(100),
	@VALUE int,
	@OPID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ID INT
    -- Insert statements for procedure here
	IF EXISTS (SELECT * FROM APCSProDB.trans.jigs WHERE barcode = @Barcode)
	BEGIN
		SET @ID = (SELECT id FROM APCSProDB.trans.jigs WHERE barcode = @Barcode)
		UPDATE [APCSProDB].[trans].jig_conditions
		SET value = @VALUE
		WHERE id = @ID


	INSERT INTO  [APCSProDB].[trans].[jig_condition_records]
           (
						 [day_id]
						,[recorded_at]
						,[jig_id]
						,[control_no]
						,[val]
						,[reseted_at]
						,[reseted_by]
		   )
			SELECT          				 
						(SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
						,GETDATE()
						,id
						,control_no
						,@VALUE
						,GETDATE()
						,@OPID
		   FROM  APCSProDB.trans.jig_conditions
		   WHERE id = @ID

		   SELECT * FROM [APCSProDB].[trans].jig_conditions WHERE id = @ID
	END
END
