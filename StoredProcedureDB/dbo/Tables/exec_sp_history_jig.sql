CREATE TABLE [dbo].[exec_sp_history_jig] (
    [history_id]   INT            IDENTITY (1, 1) NOT NULL,
    [record_at]    DATETIME       NULL,
    [record_class] INT            NULL,
    [login_name]   NVARCHAR (50)  NULL,
    [hostname]     NVARCHAR (50)  NULL,
    [appname]      NVARCHAR (128) NULL,
    [command_text] NVARCHAR (MAX) NULL,
    [lot_no]       CHAR (20)      NULL,
    [jig_id]       INT            NULL,
    [barcode]      CHAR (100)     NULL,
    CONSTRAINT [PK_exec_sp_history_jig] PRIMARY KEY CLUSTERED ([history_id] ASC)
);

