



-- exec QORT_ARM_SUPPORT.dbo.upload_DAILY_05_minutes

CREATE PROCEDURE [dbo].[upload_DAILY_05_minutes]



AS



BEGIN



	begin try



		declare @Message varchar(1024)



		exec QORT_ARM_SUPPORT..API_Raif

		



	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

