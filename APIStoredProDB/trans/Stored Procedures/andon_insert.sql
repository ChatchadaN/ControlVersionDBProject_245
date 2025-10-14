-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[andon_insert]
	@op_emp_code VARCHAR(6),
	@machine_id INT,
	@sub_category_id INT,
	@location_id INT,
	@id_at_finding INT,
	@comments VARCHAR(MAX) =  '',
	@item VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[trans].[andon_insert_001]
		@op_emp_code		= @op_emp_code,
		@machine_id			= @machine_id,
		@sub_category_id	= @sub_category_id,
		@location_id		= @location_id,
		@id_at_finding		= @id_at_finding,
		@comments			= @comments,
		@item				= @item

END
