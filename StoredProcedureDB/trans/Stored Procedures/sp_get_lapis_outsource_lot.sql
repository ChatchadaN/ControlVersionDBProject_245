-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_lapis_outsource_lot]
	-- Add the parameters for the stored procedure here
	@lotno AS VARCHAR(10),
	@mag1 AS VARCHAR(255),
	@mag2 AS VARCHAR(255) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @lotno AND container_no =  CASE WHEN @mag2 IS NULL THEN @mag1 ELSE CONCAT( @mag1,'|',@mag2) END) BEGIN
		UPDATE APCSProDB.trans.lots SET 
			updated_at = GETDATE()
			--ship_date_id = (SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date))
			WHERE lot_no = @lotno

		SELECT 'TRUE' AS Is_Pass,'' AS lot_no,N'' AS magazine
	END
	ELSE IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @lotno AND container_no = CASE WHEN @mag2 IS NULL THEN @mag1 ELSE CONCAT( @mag2,'|',@mag1) END) BEGIN
		UPDATE APCSProDB.trans.lots SET 
			updated_at = GETDATE()
			--ship_date_id = (SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date))
			WHERE lot_no = @lotno

		SELECT 'TRUE' AS Is_Pass,'' AS lot_no,N'' AS magazine
	END
	ELSE BEGIN
		SELECT 'FALSE' AS Is_Pass ,lot_no,container_no AS magazine FROM APCSProDB.trans.lots WHERE lot_no = @lotno
	END
END
