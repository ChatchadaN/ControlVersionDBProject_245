CREATE TYPE [dbo].[WaferLotList] AS TABLE (
    [WaferLot] NVARCHAR (12) NOT NULL,
    [OrderNo]  NVARCHAR (12) NULL,
    PRIMARY KEY CLUSTERED ([WaferLot] ASC));

