-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_regis_rack_setting]
	-- Add the parameters for the stored procedure here
	@setting_list [dbo].[rcs_rack_setting] readonly
	, @created_by INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
			DECLARE @rack_setting_tb TABLE
			(
				rack_id INT
				, rack_set_id INT
			)

			INSERT INTO @rack_setting_tb
			(rack_id,rack_set_id)
			SELECT [rack_id], [rack_set_id] FROM @setting_list
			
			INSERT INTO APCSProDB.rcs.rack_settings
			(rack_id, rack_set_id,[priority],created_at,created_by)
			SELECT t.rack_id
				, t.rack_set_id
				, ISNULL(s.max_priority, 0) + 1
				, GETDATE()
				, @created_by 
			FROM @rack_setting_tb as t
			LEFT JOIN ( 
				SELECT rack_set_id
				,MAX([priority]) as max_priority
				FROM APCSProDB.rcs.rack_settings
				GROUP BY rack_set_id
			) as s
			ON t.rack_set_id = s.rack_set_id
			WHERE NOT EXISTS 
			(SELECT 1 FROM APCSProDB.rcs.rack_settings rs
			WHERE rs.rack_id = t.rack_id 
			AND rs.rack_set_id = t.rack_set_id)

			SELECT 'TRUE' AS Is_Pass 
				,'Register Successfully !!' AS Error_Message_ENG
				,N'การลงทะเบียนสำเร็จ !!' AS Error_Message_THA	
				,N'' AS Headlind
			COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,ERROR_MESSAGE() AS Error_Message_ENG
		,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
		,N'Please check the data !!' AS Headlind
	END CATCH
END
