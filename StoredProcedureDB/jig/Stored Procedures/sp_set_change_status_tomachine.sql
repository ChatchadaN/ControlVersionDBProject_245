-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_change_status_tomachine] 
	-- Add the parameters for the stored procedure here
	@QRCode VARCHAR(100),
	@OPNo VARCHAR(6) = '0'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @JIGID AS INT = 0
	,@OPID AS INT

    -- Insert statements for procedure here
	IF NOT EXISTS(SELECT id FROM APCSProDB.trans.jigs WHERE 
	barcode = @QRCode 
	or TRIM(qrcodebyuser) = TRIM(@QRCode) 
	or smallcode = @QRCode
	) BEGIN
		SELECT 'False' AS Is_Pass,'This JIG is not Register !!' AS Is_Message
		RETURN
	END

	SET @JIGID = (SELECT id FROM APCSProDB.trans.jigs WHERE 
	barcode = @QRCode 
	or TRIM(qrcodebyuser) = TRIM(@QRCode) 
	or smallcode = @QRCode
	)

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

	IF (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIGID) = 'On Machine' BEGIN		
		UPDATE APCSProDB.trans.jigs SET status = 'To Machine',[jig_state] = 11,updated_at = GETDATE(),updated_by = @OPID WHERE id = @JIGID 

		IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIGID) BEGIN
			--UPDATE APCSProDB.trans.machine_jigs SET jig_id = 0,updated_at = GETDATE(),updated_by = @OPNo WHERE jig_id = @JIGID
			DELETE FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIGID
		END

		SELECT 'True' AS Is_Pass,status AS Is_Status FROM APCSProDB.trans.jigs WHERE id = @JIGID
	END
	ELSE Begin
		SELECT 'False' AS Is_Pass,'This JIG status is not on machine !!' AS Error_Message_ENG,N'JIG นี้ ('+ @QRCode + N') สถานะไม่ได้อยู่ในเครื่องจักร !!' AS Error_Message_THA
	END

END
