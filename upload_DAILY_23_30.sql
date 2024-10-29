



-- exec QORT_ARM_SUPPORT_TEST.dbo.upload_DAILY_23_30

CREATE PROCEDURE [dbo].[upload_DAILY_23_30]



AS



BEGIN



	begin try



		declare @Message varchar(1024)



		

		--exec QORT_ARM_SUPPORT_TEST.dbo.AB0001Correction -- обнуление собственной позиции Армброк 

		exec QORT_ARM_SUPPORT_TEST.dbo.ChangeCurrent -- формирование и загрузка сделок конвертаций под списание брокерской комиссии.





	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

