-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_product_slip]
	  @slip_id INT = 0,
      @production_id INT,
      @flow_pattern_id INT,
      @version_num INT,
      @is_released INT,
	  @emp_code VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_product_slip_001]
			@slip_id = @slip_id,
			@production_id = @production_id,
			@flow_pattern_id = @flow_pattern_id,
			@version_num = @version_num,
			@is_released = @is_released,
			@emp_code = @emp_code	

END
