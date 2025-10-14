-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_check_lot]
	-- Add the parameters for the stored procedure here
	@lot_no		NVARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



	IF EXISTS (	SELECT  'xx'  FROM APCSProDB.trans.lots 
				WHERE lot_no = @lot_no)
				BEGIN


				SELECT  'TRUE' AS Is_Pass
			 

	END
	ELSE
	BEGIN 

		SELECT  'FALSE' AS Is_Pass

	END 
		 
 
END
