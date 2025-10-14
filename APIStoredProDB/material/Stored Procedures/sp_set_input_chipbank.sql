
-- =============================================
-- Author:		Chatchadaporn
-- Create date: 2024/08/22
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_input_chipbank] 
	@OPNo				NVARCHAR(100)			
	, @App_Name			NVARCHAR(100)
	, @CHIPMODELNAME	NVARCHAR(100)
	, @INVOICENO		NVARCHAR(100)
	, @WFLOTNO			NVARCHAR(100)
	, @SEQNO			NVARCHAR(100)
	, @RFSEQNO			VARCHAR(100)
	, @WFCOUNT			DECIMAL		
	, @CHIPCOUNT		DECIMAL		
	, @WFCOUNT_FAIL		DECIMAL		
	, @OUTDIV			NVARCHAR(100)
	, @RECDIV			NVARCHAR(100)
	, @ORDERNO			NVARCHAR(100)
	, @SLIPNO			VARCHAR(100)
	, @SLIPNOEDA		VARCHAR(100)
	, @CASENO			VARCHAR(100)
	, @HOLDFLAG			TINYINT		
	, @PLASMA			VARCHAR(100)
	, @STOCKDATE		NVARCHAR(100)
	, @WFDATA1			NVARCHAR(180)
	, @WFDATA2			NVARCHAR(180)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

		INSERT INTO APIStoredProDB.[dbo].[exec_sp_history]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no])
		SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [material].[sp_set_input_chipbank_001] @WFLOTNO  = ''' + ISNULL(CAST(@WFLOTNO AS nvarchar(MAX)),'') 
				+ ''',@OPNo = ''' + ISNULL(CAST(@OPNo AS nvarchar(MAX)),'') +  
				+ ''',App_Name = ''' + ISNULL(CAST(@App_Name AS nvarchar(MAX)),'') +
				+ ''',@CHIPMODELNAME = ''' + ISNULL(CAST(@CHIPMODELNAME AS nvarchar(MAX)),'') +
				+ ''',@INVOICENO = ''' + ISNULL(CAST(@INVOICENO AS nvarchar(MAX)),'') +
				+ ''',@SEQNO = ''' + ISNULL(CAST(@SEQNO AS nvarchar(MAX)),'') +
				+ ''',@RFSEQNO = ''' + ISNULL(CAST(@RFSEQNO AS nvarchar(MAX)),'') +
				+ ''',@WFCOUNT = ''' + ISNULL(CAST(@WFCOUNT AS nvarchar(MAX)),'') +
				+ ''',@CHIPCOUNT = ''' + ISNULL(CAST(@CHIPCOUNT AS nvarchar(MAX)),'') +
				+ ''',@WFCOUNT_FAIL = ''' + ISNULL(CAST(@WFCOUNT_FAIL AS nvarchar(MAX)),'') +
				+ ''',@OUTDIV = ''' + ISNULL(CAST(@OUTDIV AS nvarchar(MAX)),'') +
				+ ''',@RECDIV = ''' + ISNULL(CAST(@RECDIV AS nvarchar(MAX)),'') +
				+ ''',@ORDERNO = ''' + ISNULL(CAST(@ORDERNO AS nvarchar(MAX)),'') +
				+ ''',@SLIPNO = ''' + ISNULL(CAST(@SLIPNO AS nvarchar(MAX)),'') +
				+ ''',@SLIPNOEDA = ''' + ISNULL(CAST(@SLIPNOEDA AS nvarchar(MAX)),'') +
				+ ''',@CASENO = ''' + ISNULL(CAST(@CASENO AS nvarchar(MAX)),'') +
				+ ''',@HOLDFLAG = ''' + ISNULL(CAST(@HOLDFLAG AS nvarchar(MAX)),'') +
				+ ''',@PLASMA = ''' + ISNULL(CAST(@PLASMA AS nvarchar(MAX)),'') +
				+ ''',@STOCKDATE = ''' + ISNULL(CAST(@STOCKDATE AS nvarchar(MAX)),'') +
				+ ''',@WFDATA1 = ''' + ISNULL(CAST(@WFDATA1 AS nvarchar(MAX)),'') +
				+ ''',@WFDATA2 = ''' + ISNULL(CAST(@WFDATA2 AS nvarchar(MAX)),'') +
				''''
			, @WFLOTNO

	---- ########## VERSION 001 ##########

			EXEC [APIStoredProVersionDB].[material].[sp_set_input_chipbank_001] 
				 		@OPNo			= 	@OPNo			
					,	@App_Name		=   @App_Name		
					,	@CHIPMODELNAME	=   @CHIPMODELNAME	
					,	@INVOICENO		=	@INVOICENO
					,	@WFLOTNO		=	@WFLOTNO
					,	@SEQNO			=	@SEQNO
					,	@RFSEQNO		=	@RFSEQNO
				    ,	@WFCOUNT		=	@WFCOUNT
					,	@CHIPCOUNT		=	@CHIPCOUNT
					,	@WFCOUNT_FAIL	=	@WFCOUNT_FAIL
					,	@OUTDIV			=	@OUTDIV
					,	@RECDIV			=	@RECDIV
					,	@ORDERNO		=	@ORDERNO
					,	@SLIPNO			=	@SLIPNO
					,	@SLIPNOEDA		=	@SLIPNOEDA
					,	@CASENO			=	@CASENO
					,	@HOLDFLAG		=	@HOLDFLAG
					,	@PLASMA			=	@PLASMA
					,	@STOCKDATE		=	@STOCKDATE
					,	@WFDATA1		=	@WFDATA1
					,	@WFDATA2		=	@WFDATA2

	---- ########## VERSION 001 ##########

END
