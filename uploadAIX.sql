



-- exec QORT_ARM_SUPPORT..uploadAIX







CREATE PROCEDURE [dbo].[uploadAIX]

	

AS



BEGIN



	begin try

		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Lida\Max_VS_Qort.xlsx'

		declare @Sheet varchar(16) 

		declare @TodayDate date = getdate()

		declare @TodayDateInt int = cast(convert(varchar, @TodayDate, 112) as int)

		declare @Message varchar(1024)

		SET NOCOUNT ON



		declare @cmd varchar(255)

		declare @sql varchar(1024)





			set @Sheet = 'Sheet1'



		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			--IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL DROP TABLE #comms;

	

			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath  + '; HDR=YES;IMEX=0'',

				''SELECT * FROM [' + @Sheet + '$A1:D500]'')'



			exec(@sql)

			select * from ##comms 

	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		SET @Message = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
		PRINT @Message
		SEL
ECT @Message AS Result, 'red' AS ResultColor
	END CATCH
END

