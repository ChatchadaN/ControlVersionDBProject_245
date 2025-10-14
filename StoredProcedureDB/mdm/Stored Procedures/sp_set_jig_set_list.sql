-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_jig_set_list]
	-- Add the parameters for the stored procedure here
	@jigset AS int,			
	@jig_groupid AS INT,
	@qty AS DECIMAL(18,6),
	@unit AS INT 
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--Check Material Set Exists
	IF EXISTS(SELECT 1 FROM [APCSProDB].[method].jig_set_list WHERE id = @jigset AND jig_set_id = @jig_groupid)
	BEGIN

			UPDATE [APCSProDB].[method].jig_set_list
			SET use_qty		 = @qty
			, use_qty_unit	 = @unit
			WHERE id = @jigset 
			AND jig_set_id = @jig_groupid
			 

		SELECT    'TRUE'									AS Is_Pass
				, 'Update data success. !!'				AS Error_Message_ENG
				, N'แก้ไขข้อมูลเรียบร้อยเเล้ว !!'	    AS Error_Message_THA
		RETURN
	END
	
	BEGIN TRANSACTION
	BEGIN TRY

	DECLARE @idx AS INT ,  @id AS INT
	SET @idx = (SELECT ISNULL(MAX(idx),0) +1 FROM [APCSProDB].[method].jig_set_list WHERE jig_set_id = @jigset)
	 
	SET @id = (SELECT ISNULL(MAX(id),0) +1 FROM [APCSProDB].[method].jig_set_list  )


		INSERT INTO [APCSProDB].[method].jig_set_list
			   ( id
			     ,  jig_set_id
				 , idx
				 , jig_group_id
				 , use_qty
				 , use_qty_unit
				)		   
		 VALUES
			   (  @id
			    , @jigset
			    , @idx
			    , @jig_groupid
			    , @qty
			    , @unit
			   )

		SELECT	  'TRUE'	AS Is_Pass 
				, ''		AS Error_Message_ENG 
				, N''		AS Error_Message_THA
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT	  'FALSE'					AS Is_Pass 
				,'Unable to edit data'		AS Error_Message_ENG
				, N'การแก้ไขข้อมูลผิดพลาด !!'		AS Error_Message_THA
	END CATCH
END