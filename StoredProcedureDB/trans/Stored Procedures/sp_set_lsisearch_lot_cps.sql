-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [trans].[sp_set_lsisearch_lot_cps]
	-- Add the parameters for the stored procedure here
		  @LotNo      NVARCHAR(100)
		, @status     NVARCHAR(100)
		, @CPS_State  NVARCHAR(100)
		, @OPNO		  NVARCHAR(100)
		, @State      INT
AS
BEGIN 
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	BEGIN TRY
		BEGIN TRANSACTION;

					IF (@State IN (0,1)) 
					BEGIN 

								IF (@State = 0 )
								BEGIN
											UPDATE [dbx].[dbo].[OGIData] 
											SET CPS_State = @CPS_State 
											,OPNo = @OPNO
											WHERE LotNo = @LotNo​ 			 
								END
								ELSE IF (@State = 1 )
								BEGIN
											UPDATE [dbx].[dbo].[OGIData] 
											SET CPS_State = 0 
											,OPNo = @OPNO
											WHERE LotNo = @LotNo​ 
								END		

								SELECT  'TRUE'						AS Is_Pass
										,'Update data success !!'	AS Error_Message_ENG
										,N'แก้ไขข้อมูลสำเร็จ !!'			AS Error_Message_THA
										,N''						AS Handling 
								RETURN
							 

					END 
					ELSE IF (@State = 2)
					BEGIN

								UPDATE [dbx].[dbo].[OGIData] 
								SET CPS_State = 1 
								,OPNo = @OPNO
								WHERE LotNo = @LotNo​

								SELECT  'TRUE'						AS Is_Pass
										,'Update data success !!'	AS Error_Message_ENG
										,N'แก้ไขข้อมูลสำเร็จ !!'			AS Error_Message_THA
										,N''						AS Handling 
								RETURN
							  
					END
					ELSE IF (@State = 3)
					BEGIN
								UPDATE [dbx].[dbo].[OGIData] 
								SET CPS_State = 0 
								,OPNo = @OPNO
								WHERE LotNo = @LotNo​

								EXEC [StoredProcedureDB].[dbo].[sp_set_data_cps_lsiweb] 
											@lotno		= @LotNo
										,@status	= 1​

								SELECT  'TRUE'						AS Is_Pass
										,'Update data success !!'	AS Error_Message_ENG
										,N'แก้ไขข้อมูลสำเร็จ !!'			AS Error_Message_THA
										,N''						AS Handling 
								RETURN

					END
			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
			ROLLBACK TRANSACTION;
	END CATCH;
END
