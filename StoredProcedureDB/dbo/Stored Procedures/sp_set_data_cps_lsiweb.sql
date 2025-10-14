-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_data_cps_lsiweb]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
	,@status int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--DECLARE @lot_type varchar(1)

	-- Insert statements for procedure here
	IF (@status = 1 AND @lotno != '')
		BEGIN
			--<<< INSERT DATA TO MLI02_LSI
			BEGIN TRY
				--close #2025/01/13 time : 14.25
				--if not exists(select 1 from [APCSProDB].[trans].[mli02_lsi] where LOTN = @lotno)
				--begin
				--	EXEC [StoredProcedureDB].[dbo].[sp_set_data_cps] @lotno = @lotno
				--end

				--SET @lot_type = (SELECT SUBSTRING(TRIM(@lotno),5,1))
				--INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[MLI02_LSI](
				--	[NYKP]
				--	,[MSGS]
				--	,[BSIJD]
				--	,[SHGM]
				--	,[KEIJ]
				--	,[SOFS]
				--	,[HKNK]
				--	,[LOCT]
				--	,[TOKI]
				--	,[TOKI2]
				--	,[KGSS]
				--	,[KGBS]
				--	,[HASM]
				--	,[SMGS]
				--	,[TKEM]
				--	,[NKYS]
				--	,[TMSS]
				--	,[SZON]
				--	,[LOTN]
				--	,[INVN]
				--	,[NYKD]
				--	,[NYID]
				--	,[BRKC]
				--	,[FG01]
				--	,[FG02]
				--	,[FG03]
				--	,[FG04]
				--	,[FG05]
				--	,[TR_FLG]
				--)
				----UPDATE 10 Nov 2021
				--SELECT [NYKP]
				--	,[MSGS]
				--	,[BSIJD]
				--	,[SHGM]
				--	,[KEIJ]
				--	,[SOFS]
				--	,[HKNK]
				--	,[LOCT]
				--	,[TOKI]
				--	,[TOKI2]
				--	,[KGSS]
				--	,[KGBS]
				--	,[HASM]
				--	,[SMGS]
				--	,[TKEM]
				--	,[NKYS]
				--	,[TMSS]
				--	,[SZON]
				--	,[LOTN]
				--	,[INVN]
				--	,[NYKD]
				--	,[NYID]
				--	,[BRKC]
				--	,[FG01]
				--	,[FG02]
				--	,[FG03]
				--	,[FG04]
				--	,[FG05]
				--	,[TR_FLG]
				--  FROM [APCSProDB].[trans].[mli02_lsi]
				--  WHERE LOTN = @lotno

				--SET DATA MLIO2 update #2025/01/13 time : 14.25
				DECLARE @count_rec_mli02 INT = NULL;
				SELECT @count_rec_mli02 = COUNT([LOTN]) 
				FROM [APCSProDB].[trans].[mli02_lsi] 
				WHERE [LOTN] = @lotno;

				IF (@count_rec_mli02 IS NOT NULL)
				BEGIN
					IF (@count_rec_mli02 = 0)
					BEGIN
						--SET DATA MLI02
						EXEC [StoredProcedureDB].[dbo].[sp_set_data_cps_new] @lotno = @lotno;
					END
					ELSE
					BEGIN
						--DELETE DATA MLI02
						DELETE [APCSProDB].[trans].[mli02_lsi] WHERE [LOTN] = @lotno;
						--SET DATA MLI02
						EXEC [StoredProcedureDB].[dbo].[sp_set_data_cps_new] @lotno = @lotno;
					END
				END

				--UPDATE FLG OGIData
				UPDATE [dbx].[dbo].[OGIData] SET CPS_State = 0 WHERE LotNo = @lotno;
				--UPDATE FLG mli02_lsi
				--UPDATE [APCSProDB].[trans].[mli02_lsi] SET [import_flg] = 1 WHERE LOTN = @lotno;

				SELECT 'TRUE' AS [status] ,' INSERT TO MLI02_LSI SUCCESS !!' AS [Error_Message_ENG],N' เพิ่มข้อมูลสำเร็จ' AS [Error_Message_THA] ,N'' AS Handling
			END TRY
			BEGIN CATCH
				SELECT 'FALSE' AS [status] ,' INSERT TO MLI02_LSI ERROR !!' AS [Error_Message_ENG],N' มีปัญหาในการเพิ่มข้อมูล' AS [Error_Message_THA] ,N' กรุณาติดต่อ System' AS Handling
			END CATCH
			-->>> INSERT DATA TO MLI02_LSI
		END
	ELSE
		BEGIN
			SELECT 'FALSE' AS [status] ,' ERROR !!' AS [Error_Message_ENG],N' ข้อมูลที่ส่งมาไม่ถูกต้อง' AS [Error_Message_THA] ,N' กรุณาติดต่อ System' AS Handling
		END

END
