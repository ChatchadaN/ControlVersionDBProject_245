-- =============================================
-- Author:		NUCHA
-- Create date: 2022/06/30
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[get_matching_lotoutsource]
( 
	 @lot_outsource AS VARCHAR(20),
	 @device_name AS VARCHAR(50) = NULL,
	 @is_pass AS VARCHAR(10) OUTPUT,
	 @assy_lot_no AS VARCHAR(10) OUTPUT

)

As
Begin

	SET NOCOUNT ON

	-- ########## VERSION 001 ##########
			EXEC [APIStoredProVersionDB].trans.get_matching_lotoutsource_001
				@lot_outsource = @lot_outsource,
				@device_name = @device_name,
				@is_pass = @is_pass OUTPUT,
				@assy_lot_no = @assy_lot_no OUTPUT
	-- ########## VERSION 001 ##########
END
