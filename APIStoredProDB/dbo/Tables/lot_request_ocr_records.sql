CREATE TABLE [dbo].[lot_request_ocr_records] (
    [id]            INT           IDENTITY (1, 1) NOT NULL,
    [lot_no]        VARCHAR (10)  NOT NULL,
    [ip_address]    VARCHAR (50)  NOT NULL,
    [path_image]    VARCHAR (MAX) NULL,
    [status]        TINYINT       NOT NULL,
    [mc_no]         VARCHAR (50)  NULL,
    [record_class]  INT           NULL,
    [timestamp]     DATETIME      CONSTRAINT [DF_lot_request_ocr_records_timestamp] DEFAULT (getdate()) NULL,
    [request_count] INT           CONSTRAINT [DF_lot_request_ocr_records_request_count] DEFAULT ((1)) NULL,
    CONSTRAINT [PK_lot_request_ocr_records] PRIMARY KEY CLUSTERED ([id] ASC)
);

