-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[bm_set_data_RequestBM]
	-- Add the parameters for the stored procedure here
	@Lot_No varchar(20),
	@Machine_Name varchar(20),
	@Process varchar(5),
	--@Line varchar(5),
	@Package varchar(20),
	@Device varchar(20),
	@OPNo int,
	@problem varchar(100)


	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Check_Record int = 0;
	DECLARE @problem_Code varchar(15);
	DECLARE @chkUSABLE  varchar(10) = 'false';
	

	 -- Insert statements for procedure here
	BEGIN TRY
	BEGIN TRANSACTION

		--BEGIN Insert To Database
			select top(1) @Check_Record =  [ID]+1 from [DBx].[dbo].[BMMaintenance]  order by id desc

			select top(1) @problem_Code = [val] from  [DBx].[BM].[item_labels] where name='BMMaintenance.problem' and label_eng = @problem

			INSERT INTO [DBx].[dbo].[BMMaintenance]
            (ID,MachineID,PMID,LotNo,Requestor,StatusID,TimeRequest,Package,Device,ProcessID,AQI,MCStatus,problem,Undon)
			VALUES
				   (@Check_Record,@Machine_Name,5,@Lot_No,@OPNo,1,GETDATE(),@Package,@Device,@Process,'No','Stop',@problem_Code,'No')

			INSERT INTO [DBx].[dbo].[BMPM6Detail] 
			   (BM_ID,WhereRequest)
			VALUES
			   (@Check_Record,'001')
		
		--END

		SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'Request OK' AS Error_Message_THA, N'บันทึกข้อมูลสำเร็จ' AS Handling,@Check_Record As BMID
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Request fail. !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาติดต่อ System' AS Handling
	END CATCH

END