
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/09/29>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [material].[sp_set_pickup_repack_001]
	-- Add the parameters for the stored procedure here
	  @barcode				VARCHAR(50)
	, @quantity				INT  
	, @pack_size			INT 
	, @emp_id				INT			= 1

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE   @limit_state			INT 
			, @limitdate			DATETIME 
			, @qc_state				INT 
			, @extended_limit_date	DATETIME
			 



	BEGIN TRY  

		SELECT    @limitdate			= ISNULL(m.limit_date, GETDATE()) 
				, @extended_limit_date	= ISNULL(extended_limit_date, GETDATE())
				, @limit_state			= limit_state
				, @qc_state				= qc_state
	FROM APCSProDB.trans.materials m 
	INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id
	INNER JOIN APCSProDB.material.categories c ON c.id = p.category_id
	WHERE barcode = @barcode
 

				IF  (@quantity	 > 0 AND  @pack_size > 0	)
				BEGIN 
				
					DELETE APCSPRODB.[TRANS].[MATERIAL_REPACK_FILE] 
					WHERE BARCODE = @BARCODE;

					INSERT INTO APCSPRODB.[TRANS].[MATERIAL_REPACK_FILE]
					(			 [MATERIAL_ID]
							   , [DAY_ID]
							   , [LOCATION_ID]
							   , [TO_LOCATION_ID]
							   , [WH_CODE]
							   , [PRODUCTION_NAME]
							   , [BARCODE]
							   , [QUANTITY]
							   , [PACK_STD_QTY]
							   , [PACK_UNIT_QTY]
							   , [REPACK_QTY]
							   , [PACK_UNIT_NAME]
							   , [LOT_NO]
							   , [CREATED_AT]
							   , created_by
					)
					SELECT	     [MTAL].ID
							   , StoredProcedureDB.[MATERIAL].[FN_GETDAYID](GETDATE())
							   , [MTAL].LOCATION_ID
							   , [MTAL].LOCATION_ID
							   , [LOC].WH_CODE
							   , [PROD].NAME
							   , [MTAL].BARCODE
							   , [MTAL].QUANTITY
							   , [PROD].PACK_STD_QTY
							   , @PACK_SIZE
							   , @QUANTITY
							   , [UNIT].DESCRIPTIONS
							   , [MTAL].LOT_NO
							   , GETDATE()
							   , @emp_id
					FROM APCSPRODB.TRANS.MATERIALS [MTAL] 
					INNER JOIN APCSPRODB.MATERIAL.LOCATIONS [LOC] 
					ON [MTAL].LOCATION_ID =  [LOC].ID
					INNER JOIN APCSPRODB.MATERIAL.PRODUCTIONS [PROD] 
					ON [MTAL].MATERIAL_PRODUCTION_ID = [PROD].ID
					INNER JOIN APCSPRODB.MATERIAL.MATERIAL_CODES [UNIT] 
					ON [PROD].UNIT_CODE = [UNIT].CODE 
					WHERE [MTAL].BARCODE = @BARCODE AND UNIT.[GROUP] = 'PACKAGE_UNIT';


					SELECT    'TRUE'							AS Is_Pass
							, N'Repack completed sccessfully'	AS Error_Message_ENG
							, N'Repack completed sccessfully'	AS Error_Message_THA
							, ''								AS Handling 
					RETURN
				END 

		END TRY  
		BEGIN CATCH  

					SELECT    'FALSE'					AS Is_Pass 
							, N'Failed to repack !!'	AS Error_Message_ENG
							, N'Failed to repack !!'	AS Error_Message_THA 
							, ''						AS Handling

		END CATCH  


END
