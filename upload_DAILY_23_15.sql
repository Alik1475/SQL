



-- exec QORT_ARM_SUPPORT.dbo.upload_DAILY_23_15

CREATE PROCEDURE [dbo].[upload_DAILY_23_15]



AS



BEGIN



	begin try



		declare @Message varchar(1024)



		

		exec QORT_ARM_SUPPORT.dbo.updateBrokCommission -- округление начисленной комиссии и выравнивание к 5000 комиссий АМХ

		exec QORT_ARM_SUPPORT..UPLOAD_MarketData_CBA -- загрузка котировок из по бумагам из списка ЦБ РА

		exec QORT_ARM_SUPPORT..UPLOAD_MarketData_AMX -- загрузка котировок по файлу с AMX

		exec QORT_ARM_SUPPORT..UPLOAD_MarketData_CBONDS -- загрузка котировок по файлу с CBONDS



	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

