-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_nextlots_v1]
	-- Add the parameters for the stored procedure here
	--@McName  VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
DECLARE @MCName varchar(MAX)
--SET @MCName = 'TP-TP-59,TP-TP-60,TP-TP-61,FT-RAS-001,FT-RAS-002,FT-RAS-004,FT-RAS-005,FT-RAS-006,FT-IFZ-014,FT-IFZ-020,FT-IFZ-013,FT-IFZ-034,FT-IFZ-006,FT-IFZ-013,FT-IFZ-025,FT-IFZ-029,FT-IFZ-032,FT-IFZ-011,FT-IFZ-012,FT-IFZ-019,FT-IFZ-031,FT-IFZ-024,FT-IFZ-033,FT-IFZ-035,FT-IFZ-001,FT-IFZ-017,FT-IFZ-018'--,TP-TP-09,TP-TP-14,TP-TP-18,TP-TP-44'--'FT-MT-001,FT-IFZ-030,FT-IFZ-008'
--SET @MCName = 'TP-TP-61,TP-TP-59,TP-TP-62,TP-TP-63,TP-TP-60,TP-TP-47,TP-TP-51,TP-TP-50,TP-TP-46,TP-TP-48,TP-FTTP-01,TP-FTTP-02,TP-TP-09,TP-TP-14,TP-TP-18,TP-TP-44,TP-TP-04,TP-TP-01,TP-TP-38,TP-TP-24,TP-TP-43,TP-TP-36,TP-TP-15,TP-TP-27,TP-TP-19,TP-TP-17,TP-TP-29,TP-TP-21,TP-TP-22,TP-TP-37,FT-RAS-001,FT-RAS-002,FT-RAS-004,FT-RAS-005,FT-RAS-006,FT-IFZ-014,FT-IFZ-020,FT-IFZ-013,FT-IFZ-034,FT-IFZ-006,FT-IFZ-013,FT-IFZ-025,FT-IFZ-029,FT-IFZ-032,FT-IFZ-011,FT-IFZ-012,FT-IFZ-019,FT-IFZ-031,FT-IFZ-024,FT-IFZ-033,FT-IFZ-035,FT-IFZ-001,FT-IFZ-017,FT-IFZ-018'--,TP-TP-09,TP-TP-14,TP-TP-18,TP-TP-44'--'FT-MT-001,FT-IFZ-030,FT-IFZ-008'
SET @MCName = 'TP-TP-68,TP-TP-61,TP-TP-59,TP-TP-62,TP-TP-63,TP-TP-60,TP-TP-47,TP-TP-51,TP-TP-46'
			SET @MCName += ',TP-TP-48,TP-TP-04,TP-TP-43,TP-TP-36,TP-TP-65,TP-TP-57'

			SET @MCName += ',TP-TP-01,TP-TP-50,TP-TP-69,TP-TP-73,TP-TP-09,TP-TP-14,TP-TP-18,TP-TP-44,TP-TP-37,TP-TP-21,TP-TP-22'  --TP 2F 2023/09/13
			SET @MCName += ',TP-TP-74,TP-TP-24,TP-TP-38,TP-TP-06,TP-TP-27,TP-TP-15,TP-TP-29,TP-TP-17,TP-TP-19,TP-TP-53,TP-TP-54'  --TP 2F 2023/09/13
			SET @MCName += ',TP-FTTP-01,TP-FTTP-02,TP-FTTP-03,TP-FTTP-04,TP-TP-34'														  --TP 2F 2023/09/13

			SET @MCName += ',FT-RAS-001,FT-RAS-002,FT-RAS-004,FT-RAS-005,FT-RAS-006,FT-IFZ-014,FT-IFZ-020,FT-IFZ-013,FT-IFZ-034'
			SET @MCName += ',FT-IFZ-006,FT-IFZ-013,FT-IFZ-025,FT-IFZ-029,FT-IFZ-032,FT-IFZ-011,FT-IFZ-012,FT-IFZ-019,FT-IFZ-031'
			SET @MCName += ',FT-IFZ-024,FT-IFZ-033,FT-IFZ-035,FT-IFZ-001,FT-IFZ-017,FT-IFZ-018';
			--,TP-TP-09,TP-TP-14,TP-TP-18,TP-TP-44'--'FT-MT-001,FT-IFZ-030,FT-IFZ-008'
------ ADD FT NextLot 80 mc
--SET @MCName += ',FT-M-003,FT-M-013,FT-M-061,FT-M-106,FT-M-152,FT-M-173,FT-M-214,FT-M-223,FT-M-243,FT-M-195,FT-M-221,FT-M-026,FT-M-051,FT-M-064,FT-M-113,FT-M-135'
--SET @MCName += ',FT-M-156,FT-M-222,FT-M-024,FT-M-039,FT-M-042,FT-M-050,FT-M-104,FT-M-129,FT-M-074,FT-M-100,FT-M-143,FT-M-043,FT-M-055,FT-M-087,FT-M-089,FT-M-098';
--SET @MCName += ',FT-M-105,FT-M-114,FT-M-128,FT-M-001,FT-M-110,FT-M-019,FT-M-079,FT-M-158,FT-M-140,FT-M-148,FT-M-220,FT-IFZ-007,FT-Z-002,FT-ITHA-003,FT-M-034,FT-M-096';
--SET @MCName += ',FT-M-176,FT-M-038,FT-M-041,FT-M-056,FT-M-066,FT-M-070,FT-M-072,FT-M-094,FT-M-099,FT-M-111,FT-M-122,FT-M-127,FT-M-132,FT-M-144,FT-IFZ-065,FT-M-069';
--SET @MCName += ',FT-M-157,FT-M-169,FT-M-187,FT-M-192,FT-M-206,FT-M-212,FT-M-033,FT-M-101,FT-M-142,FT-M-172,FT-M-202,FT-M-063,FT-M-112,FT-M-191,FT-M-201,FT-M-080';
------ ADD FT NextLot 11 mc
SET @MCName +=',FT-M-003,FT-M-013,FT-M-061,FT-M-106,FT-M-173,FT-M-195,FT-M-214,FT-M-223,FT-M-243,FT-M-152';
--SET @MCName +=',TP-FTTP-04,TP-TP-09,TP-TP-01,TP-TP-14,TP-TP-44,TP-TP-37,TP-FTTP-01,TP-FTTP-02,TP-TP-15,TP-TP-18,TP-TP-17,TP-TP-19,TP-TP-27,TP-TP-29,TP-TP-30,TP-TP-34,TP-TP-73,TP-TP-52,TP-TP-53,TP-TP-54 ,TP-TP-58,TP-TP-74,TP-FTTP-03,TP-TP-69,TP-TP-70,TP-TP-71,TP-TP-72';

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
where seq_no = 2 and mc.name in (SELECT * FROM string_split(@MCName,','))
UNION ALL
SELECT lots.id as id, temp.lot_no as lotno,mc.id as mcid, temp.machine_name as mcname ,temp.package_name
FROM DBxDW.dbo.scheduler_temp_seq_tp as temp
INNER JOIN APCSProDB.trans.lots as lots on lots.lot_no = temp.lot_no collate SQL_Latin1_General_CP1_CI_AS
LEFT JOIN APCSProDB.mc.machines as mc on mc.name = temp.machine_name collate SQL_Latin1_General_CP1_CI_AS
where seq_no = 2 and mc.name in (SELECT * FROM string_split(@MCName,','))

--select * from #GetNextLot

INSERT INTO #tempNextLot
SELECT ROW_NUMBER() OVER(ORDER BY McID ASC),* FROM #GetNextLot

DECLARE @Loop int = 1

IF((select MAX(RowIndex) from  #tempNextLot) = 0)
	BEGIN
				UPDATE [APCSProDB].[trans].[machine_states]
					 SET [next_lot_id] = null
					 WHERE machine_id in (SELECT * FROM string_split(@MCName,','))
	END
--select MAX(RowIndex) from  #tempNextLot
--select * from #tempNextLot
WHILE @Loop <= (select MAX(RowIndex) from  #tempNextLot)
	Begin
		IF EXISTS ( (SELECT MCName FROM #tempNextLot WHERE McID = (SELECT McID FROM #tempNextLot where RowIndex = @Loop)))
		BEGIN
		DECLARE @mc_id int = (SELECT McID FROM #tempNextLot WHERE McID = (SELECT McID FROM #tempNextLot where RowIndex = @Loop)) 
		DECLARE @nextlot_id int = (SELECT next_lot_id FROM APCSProDB.trans.machine_states WHERE machine_id = @mc_id)

		DECLARE @lot_setup varchar(10) = (SELECT LotNo FROM DBx.dbo.FTSetupReport WHERE MCNo = (SELECT MCName FROM #tempNextLot where RowIndex = @Loop))
			--(SELECT next_lot_id FROM APCSProDB.trans.machine_states WHERE machine_id = @mc_id)
			IF (@nextlot_id is null)
				BEGIN
					--SELECT machine_id FROM APCSProDB.trans.machine_states WHERE machine_id = @mc_id
					--SELECT @mc_id as mcid ,@nextlot_id as lotid
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
							IF((SELECT is_special_flow FROM APCSProDB.trans.lots WHERE id = @nextlot_id) = 0)
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
											--UPDATE [APCSProDB].[trans].[machine_states]
											--SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop) 
											--WHERE machine_id = @mc_id
										END
								END
						ELSE
							BEGIN
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
										--UPDATE [APCSProDB].[trans].[machine_states]
										--SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop) 
										--WHERE machine_id = @mc_id
									END
							END
						END
					
					ELSE
						BEGIN
						IF((SELECT is_special_flow FROM APCSProDB.trans.lots WHERE id = @nextlot_id) = 0)
							BEGIN
									IF((SELECT id FROM APCSProDB.trans.lots WHERE lot_no = @lot_setup) <> @nextlot_id)
								BEGIN
									IF((SELECT process_state FROM APCSProDB.trans.lots WHERE id = @nextlot_id) not in (1,101))
										BEGIN
										
												IF((SELECT LotID FROM #tempNextLot where RowIndex = @Loop) is null)
													BEGIN
													--select '22',null as nextlotid, @mc_id
														UPDATE [APCSProDB].[trans].[machine_states]
														 SET [next_lot_id] = null
														 WHERE machine_id = @mc_id
													END
												ELSE
													BEGIN
													
													--select '11',(SELECT LotID FROM #tempNextLot where RowIndex = @Loop) as nextlotid, @mc_id
														UPDATE [APCSProDB].[trans].[machine_states]
														 SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop)
														 WHERE machine_id = @mc_id
													 END
											END
										END
							END
						ELSE
							BEGIN
							IF((SELECT id FROM APCSProDB.trans.lots WHERE lot_no = @lot_setup) <> @nextlot_id)
								BEGIN
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
													--select '2',null as nextlotid, @mc_id
														UPDATE [APCSProDB].[trans].[machine_states]
														 SET [next_lot_id] = null
														 WHERE machine_id = @mc_id
													END
												ELSE
													BEGIN
													
													--SELECT LotNo FROM DBx.dbo.FTSetupReport WHERE MCNo = (SELECT MCName FROM #tempNextLot where RowIndex = @Loop)
													--select '1',(SELECT LotID FROM #tempNextLot where RowIndex = @Loop) as nextlotid, @mc_id
														UPDATE [APCSProDB].[trans].[machine_states]
														 SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop)
														 WHERE machine_id = @mc_id
													 END
											END
										END
								END
							END
						END
				END


			--- old version-------
				--BEGIN

				--	IF((SELECT process_state FROM APCSProDB.trans.lots WHERE id = @nextlot_id) in (0,100))
				--	BEGIN

				--	--SELECT lot_no,process_state FROM APCSProDB.trans.lots WHERE lot_no = @nextlot_id
				--	UPDATE [APCSProDB].[trans].[machine_states]
				--		SET [next_lot_id] = (SELECT LotID FROM #tempNextLot where RowIndex = @Loop) 
				--		WHERE machine_id = @mc_id
				--	END
				--END
			
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
