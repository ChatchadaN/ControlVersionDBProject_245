-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_wfdata_chipbank_001] 
	-- Add the parameters for the stored procedure here

	@OPNo				NVARCHAR(20)			
	, @App_Name			NVARCHAR(20)
	, @WFLOTNO			NVARCHAR(20)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	----------------------------------------------------------------------
    -- Insert statements for procedure here
	BEGIN TRY
		DECLARE @LOTNO NVARCHAR(20),
				@INVOICE_NO NVARCHAR(50),
				@CHIPMODELNAME NVARCHAR(50)

		IF EXISTS(SELECT 1 FROM APCSProDB.trans.materials WHERE lot_no = @WFLOTNO)
		BEGIN
			SELECT @LOTNO = lot_no,
				   @INVOICE_NO = mat_ar.invoice_no,
				   @CHIPMODELNAME = wf_details.chip_model_name
			FROM APCSProDB.trans.materials
			INNER JOIN APCSProDB.trans.material_arrival_records mat_ar 
				ON materials.arrival_material_id = mat_ar.id
			INNER JOIN APCSProDB.trans.wf_details 
				ON materials.id = wf_details.material_id
			WHERE lot_no = @WFLOTNO

			SELECT 'TRUE' AS Is_Pass,
				   'Data found successfully !!' AS Error_Message_ENG,
				   N'ค้นหาข้อมูลสำเร็จ !!' AS Error_Message_THA,
				   '' AS Handling,
				   @LOTNO AS WFLOTNO,
				   @INVOICE_NO AS INVOICE_NO,
				   @CHIPMODELNAME AS CHIPMODELNAME

			RETURN;
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Is_Pass,
				   'WFLOTNO data not found' AS Error_Message_ENG,
				   N'ไม่พบข้อมูล WFLOTNO !!' AS Error_Message_THA,
				   '' AS Handling,
				   '' AS WFLOTNO,
				   '' AS INVOICE_NO,
				   '' AS CHIPMODELNAME
			RETURN;

		END
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass,
				ERROR_MESSAGE() AS Error_Message_ENG,
				N'เกิดข้อผิดพลาด !!' AS Error_Message_THA,
				'' AS Handling,
			    '' AS WFLOTNO,
				'' AS INVOICE_NO,
				'' AS CHIPMODELNAME
		RETURN;
	END CATCH

END
