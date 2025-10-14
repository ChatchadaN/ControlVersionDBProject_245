-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_maching_rack_job]
	-- Add the parameters for the stored procedure here
	@rack_control_id INT 
	,@job_id INT
	,@create_by INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS  (SELECT 1 FROM APCSProDB.rcs.rack_jobs WHERE rack_control_id = @rack_control_id AND job_id = @job_id)
	BEGIN
		SELECT 'FALSE' AS Is_Pass,'ERROR: Rack_Job Already Exists!!' AS Error_Message_ENG,N'ERROR: ข้อมูล Rack และ Job มีอยู่แล้ว !!' AS Error_Message_THA
		RETURN;
	END
    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @priority_new INT
		SET @priority_new = 1
	
		INSERT INTO APCSProDB.rcs.rack_jobs
		VALUES(
			@rack_control_id
			, @job_id
			, GETDATE()
			, @create_by
			, NULL
			, NULL
			, @priority_new
		)
			
		SELECT 'TRUE' AS Is_Pass ,'Register Successfully !!' AS Error_Message_ENG,N'การลงทะเบียนสำเร็จ !!' AS Error_Message_THA		
		COMMIT;
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
