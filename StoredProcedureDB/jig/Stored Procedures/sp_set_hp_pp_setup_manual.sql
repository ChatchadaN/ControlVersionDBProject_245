-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_hp_pp_setup_manual]
	-- Add the parameters for the stored procedure here
	@HPPP1 AS VARCHAR(100) = '',
	@HPPP2 AS VARCHAR(100) = '',
	@MCNo AS VARCHAR(50),
	@OPNo AS VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @mcid AS int
		,@OldHP AS int
		,@OldPP AS int
		,@Type1 AS VARCHAR(2)
		,@Type2 AS VARCHAR(2)
		,@ID1 AS INT
		,@ID2 AS INT
		,@OPID AS INT

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
	SET @mcid = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)

	--------------------- 1
	SET @Type1 = (SELECT APCSProDB.jig.categories.name FROM APCSProDB.trans.jigs 
	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
	  WHERE (qrcodebyuser = @HPPP1 OR smallcode = @HPPP1) AND categories.lsi_process_id = 3)
	SET @ID1 = (SELECT jigs.id FROM APCSProDB.trans.jigs 
	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
	  WHERE (qrcodebyuser = @HPPP1 OR smallcode = @HPPP1) AND categories.lsi_process_id = 3)

	--------------------- 2
	SET @Type2 = (SELECT APCSProDB.jig.categories.name FROM APCSProDB.trans.jigs 
	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
	  WHERE (qrcodebyuser = @HPPP2 OR smallcode = @HPPP2 ) AND categories.lsi_process_id = 3)
	SET @ID2 = (SELECT jigs.id FROM APCSProDB.trans.jigs 
	  INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
	  INNER JOIN APCSProDB.jig.categories on APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
	  WHERE (qrcodebyuser = @HPPP2 OR smallcode = @HPPP2) AND categories.lsi_process_id = 3)


	--///////////////////////////////// HPPP 1 //////////////////////////////////
	IF @Type1 = 'HP' BEGIN
		--HP idx1
		IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 1)
		BEGIN
			SET @OldHP = (SELECT jig_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 1)
			--update old
			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'To Stock'
				   ,[jig_state] = 3
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @OldHP

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@OldHP,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @OldHP), GETDATE(),@OPID,@OPNo,'To Stock',@MCNo,3)
			--update new
			UPDATE[APCSProDB].[trans].[machine_jigs]
			   SET [jig_id] = @ID1     
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = @OPID
			 WHERE machine_id = @mcid and idx = 1

			 UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
					WHERE id = @ID1

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@ID1,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @ID1), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
		 ELSE BEGIN
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_group_id,jig_id,created_at,created_by) 
			VALUES (@mcid,1,1,@ID1,GETDATE(),@OPID)

			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @ID1

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@ID1,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @ID1), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
	END

	ELSE IF @Type1 = 'PP' BEGIN
		 --PP idx2
		IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 2)
		BEGIN
			SET @OldPP = (SELECT jig_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 2)
			--update old
			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'To Stock'
				   ,[jig_state] = 3
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @OldPP

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@OldPP,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @OldPP), GETDATE(),@OPID,@OPNo,'To Stock',@MCNo,3)
		
			--update new
			 UPDATE[APCSProDB].[trans].[machine_jigs]
			   SET [jig_id] = @ID1     
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = @OPID
			 WHERE machine_id = @mcid and idx = 2

			 UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @ID1

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@ID1,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @ID1), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
		 ELSE BEGIN
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_group_id,jig_id,created_at,created_by) 
			VALUES (@mcid,2,1,@ID1,GETDATE(),@OPID)

			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @ID1

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@ID1,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @ID1), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
	END



	--///////////////////////////////// HPPP 2 //////////////////////////////////
	IF @Type2 = 'HP' BEGIN
		--HP idx1
		IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 1)
		BEGIN
			SET @OldHP = (SELECT jig_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 1)
			--update old
			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'To Stock'
				   ,[jig_state] = 3
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @OldHP

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@OldHP,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @OldHP), GETDATE(),@OPID,@OPNo,'To Stock',@MCNo,3)
			--update new
			UPDATE[APCSProDB].[trans].[machine_jigs]
			   SET [jig_id] = @ID2     
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = @OPID
			 WHERE machine_id = @mcid and idx = 1

			 UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
					WHERE id = @ID2

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@ID2,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @ID2), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
		 ELSE BEGIN
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_group_id,jig_id,created_at,created_by) 
			VALUES (@mcid,1,1,@ID2,GETDATE(),@OPID)

			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @ID2

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@ID2,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @ID2), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
	END

	ELSE IF @Type2 = 'PP' BEGIN
		 --PP idx2
		IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 2)
		BEGIN
			SET @OldPP = (SELECT jig_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 2)
			--update old
			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'To Stock'
				   ,[jig_state] = 3
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @OldPP

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@OldPP,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @OldPP), GETDATE(),@OPID,@OPNo,'To Stock',@MCNo,3)
		
			--update new
			 UPDATE[APCSProDB].[trans].[machine_jigs]
			   SET [jig_id] = @ID2     
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = @OPID
			 WHERE machine_id = @mcid and idx = 2

			 UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @ID2

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@ID2,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @ID2), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
		 ELSE BEGIN
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_group_id,jig_id,created_at,created_by) 
			VALUES (@mcid,2,1,@ID2,GETDATE(),@OPID)

			UPDATE [APCSProDB].[trans].[jigs]
				SET [status] = 'On Machine'
				   ,[jig_state] = 12
				   ,[updated_at] = GETDATE()
				   ,[updated_by] = @OPID
				WHERE id = @ID2

			INSERT INTO APCSProDB.trans.jig_records ([day_id], [record_at], [jig_id], [jig_production_id], [created_at], [created_by], [operated_by], transaction_type,mc_no,record_class) 
							values((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111)),GETDATE(),@ID2,
							(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @ID2), GETDATE(),@OPID,@OPNo,'On Machine',@MCNo,12)
		 END
	END

END
