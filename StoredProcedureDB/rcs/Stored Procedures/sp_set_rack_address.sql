-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_rack_address]
	-- Add the parameters for the stored procedure here
	@Address_id INT
	,@is_enable INT
	,@update_by INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @item VARCHAR(50)

	SELECT @item = item FROM APCSProDB.rcs.rack_addresses
	WHERE id = @Address_id

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		
		IF @item IS NULL
		BEGIN
			Print 'Disable/Enable'

			UPDATE APCSProDB.rcs.rack_addresses 
			SET is_enable = @is_enable
			, updated_at = GETDATE()
			, updated_by = @update_by
			WHERE id = @Address_id

			INSERT INTO [APCSProDB].[rcs].[rack_address_records]
			SELECT 
				GETDATE()
				,'2'
				,[id]
				,[rack_control_id]
				,[item]
				,[status]
				,[address]
				,[x]
				,[y]
				,[z]
				,[is_enable]
				,[created_at]
				,[created_by]
				,[updated_at]
				,[updated_by]
			FROM APCSProDB.rcs.rack_addresses 
			WHERE [rack_addresses].[id] = @Address_id;

			SELECT 'TRUE' AS Is_Pass 
			,'Update Data successfully !!' AS Error_Message_ENG
			, N'อัพเดทข้อมูลสำเร็จ !!' AS Error_Message_THA	
			, N'' AS [Handling];
			COMMIT;
		END
		ELSE
		BEGIN
			Print 'Clear item'
			SELECT 'FALSE' AS [Is_Pass] 
			, CONCAT('Cannot Update Data. Please remove item : ', @item) AS [Error_Message_ENG]
			, CONCAT(N'ไม่สามารถอัปเดตได้ กรุณาลบ item : ', @item ) AS [Error_Message_THA]
			, N'กรุณาติดต่อ System' AS [Handling];	
			RETURN;
		END

	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,ERROR_MESSAGE() AS Error_Message_ENG
		,N'Please check the data !!' AS Error_Message_THA
		,N'' AS Headlind
	END CATCH
END
