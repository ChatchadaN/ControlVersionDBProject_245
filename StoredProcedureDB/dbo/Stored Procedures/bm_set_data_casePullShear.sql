-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[bm_set_data_casePullShear]
	-- Add the parameters for the stored procedure here
	@Lot_No varchar(20),
	@Machine_ID varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Check_Record int = 0;
	DECLARE @BM_ID int = 0;
	DECLARE @LotNo varchar(20) = '';
	DECLARE @MachineID varchar(20) = '';
	DECLARE @ProcessID varchar(20) = '';
	DECLARE @CategoryID int = 0;
	DECLARE @StatusID int = 0;
	DECLARE @TreatmentContent1 varchar(20) = '';

    -- Insert statements for procedure here
	BEGIN TRY
	BEGIN TRANSACTION
	SELECT @BM_ID = [BMMaintenance].[ID]
		  ,@LotNo = [BMMaintenance].[LotNo]
		  ,@MachineID = [MachineID]
		  ,@ProcessID = [ProcessID]
		  ,@CategoryID = [CategoryID]
		  ,@StatusID = [StatusID]
		  ,@TreatmentContent1 = [BMPM6Detail].[TreatmentContent1]
	  FROM [DBx].[dbo].[BMMaintenance]
	  inner join [DBx].[dbo].[BMPM6Detail] on BMPM6Detail.BM_ID = [BMMaintenance].id
	  where StatusID = 2 and CategoryID = 16 and LotNo = @Lot_No and MachineID = @Machine_ID 

	  select @Check_Record = COUNT(*) from [DBx].[dbo].[BMMaintenance]
	  where StatusID = 2 and CategoryID = 16 and MachineID = @MachineID and LotNo = @LotNo

	  IF @Check_Record != 0
		BEGIN
			UPDATE [DBx].[dbo].[BMPM6Detail]
			SET TreatmentContent1 = 'Manual End Shear'
			WHERE BM_ID = @BM_ID;
		END

		 SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA, N'' AS Handling
		COMMIT; 
	END TRY

	BEGIN CATCH
			ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Update fail. !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาติดต่อ System' AS Handling
	END CATCH

END
