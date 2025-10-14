-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_shipment] 
	-- Add the parameters for the stored procedure here
	@MCNo varchar(30) 
	, @LotNo varchar(10) 
	, @OPNo varchar(7)
	, @TotalGood int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @ProductCode varchar(15)

	-- Start Check @ProductCode
	--IF(exists (SELECT TOP 1 CASE WHEN FORWADING_BUNRUI = 'OVER SEAS' THEN 'OVERSEA' ELSE FORWADING_BUNRUI END
	--					FROM APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT
	--					WHERE LOT_NO_1 = @LotNo))
	--	BEGIN
	--		SET @ProductCode = (SELECT TOP 1 CASE WHEN FORWADING_BUNRUI = 'OVER SEAS' THEN 'OVERSEA' ELSE FORWADING_BUNRUI END
	--						FROM APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT
	--						WHERE LOT_NO_1 = @LotNo)
	--	END
	--ELSE
	--	BEGIN
	--		IF(exists (SELECT TOP 1 CASE WHEN pdcd = 'QI000' THEN 'OVERSEA' 
	--					WHEN pdcd = 'QI001' THEN 'JAPAN' ELSE '' END
	--					FROM APCSProDB.trans.surpluses
	--					WHERE serial_no = @LotNo))
	--			BEGIN
	--				SET @ProductCode = (SELECT TOP 1 CASE WHEN pdcd = 'QI000' THEN 'OVERSEA' 
	--									WHEN pdcd = 'QI001' THEN 'JAPAN' ELSE '' END
	--									FROM APCSProDB.trans.surpluses
	--									WHERE serial_no = @LotNo)
	--			END
	--		ELSE
	--			BEGIN
	--				SET @ProductCode = ''
	--			END
	--	END
	---- End Check @ProductCode

	--SET @OPNo = (case 
	--			when LEN(CAST(@OPNo as varchar(7))) = 5 then '0' + CAST(@OPNo as char(5))
	--			when LEN(CAST(@OPNo as varchar(7))) = 4 then '00' + CAST(@OPNo as char(5))
	--			when LEN(CAST(@OPNo as varchar(7))) = 3 then '000' + CAST(@OPNo as char(5))
	--			when LEN(CAST(@OPNo as varchar(7))) = 2 then '0000' + CAST(@OPNo as char(5))
	--			when LEN(CAST(@OPNo as varchar(7))) = 1 then '00000' + CAST(@OPNo as char(5))
	--			else CAST(@OPNo as varchar(7)) 
	--		end)

    --Insert statements for procedure here
	--BEGIN TRANSACTION
		BEGIN TRY
			--OP NO
			SET @OPNo = (case 
				when LEN(CAST(@OPNo as varchar(7))) = 5 then '0' + CAST(@OPNo as char(5))
				when LEN(CAST(@OPNo as varchar(7))) = 4 then '00' + CAST(@OPNo as char(5))
				when LEN(CAST(@OPNo as varchar(7))) = 3 then '000' + CAST(@OPNo as char(5))
				when LEN(CAST(@OPNo as varchar(7))) = 2 then '0000' + CAST(@OPNo as char(5))
				when LEN(CAST(@OPNo as varchar(7))) = 1 then '00000' + CAST(@OPNo as char(5))
				else CAST(@OPNo as varchar(7)) 
			end)

			--Find PDCD
			IF(exists (SELECT TOP 1 CASE WHEN pdcd = 'QI000' THEN 'OVERSEA' 
						WHEN pdcd = 'QI001' THEN 'JAPAN' ELSE '' END
						FROM [APCSProDB].[trans].[surpluses] 
						WHERE serial_no = @LotNo))
				BEGIN
					SET @ProductCode = (SELECT TOP 1 CASE WHEN [surpluses].[pdcd] = 'QI000' THEN 'OVERSEA' 
										WHEN [surpluses].[pdcd] = 'QI001' THEN 'JAPAN' ELSE '' END
										FROM [APCSProDB].[trans].[surpluses]
										WHERE [surpluses].[serial_no] = @LotNo)
				END
			ELSE
				BEGIN
					SET @ProductCode = ''
				END
			-- END Find PDCD

			INSERT INTO [DBx].[dbo].[OGIData] ([MCNo]
			  ,[LotNo]
			  ,[LotStartTime]
			  ,[OPNo]
			  ,[InputQty]
			  ,[LotEndTime]
			  ,[TomSon]
			  ,[ProductCode]
			  ,[SelfConVersion]
			  ,[NetVersion]
			  ,[TotalGood]
			  ,[TotalNG]
			  ,[Remark1]
			  ,[Remark2]
			  ,[ReelCount]
			  ,[TomsonCount]
			  ,[CPS_State])	
			VALUES (@MCNo
			  ,@LotNo
			  ,GETDATE()
			  ,@OPNo
			  ,@TotalGood
			  ,GETDATE()
			  ,NULL
			  ,@ProductCode
			  ,NULL
			  ,NULL
			  ,@TotalGood
			  ,0
			  ,NULL
			  ,NULL
			  ,0
			  ,NULL
			  ,1
			);

			SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA
			--COMMIT; 
		END TRY

		BEGIN CATCH
			--ROLLBACK;
			SELECT 'FALSE' AS Is_Pass ,'Insert fail. !!' AS Error_Message_ENG,N'บันทึกผิดพลาด !!' AS Error_Message_THA

			--SEND MAIL
			--DECLARE @Body NVARCHAR(MAX)
			--DECLARE @TableHead VARCHAR(1000)
			--DECLARE @TableTail VARCHAR(1000)

			--SET @TableHead = '<html><head>' + '<style>'
			--	+ 'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
			--	+ '</style>' + '</head>' + '<body>' + 'ON : ' + CONVERT(varchar, GETDATE(), 120)
			--	+ ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
			--	+ '<tr><td bgcolor=#E6E6FA><b>ErrorNumber</b></td>'
			--	+ '<td bgcolor=#E6E6FA><b>ErrorSeverity</b></td>'
			--	+ '<td bgcolor=#E6E6FA><b>ErrorState</b></td>'
			--	+ '<td bgcolor=#E6E6FA><b>ErrorProcedure</b></td>'
			--	+ '<td bgcolor=#E6E6FA><b>ErrorMessage</b></td></tr>';
			--SET @Body = '<tr><td><b>' + CONVERT(varchar, ERROR_NUMBER()) + '</b></td>'
			--	+ '<tr><td><b>' + CONVERT(varchar, ERROR_SEVERITY()) + '</b></td>'
			--	+ '<tr><td><b>' + CONVERT(varchar, ERROR_STATE()) + '</b></td>'
			--	+ '<tr><td><b>' + CONVERT(varchar, ERROR_PROCEDURE()) + '</b></td>'
			--	+ '<td><b>' + CONVERT(varchar, ERROR_MESSAGE()) + '</b></td></tr>';
			--SET @TableTail = '</table></body></html>';
			--SET  @Body = @TableHead + ISNULL(@Body, '') + @TableTail;

			--EXEC msdb.dbo.sp_send_dbmail
			--	@profile_name ='RIST'
			--	, @recipients = 'LSI_Database_Admin@rist.local'
			--	, @subject = 'ERROR OGIData'
			--	, @body = @Body
			--	, @body_format = 'HTML';
			--END SEND MAIL
		END CATCH


END
