



-- exec QORT_ARM_SUPPORT_TEST.dbo.upload_DAILY_23_15

CREATE PROCEDURE [dbo].[upload_DAILY_23_15]



AS



BEGIN



	begin try



		declare @Message varchar(1024)



		

		exec QORT_ARM_SUPPORT_TEST.dbo.updateBrokCommission -- округление начисленной комиссии и выравнивание к 5000 комиссий АМХ

		--exec QORT_ARM_SUPPORT_TEST..UPLOAD_MarketData_CBA -- загрузка котировок из по бумагам из списка ЦБ РА





	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END
