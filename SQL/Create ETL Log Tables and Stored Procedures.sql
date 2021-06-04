DECLARE @dbname nvarchar(128)

-- Please change the database to the one this will be run on.
SET @dbname = N'SSISLogs'

IF NOT (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE ('[' + name + ']' = @dbname OR name = @dbname)))
BEGIN
	CREATE DATABASE [SSISLogs]
END

GO

USE [SSISLogs]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ErrorLog](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[PackageName] [varchar](150) NULL,
	[EventType] [varchar](15) NULL,
	[ExecutionID] [varchar](50) NULL,
	[PackageID] [varchar](50) NULL,
	[SourceName] [varchar](150) NULL,
	[SourceID] [varchar](50) NULL,
	[ErrorCode] [varchar](15) NULL,
	[ErrorDescription] [varchar](1000) NULL,
	[InteractiveMode] [bit] NULL,
	[MachineName] [varchar](50) NULL,
	[UserName] [varchar](50) NULL,
	[EventDateTime] [datetime] NOT NULL DEFAULT ((getdate())),
 CONSTRAINT [PK_SSISEnterpriseLog] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
))

GO
CREATE TABLE [dbo].[PackageLog](
	[PackageLogID] [int] IDENTITY(1,1) NOT NULL,
	[PackageName] [nvarchar](100) NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[Success] [bit] NULL CONSTRAINT [DF_PackageLog_Success]  DEFAULT ((0)),
 CONSTRAINT [PK_PackageLog] PRIMARY KEY CLUSTERED 
(
	[PackageLogID] ASC
))

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LoadLog](
	[LoadLogID] [int] IDENTITY(1,1) NOT NULL,
	[PackageLogID] [int] NOT NULL,
	[TableName] [nvarchar](100) NOT NULL,
	[UpdateCount] [int] NOT NULL CONSTRAINT [DF_TableLog_UpdateCount]  DEFAULT ((0)),
	[InsertCount] [int] NOT NULL CONSTRAINT [DF_TableLog_InsertCount]  DEFAULT ((0)),
	[DeleteCount] [int] NOT NULL CONSTRAINT [DF_TableLog_DeleteCount]  DEFAULT ((0)),
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[Success] [bit] NOT NULL CONSTRAINT [DF_TableLog_Success]  DEFAULT ((0)),
 CONSTRAINT [PK_LoadLog] PRIMARY KEY CLUSTERED 
(
	[LoadLogID] ASC
))

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExtractLog](
	[ExtractLogID] [int] IDENTITY(1,1) NOT NULL,
	[PackageLogID] [int] NOT NULL,
	[TableName] [nvarchar](100) NOT NULL,
	[ExtractCount] [int] NOT NULL CONSTRAINT [DF_ExtractLog_ExtractCount]  DEFAULT ((0)),
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[LastExtractDateTime] [datetime] NULL,
	[Success] [bit] NOT NULL CONSTRAINT [DF_ExtractLog_Success]  DEFAULT ((0)),
 CONSTRAINT [PK_ExtractLog] PRIMARY KEY CLUSTERED 
(
	[ExtractLogID] ASC
))
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[stp_InitPackageLog]
  @PackageName NVARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO PackageLog (
	  PackageName
	, StartTime
	)
	VALUES (
	  @PackageName
	, GetDate()
	)

	SELECT CAST(Scope_Identity() AS INT) PackageLogID
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[stp_EndPackageLog]
  @PackageLogID INT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE PackageLog SET
	  EndTime = GetDate()
	, Success = 1
	WHERE PackageLogID = @PackageLogID

	SET NOCOUNT OFF;
END

GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[stp_InitExtractLog]
  @PackageLogID INT,
  @TableName NVARCHAR(100)
AS
BEGIN
	DECLARE @LastExtractDateTime	DATETIME
	
	SET NOCOUNT ON;
	
	SELECT @LastExtractDateTime = ISNULL(MAX(LastExtractDateTime), '1900-01-01')
	FROM ExtractLog
	WHERE TableName = @TableName
	AND ExtractLogID = (SELECT MAX(ExtractLogID) FROM ExtractLog WHERE TableName = @TableName)
		
	INSERT INTO ExtractLog (
	  PackageLogID
	, TableName
	, StartTime
	)
	VALUES (
	  @PackageLogID
	, @TableName
	, GetDate()
	)

	SELECT 
	  CAST(Scope_Identity() AS INT) ExtractLogID
	, @LastExtractDateTime
	
	SET NOCOUNT OFF;
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[stp_EndExtractLog]
  @ExtractLogID INT,
  @ExtractCount INT,
  @TableName NVARCHAR(100),
  @ColumnName VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @LastExtractDateTime DATETIME, @SQL NVARCHAR(255)
	
	SELECT @SQL = N'SELECT @LastExtractDateTime = ISNULL(MAX(' + @ColumnName + '), ''1900-01-01'') FROM ' + @TableName
	EXEC sp_executeSQL @SQL, N'@LastExtractDateTime DATETIME OUTPUT', @LastExtractDateTime OUTPUT
	
	UPDATE ExtractLog
	SET
	  EndTime = GetDate()
	, ExtractCount = @ExtractCount
	, LastExtractDateTime = @LastExtractDateTime
	, Success = 1
	WHERE ExtractLogID = @ExtractLogID

	SET NOCOUNT OFF;
END
GO

CREATE PROCEDURE [dbo].[stp_InitLoadLog]
  @PackageLogID int,
  @TableName nvarchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO LoadLog (
	  PackageLogID,
	  TableName,
	  StartTime
	)
	VALUES (
	  @PackageLogID,
	  @TableName,
	  GetDate()
	)

	SELECT CAST(Scope_Identity() AS INT) LoadLogID
END

GO

CREATE PROCEDURE [dbo].[stp_EndLoadLog]
  @LoadLogID INT,
  @UpdateCount int = 0,
  @InsertCount int = 0
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE LoadLog 
	SET
		UpdateCount = @UpdateCount,
		InsertCount = @InsertCount,
		EndTime = GetDate(),
		Success = 1
	WHERE LoadLogID = @LoadLogID

	SET NOCOUNT OFF;
END

GO


ALTER TABLE [dbo].[ExtractLog]  WITH CHECK ADD  CONSTRAINT [FK_ExtractLog_PackageLog] FOREIGN KEY([PackageLogID])
REFERENCES [dbo].[PackageLog] ([PackageLogID])
GO
ALTER TABLE [dbo].[ExtractLog] CHECK CONSTRAINT [FK_ExtractLog_PackageLog]
GO

ALTER TABLE [dbo].[LoadLog]  WITH CHECK ADD  CONSTRAINT [FK_LoadLog_PackageLog] FOREIGN KEY([PackageLogID])
REFERENCES [dbo].[PackageLog] ([PackageLogID])
GO
ALTER TABLE [dbo].[LoadLog] CHECK CONSTRAINT [FK_LoadLog_PackageLog]
GO
