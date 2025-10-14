CREATE TABLE [dbo].[ProductBatches] (
    [BatchNo]     INT            NOT NULL,
    [ProductID]   INT            NOT NULL,
    [ProductName] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_ProductBatches] PRIMARY KEY CLUSTERED ([BatchNo] ASC, [ProductID] ASC)
);

