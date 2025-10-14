-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [material].[fnc_set_wf_data_table]
(	
	-- Add the parameters for the function here
	@WFDATA NVARCHAR(180)
)
RETURNS @Output TABLE (IDx INT, Qty INT)
AS
BEGIN

	DECLARE @WFDATATRIM NVARCHAR(180)
	SET @WFDATATRIM = TRIM(@WFDATA)

	DECLARE @spaceteb INT
	,@wf_idx INT
	,@qty INT

	WHILE LEN(@WFDATATRIM) > 0
	BEGIN

		SET @spaceteb =  CHARINDEX(' ',@WFDATATRIM);

		IF @spaceteb = 0
			BREAK;

		--get idx
		SET @wf_idx = CAST(SUBSTRING(@WFDATATRIM, 1, @spaceteb - 1) AS INT);

		--remove idx
		SET @WFDATATRIM = LTRIM(SUBSTRING(@WFDATATRIM, @spaceteb + 1, LEN(@WFDATATRIM)));

		SET @spaceteb =  CHARINDEX(' ',@WFDATATRIM);

		IF @spaceteb = 0
			SET @spaceteb = LEN(@WFDATATRIM) + 1 ;

		--get qty
		SET @qty = CAST(SUBSTRING(@WFDATATRIM, 1,@spaceteb) AS INT)

		--remove qty
		SET @WFDATATRIM = LTRIM(SUBSTRING(@WFDATATRIM, @spaceteb, LEN(@WFDATATRIM)));

		--Insert @Output
		INSERT INTO @Output (IDx ,Qty)
		VALUES (@wf_idx ,@qty)

	END
	RETURN 
END

