-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_andon_insertcase]
	-- Add the parameters for the stored procedure here
	@id as int,
	@runningdisplayid as varchar(10),
	@ProcessName as varchar(20),
	@McNo as varchar(20),
	@OPNo as varchar(10),
	@LineNo as varchar(50),
	@Package as varchar(20),
	@Device as varchar(25),
	@LotNo as varchar(10),
	@Type as varchar(50),
	@Detail as varchar(250),
	@Detail2 as varchar(250),
	@Detail3 as varchar(250),
	@ComName as varchar(250)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

		IF(@ProcessName = 'EDS') BEGIN
			SET @Package = 'NONE'
		END

		INSERT INTO DBx.dbo.ProblemsTransaction VALUES(
                    @id ,
                    @runningdisplayid ,
                    @ProcessName ,
                    @McNo,
                    @OPNo,
                    @LineNo,
                    UPPER(@Package),
                    UPPER(@Device),
                    UPPER(@LotNo),
                    GETDATE(),
                    NULL, 
                    0,
                    NULL,
                    @Type,
                    @Detail,
                    ISNULL(NULL,@Detail2),
                    @Detail3,
                    @ComName)
END
