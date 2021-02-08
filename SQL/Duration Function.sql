USE SSISLogs 
GO 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Hector Sosa, Jr
-- Create date: Aug 5, 2012
-- Description:	Gets a text description of a
-- duration between two datetime values.
-- =============================================
CREATE FUNCTION GetDuration 
(
	@startTime DATETIME, @endTime DATETIME
)
RETURNS VARCHAR(50)
AS
BEGIN

	DECLARE @duration INT, @hours INT, @minutes INT, @seconds INT, @totalSeconds INT,
    @durationText VARCHAR(50)

    SET @durationText = ''

    SET @totalSeconds = datediff(second,@startTime,@endTime)
    SET @hours = @totalSeconds / 3600
    SET @minutes = @totalSeconds % 3600 / 60
    SET @seconds = @totalSeconds % 60

    IF @hours > 0
    BEGIN 
        DECLARE @hourText VARCHAR(6)
        
        IF @hours = 1
        BEGIN  
          SET @hourText = ' hour'
        END
        ELSE 
        BEGIN
          SET @hourText = ' hours'
        END
        
        SET @durationText = cast(@hours AS VARCHAR(3)) + @hourText
    END 

    IF @minutes > 0
    BEGIN
        DECLARE @minuteText VARCHAR(6)
        
        IF @minutes = 1
        BEGIN  
          SET @minuteText = ' minute'
        END
        ELSE 
        BEGIN
          SET @minuteText = ' minutes'
        END
         
        SET @durationText = @durationText + cast(@minutes AS VARCHAR(3)) + @minuteText
    END 

    IF @seconds > 0
    BEGIN
        DECLARE @secondText VARCHAR(6)
        
        IF @seconds = 1
        BEGIN  
          SET @secondText = ' second'
        END
        ELSE 
        BEGIN
          SET @secondText = ' seconds'
        END 
        SET @durationText = @durationText + cast(@seconds AS VARCHAR(3)) + @secondText
    END
    ELSE
    BEGIN 
        DECLARE @millisecs INT
        SET @millisecs = datediff(millisecond,@startTime,@endTime)
        SET @durationText = cast(@millisecs AS VARCHAR(5)) + ' milliseconds'
    END  

    RETURN @durationText
    
END
GO

