



-- exec QORT_ARM_SUPPORT.dbo.upload_DAILY_16_00

CREATE PROCEDURE [dbo].[upload_DAILY_16_00]



AS



BEGIN



	begin try



		declare @Message varchar(1024)

-----------------------------процедуры запускаемые по армянскому календарю праздников--------------------------------

		  IF NOT EXISTS (
    SELECT 1
    FROM QORT_BACK_DB.dbo.CalendarDates
    WHERE Date =  cast(convert(varchar, GETDATE(), 112) as int)
)
BEGIN

exec QORT_ARM_SUPPORT.dbo.DepoReconcil @sendmail = 1 -- сверка клиентских позиций с отправкой уведомления

EN
D
ELSE
BEGIN
    PRINT 'Сегодня праздник. Задание не будет выполняться.';
END;



------------------------------------------------------------------------------------------------------------------------------

		exec QORT_ARM_SUPPORT.dbo.BirthdayClients -- рассылка сейлзам информации про дни рождения



	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

