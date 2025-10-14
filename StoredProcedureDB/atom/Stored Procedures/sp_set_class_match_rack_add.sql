-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_class_match_rack_add] 
	-- Add the parameters for the stored procedure here
	@classID AS int,
	@locations_name AS VARCHAR(50),
	@OpNo AS VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @emp_id int
		SELECT @emp_id = id 
		FROM APCSProDB.man.users
		WHERE emp_num = @OpNo

    -- Insert statements for procedure here	
	INSERT INTO [APCSProDB].[inv].[class_locations]
		(
			class_id
			, location_name
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by]
		)
		VALUES(
			@classID
			, @locations_name
			, GETDATE()
			, @emp_id
			, NULL
			, NULL
		)

END
