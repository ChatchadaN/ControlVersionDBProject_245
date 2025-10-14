CREATE TYPE [req].[images] AS TABLE (
    [id]          INT             NOT NULL,
    [images_file] VARBINARY (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC));

