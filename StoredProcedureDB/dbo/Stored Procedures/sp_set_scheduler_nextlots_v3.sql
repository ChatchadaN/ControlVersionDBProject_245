-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_nextlots_v3]
	-- Add the parameters for the stored procedure here
	--@McName  VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

BEGIN TRANSACTION
BEGIN TRY

	CREATE TABLE #tempNextLot
(
   RowIndex int,LotID int,LotNo varchar(10),McID int,MCName varchar(20),PackageName varchar(30)
)
CREATE TABLE #GetNextLot
(
   LotID int,LotNo varchar(10),McID int,MCName varchar(20),PackageName varchar(30)
)

INSERT INTO #GetNextLot
SELECT lots.id as id, temp.lot_no as lotno,mc.id as mcid, temp.machine_name as mcname ,temp.package_name
FROM DBxDW.dbo.scheduler_temp as temp
INNER JOIN APCSProDB.trans.lots as lots on lots.lot_no = temp.lot_no collate SQL_Latin1_General_CP1_CI_AS
INNER JOIN APCSProDB.mc.machines as mc on mc.name = temp.machine_name collate SQL_Latin1_General_CP1_CI_AS
where seq_no = 2 
UNION ALL
SELECT lots.id as id, temp.lot_no as lotno,mc.id as mcid, temp.machine_name as mcname ,temp.package_name
FROM DBxDW.dbo.scheduler_temp_seq_tp as temp
INNER JOIN APCSProDB.trans.lots as lots on lots.lot_no = temp.lot_no collate SQL_Latin1_General_CP1_CI_AS
LEFT JOIN APCSProDB.mc.machines as mc on mc.name = temp.machine_name collate SQL_Latin1_General_CP1_CI_AS
where seq_no = 2 


INSERT INTO #tempNextLot
SELECT ROW_NUMBER() OVER(ORDER BY McID ASC),* FROM #GetNextLot

DECLARE @Loop int = 1

--IF((select MAX(RowIndex) from  #tempNextLot) = 0)BEGIN
				
--				UPDATE [APCSProDB].[trans].[machine_states]
--					 SET [next_lot_id] = null
--					 WHERE machine_id in (SELECT * FROM string_split(@MCName,','))
--END


WHILE @Loop <= (select MAX(RowIndex) from  #tempNextLot)
	Begin
		IF EXISTS ( (SELECT MCName FROM #tempNextLot WHERE McID = (SELECT McID FROM #tempNextLot where RowIndex = @Loop)))
		BEGIN
		DECLARE @mc_id int = (SELECT McID FROM #tempNextLot WHERE McID = (SELECT McID FROM #tempNextLot where RowIndex = @Loop)) 
		DECLARE @nextlot_id int = (SELECT next_lot_id FROM APCSProDB.trans.machine_states WHERE machine_id = @mc_id)

		DECLARE @lot_setup varchar(10) = (SELECT LotNo FROM DBx.dbo.FTSetupReport WHERE MCNo = (SELECT MCName FROM #tempNextLot where RowIndex = @Loop))

			IF (@nextlot_id is null)
				BEGIN
					IF((SELECT LotID FROM #tempNextLot where RowIndex = @Loop) is null)
						BEGIN
							 UPDATE [APCSProDB].[trans].[machine_states]
							 SET [next_lot_id] = null
							 WHERE machine_id = @mc_id
					END
					ELSE
						BEGIN
							 UPDATE [APCSProDB].[trans].[machine_states]
							 SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop)
							 WHERE machine_id = @mc_id
					 END
				END
			
			ELSE -- next lot is not null
				BEGIN
					IF NOT EXISTS((SELECT LotNo FROM DBx.dbo.FTSetupReport WHERE MCNo = (SELECT MCName FROM #tempNextLot where RowIndex = @Loop))) 					
					OR ((SELECT LotNo FROM DBx.dbo.FTSetupReport WHERE MCNo = (SELECT MCName FROM #tempNextLot where RowIndex = @Loop))) IS NULL --ไม่มี Check Sheet Update by อั๋น 2023/08/01

						BEGIN
							SELECT LotID FROM #tempNextLot where RowIndex = @Loop
							IF((SELECT is_special_flow FROM APCSProDB.trans.lots WHERE id = @nextlot_id) = 0) -- Not Special Flow
								BEGIN
									IF((SELECT process_state FROM APCSProDB.trans.lots WHERE id = @nextlot_id) not in (1,101))
										BEGIN
										--SELECT 1 as notsetup
											IF((SELECT LotID FROM #tempNextLot where RowIndex = @Loop) is null)
												BEGIN
												UPDATE [APCSProDB].[trans].[machine_states]
												 SET [next_lot_id] = null
												 WHERE machine_id = @mc_id
											END
											ELSE
												BEGIN
												UPDATE [APCSProDB].[trans].[machine_states]
												 SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop)
												 WHERE machine_id = @mc_id
											 END
										END
								END
							ELSE
							BEGIN  -- Special Flow
								IF((SELECT special.process_state FROM APCSProDB.trans.lots 
									inner join APCSProDB.trans.special_flows as special on special.lot_id = [APCSProDB].[trans].[lots].id and [APCSProDB].[trans].[lots].special_flow_id = special.id
									inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
									WHERE APCSProDB.trans.lots.id = @nextlot_id) not in (1,101))
									BEGIN
					
										IF((SELECT LotID FROM #tempNextLot where RowIndex = @Loop) is null)
											BEGIN
											UPDATE [APCSProDB].[trans].[machine_states]
											 SET [next_lot_id] = null
											 WHERE machine_id = @mc_id
										END
										ELSE
											BEGIN
											UPDATE [APCSProDB].[trans].[machine_states]
											 SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop)
											 WHERE machine_id = @mc_id
									    END
								END
							END
						END
					
					ELSE
						BEGIN
						IF((SELECT is_special_flow FROM APCSProDB.trans.lots WHERE id = @nextlot_id) = 0) -- Not Special Flow
							BEGIN
								--	IF((SELECT id FROM APCSProDB.trans.lots WHERE lot_no = @lot_setup) <> @nextlot_id)
								--BEGIN
									IF((SELECT process_state FROM APCSProDB.trans.lots WHERE id = @nextlot_id) not in (1,101))
										BEGIN
										
												IF((SELECT LotID FROM #tempNextLot where RowIndex = @Loop) is null)
													BEGIN
														UPDATE [APCSProDB].[trans].[machine_states]
														 SET [next_lot_id] = null
														 WHERE machine_id = @mc_id
												END
												ELSE
													BEGIN
														UPDATE [APCSProDB].[trans].[machine_states]
														 SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop)
														 WHERE machine_id = @mc_id
												END
											END
										--END
							END
						ELSE  -- Special Flow
							BEGIN
							--IF((SELECT id FROM APCSProDB.trans.lots WHERE lot_no = @lot_setup) <> @nextlot_id)
							--	BEGIN
									IF((SELECT special.process_state FROM APCSProDB.trans.lots 
										inner join APCSProDB.trans.special_flows as special with (NOLOCK) on lots.special_flow_id = special.id
										inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
										WHERE APCSProDB.trans.lots.id = @nextlot_id) not in (1,101))
										BEGIN
										IF((SELECT lotspecial.job_id FROM APCSProDB.trans.lots 
											inner join APCSProDB.trans.special_flows as special with (NOLOCK) on lots.special_flow_id = special.id
											inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
											WHERE APCSProDB.trans.lots.id = @nextlot_id) not in (378,365,366,367,385)) -- Flow not plan
											BEGIN
												IF((SELECT LotID FROM #tempNextLot where RowIndex = @Loop) is null)
													BEGIN
														UPDATE [APCSProDB].[trans].[machine_states]
														 SET [next_lot_id] = null
														 WHERE machine_id = @mc_id
												END
												ELSE
													BEGIN
														UPDATE [APCSProDB].[trans].[machine_states]
														 SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop)
														 WHERE machine_id = @mc_id
												END
											END
										END
								--END
							END
						END
				END			
		END
		SET @Loop = @Loop+1
	End

	Drop table #tempNextLot
	Drop table #GetNextLot
	COMMIT;
END TRY
BEGIN CATCH
	PRINT '---> Error <----' +  ERROR_MESSAGE() + '---> Error <----'; 
	ROLLBACK;
END CATCH
END
