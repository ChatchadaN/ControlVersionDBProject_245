-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_tp_qa_setup_mc] 
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	@Devicename as VARCHAR(50)='%' ,
	@PKG as VARCHAR(50) ='%' ,
	@IsGDIC as int = 1,
	@McName as VARCHAR(50) = null ,
	@TpRank as VARCHAR(5) ='%'
AS
BEGIN
BEGIN TRANSACTION
BEGIN Try
	IF(@McName is null)
	begin
		UPDATE  DBx.dbo.scheduler_tp_qa_mc_setup
		SET		[devicename] = @Devicename
		WHERE [is_gdic] = @IsGDIC and [pkgname] = @PKG
	end
	ELSE
	begin
		UPDATE  DBx.dbo.scheduler_tp_qa_mc_setup
		SET		[devicename] = @Devicename
		WHERE [mcname] = @McName
	end
	COMMIT;
END TRY
BEGIN CATCH
	PRINT '---> Error <----' +  ERROR_MESSAGE() + '---> Error <----'; 
	ROLLBACK;
END CATCH		
END
