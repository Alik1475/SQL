



-- exec QORT_ARM_SUPPORT_TEST.dbo.upload_DAILY_5_minutes

CREATE PROCEDURE [dbo].[upload_DAILY_5_minutes]



AS



BEGIN



	begin try



		declare @Message varchar(1024)



		--exec QORT_ARM_SUPPORT_TEST..TestFlaskRequest_TEST -- raiffeizeb update

		exec QORT_ARM_SUPPORT_TEST..API_Raif



	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

