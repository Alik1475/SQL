



-- exec QORT_ARM_SUPPORT.dbo.upload_DAILY_16_00

create PROCEDURE [dbo].[upload_DAILY_16_00]



AS



BEGIN



	begin try



		declare @Message varchar(1024)



		

		exec QORT_ARM_SUPPORT.dbo.DepoReconcil @sendmail = 1 -- сверка клиентских позиций с отправкой уведомления



	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

