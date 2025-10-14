
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_lots_mark_no_001]	-- Add the parameters for the stored procedure here	
	@lot_no VARCHAR(10)
	, @mark_no VARCHAR(50)
    , @is_update INT  -- 0:INSERT, 1:UPDATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	IF (@is_update = 0 ) -- INSERT
	BEGIN
		IF NOT EXISTS(SELECT [lot_no] FROM [APIStoredProDB].[dbo].[lot_masks] WHERE [lot_no] = @lot_no)
		BEGIN
			INSERT INTO [APIStoredProDB].[dbo].[lot_masks]
				( [lot_no]
				, [mno] )
			VALUES
				( @lot_no
				, @mark_no );

			SELECT 'TRUE' AS Is_Pass 
				, 'Insert Success !!' AS Error_Message_ENG
				, N'บันทึกข้อมูลสำเร็จ !!' AS Error_Message_THA 
				, N'' AS Handling;
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Is_Pass 
				, 'Insert fail !!' AS Error_Message_ENG
				, N'บันทึกข้อมูลไม่สำเร็จ !!' AS Error_Message_THA 
				, N'กรุณาติดต่อผู้ดูแลระบบ' AS Handling;
		END
	END
	ELSE IF (@is_update = 1 ) -- UPDATE
	BEGIN
		UPDATE APIStoredProDB.dbo.lot_masks
		SET mno = @mark_no
		WHERE lot_no = @lot_no;
		
		SELECT 'TRUE' AS Is_Pass 
			, 'Update Success !!' AS Error_Message_ENG
			, N'บันทึกข้อมูลสำเร็จ !!' AS Error_Message_THA 
			, N'' AS Handling;
	END
END
