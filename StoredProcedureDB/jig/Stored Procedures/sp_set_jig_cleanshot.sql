
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [jig].[sp_set_jig_cleanshot]
	-- Add the parameters for the stored procedure here
		@qrcodebyuser			AS NVARCHAR(100) 
	 ,  @process_id				INT				 =  NULL 
	 ,  @update_by				INT				

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @jig_id		INT
     
	
	SET @jig_id = (SELECT TOP(1) id FROM APCSProDB.trans.jigs WHERE barcode = @qrcodebyuser OR smallcode = @qrcodebyuser  )
 
	BEGIN TRANSACTION
	BEGIN TRY
	
	 		UPDATE    APCSProDB.trans.jig_conditions
			SET		  periodcheck_value			= 0
					, reseted_at				= GETDATE()
					, reseted_by				= @update_by
			WHERE id = @JIG_ID

			INSERT INTO  [APCSProDB].[trans].[jig_condition_records]
           (
						  [day_id]
						, [recorded_at]
						, [jig_id]
						, [control_no]
						, [val]
						, [reseted_at]
						, [reseted_by]
						, [periodcheck_value]
						, accumulate_lifetime
		   )
		   	SELECT        (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
						, GETDATE()
						, id
						, control_no
						, [value]
						, GETDATE()
						, @update_by
						, periodcheck_value 
						, accumulate_lifetime
		   FROM  APCSProDB.trans.jig_conditions
		   WHERE id = @JIG_ID
		  
		   	SELECT    'TRUE' AS Is_Pass
					, N'This jig ('+ @qrcodebyuser + ') Clean Shot done!!' AS Error_Message_ENG
					, N'jig นี้ ('+ @qrcodebyuser + N') Clean Shot แล้ว !!' AS Error_Message_THA
					, '' AS Handling
					  
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH

		SELECT	  'FALSE'						AS Is_Pass 
				, ERROR_MESSAGE()				AS Error_Message_ENG
				, N'ไม่สามารถ Clean shot ได้ !!' AS Error_Message_THA
				, N' กรุณาติดต่อ System'			AS Handling


	ROLLBACK TRANSACTION 
	END CATCH


END
