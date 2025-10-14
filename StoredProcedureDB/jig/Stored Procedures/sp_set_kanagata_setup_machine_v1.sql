-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [jig].[sp_set_kanagata_setup_machine_v1] 
	-- Add the parameters for the stored procedure here
		@MCNo as varchar(50),		
		@UserID as varchar(50),
		@KanagataName as varchar(50) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @JIG_ID as varchar(50)
	,@MC_ID as INT
	,@Status as varchar(50)

	SET @JIG_ID = (SELECT jigs.id FROM APCSProDB.trans.jigs INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
				  INNER JOIN APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id WHERE qrcodebyuser = @KanagataName AND categories.name = 'Kanagata Base')
	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo)

	SET @Status = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID)

	IF @Status = 'To Machine' BEGIN
		IF EXISTS (SELECT machine_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID and idx = 1) BEGIN
			DECLARE @JIG_OLD as INT
			SET @JIG_OLD =	(SELECT jig_id as Detail FROM APCSProDB.trans.machine_jigs where machine_id = @MC_ID and idx = 1 )
			IF @JIG_ID <> @JIG_OLD BEGIN
						--/////////Check JIG On Machine Old //OR// JIG NEW
				IF NOT EXISTS( SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIG_ID AND machine_id = @MC_ID) BEGIN
					--//////////UPDATE JIG OLD
					UPDATE APCSProDB.trans.jigs set status = 'To Machine',[jig_state] = 11,updated_at = GETDATE(),updated_by = @UserID where id = @JIG_OLD OR root_jig_id = @JIG_OLD

					--//////////UPDATE JIG NEW
					UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @UserID where id = @JIG_ID OR root_jig_id = @JIG_ID
					UPDATE APCSProDB.trans.machine_jigs SET  jig_id = @JIG_ID,updated_at = GETDATE(),updated_by = @UserID WHERE machine_id = @MC_ID

					--//////////Insert JIG Record On Machine
					INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,mc_no,record_class) 
								 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID,
								 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID),NULL, GETDATE(), @UserID, @UserID,'On Machine',@MCNo,12)

					--//////////Insert JIG Record Out Machine
					INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,record_class) 
								 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_OLD,
								 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_OLD),NULL, GETDATE(), @UserID, @UserID,'To Machine',11)
				END
			END
		END
		ELSE  BEGIN
			--//////////UPDATE JIG NEW
			UPDATE APCSProDB.trans.jigs set location_id = NULL,status = 'On Machine',[jig_state] = 12,updated_at = GETDATE(),updated_by = @UserID where id = @JIG_ID OR root_jig_id = @JIG_ID
			INSERT INTO APCSProDB.trans.machine_jigs (machine_id,idx,jig_id,created_at,created_by) VALUES (@MC_ID,1,@JIG_ID,GETDATE(),@UserID)

			--//////////Insert JIG Record On Machine
			INSERT INTO APCSProDB.trans.jig_records ([day_id],[record_at],[jig_id],[jig_production_id],[location_id],[created_at],[created_by],[operated_by],transaction_type,mc_no,record_class) 
						 values ((SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111)),GETDATE(),@JIG_ID,
						 (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID),NULL, GETDATE(), @UserID, @UserID,'On Machine',@MCNo,12)
		END
	END
END