



-- exec QORT_ARM_SUPPORT.dbo.DRAFT1 



CREATE PROCEDURE [dbo].[DRAFT1]

	

AS



BEGIN
	BEGIN TRY



		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Lida\Max_VS_Qort.xlsx'

		declare @Sheet varchar(16) 

		declare @TodayDate date = getdate()

		declare @TodayDateInt int = cast(convert(varchar, @TodayDate, 112) as int)

		declare @Message varchar(1024)

		SET NOCOUNT ON



		declare @cmd varchar(255)

		declare @sql varchar(1024)





			set @Sheet = 'Sheet1'

	

	IF OBJECT_ID('tempdb..##ExcelHeader', 'U') IS NOT NULL DROP TABLE ##ExcelHeader;

			SET @sql = 'SELECT * INTO ##ExcelHeader

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0;Database=' + @filePath + ';HDR=NO;IMEX=1'',

				''SELECT * FROM [' + @Sheet + '$A1:D1]'')'



			EXEC(@sql)





			SELECT * FROM ##ExcelHeader



		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			

	

			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath  + '; HDR=NO;IMEX=1'',

				''SELECT * FROM [' + @Sheet + '$A2:D500]'')'



			exec(@sql)

			select * from ##comms 

			DECLARE @date1 INT, @date2 INT, @date3 INT 

			SELECT TOP 1 @date1 = cast(convert(varchar, [F2], 112) as int)

			, @date2 = cast(convert(varchar, [F3], 112) as int)

			, @date3 = cast(convert(varchar, [F4], 112) as int)

			FROM ##ExcelHeader 

	--/*

			UPDATE C

			SET 

			 

			   F2 = dbo.fn_Quote_AMD((select top 1 id from QORT_BACK_DB.dbo.Assets ass where F1 = ass.ISIN and ass.enabled = 0 ), @date1)

			 , F3 = dbo.fn_Quote_AMD((select top 1 id from QORT_BACK_DB.dbo.Assets ass where F1 = ass.ISIN and ass.enabled = 0 ), @date2)

			 , F4 = dbo.fn_Quote_AMD((select top 1 id from QORT_BACK_DB.dbo.Assets ass where F1 = ass.ISIN and ass.enabled = 0 ), @date3)



				FROM ##comms C

				WHERE F1 IS NOT NULL


  --*/
  	select * from ##comms 
	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		SET @Message = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
		PRINT @Messag
e
		SELECT @Message AS Result, 'red' AS ResultColor
	END CATCH
END

