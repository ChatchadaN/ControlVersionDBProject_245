CREATE TABLE [dbo].[config_lot_marks] (
    [Device]      CHAR (20)     NOT NULL,
    [Package]     CHAR (20)     NOT NULL,
    [ColumnMark]  VARCHAR (MAX) NULL,
    [FT_SYMBOL_1] VARCHAR (20)  NULL,
    [FT_SYMBOL_2] VARCHAR (20)  NULL,
    [FT_SYMBOL_3] VARCHAR (20)  NULL,
    [FT_SYMBOL_4] VARCHAR (20)  NULL,
    [FT_SYMBOL_5] VARCHAR (20)  NULL,
    [IsEnabled]   TINYINT       CONSTRAINT [DF_config_lot_marks_IsEnabled] DEFAULT ((0)) NULL,
    [Comment]     VARCHAR (MAX) NULL,
    CONSTRAINT [PK_config_lot_marks] PRIMARY KEY CLUSTERED ([Device] ASC, [Package] ASC)
);

