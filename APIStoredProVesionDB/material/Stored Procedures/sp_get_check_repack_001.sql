
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/09/29>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [material].[sp_get_check_repack_001]
	-- Add the parameters for the stored procedure here
	  @barcode				VARCHAR(50)
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE   @limit_state			INT 
			, @limitdate			DATETIME 
			, @qc_state				INT 
			, @extended_limit_date	DATETIME
			 
			   
		SELECT    @limitdate			= ISNULL(m.limit_date, GETDATE()) 
				, @extended_limit_date	= ISNULL(extended_limit_date, GETDATE())
				, @limit_state			= limit_state
				, @qc_state				= qc_state
	FROM APCSProDB.trans.materials m 
	INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id
	INNER JOIN APCSProDB.material.categories c ON c.id = p.category_id
	WHERE barcode = @barcode
 

				IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.materials	WHERE barcode = @barcode)
				BEGIN

						SELECT    'FALSE'					AS Is_Pass 
								, N'This material ('+ @barcode +') not found.'	AS Error_Message_ENG
								, N'ไม่พบข้อมูล ('+ @barcode +') Material'	AS Error_Message_THA 
								, ''						AS Handling
						RETURN

				END  
				ELSE IF((@limitdate < GETDATE() AND @extended_limit_date < GETDATE()) OR (@limit_state <> 0))
				BEGIN

						SELECT    'FALSE'					AS Is_Pass 
								, N'Material has expired.'	AS Error_Message_ENG
								, N'Material has expired.'	AS Error_Message_THA 
								, ''						AS Handling
						RETURN

				END  
				ELSE IF(@qc_state <>  0)
				BEGIN

						SELECT    'FALSE'					AS Is_Pass 
								, N'Material is on Hold.'	AS Error_Message_ENG
								, N'Material is on Hold.'	AS Error_Message_THA 
								, ''						AS Handling

						RETURN

				END 
				ELSE  
				BEGIN 
				 

					SELECT    'TRUE'							AS Is_Pass
							, N'Success'						AS Error_Message_ENG
							, N'Success'						AS Error_Message_THA
							, ''								AS Handling 
					RETURN



				END 

 

END
