CREATE TABLE [dbo].[exec_spdb_history] (
    [history_id]       INT            IDENTITY (1, 1) NOT NULL,
    [record_at]        DATETIME       NULL,
    [record_class]     INT            NULL,
    [login_name]       NVARCHAR (50)  NULL,
    [hostname]         NVARCHAR (50)  NULL,
    [appname]          NVARCHAR (128) NULL,
    [storedprocedname] NVARCHAR (200) NULL,
    [lot_no]           CHAR (20)      NULL,
    [command_text]     NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_exec_spdb_history] PRIMARY KEY CLUSTERED ([history_id] ASC)
);

