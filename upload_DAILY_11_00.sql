



-- exec QORT_ARM_SUPPORT.dbo.upload_DAILY_11_00

CREATE PROCEDURE [dbo].[upload_DAILY_11_00]



AS



BEGIN



	begin try



		declare @Message varchar(1024)



		--exec QORT_ARM_SUPPORT.dbo.UpdateCouponForREPO -- обнуление ставки и объема купоня для заведения пролонгации РЕПО после доработкт Аркой не используется

		exec QORT_ARM_SUPPORT.dbo.DepoReconcil @sendmail = 1 -- сверка клиентских позиций с отправкой уведомления

		exec QORT_ARM_SUPPORT.dbo.CheckRepoFor7daysCoupon @sendmail = 1 -- уведомление за 7 дней до выплаты купонов по открытым сделкам РЕПО

		exec QORT_ARM_SUPPORT.dbo.AssetsRedemptionEmail @SendMail = 1 -- уведомление о купонах сегодня

		exec QORT_ARM_SUPPORT.dbo.SalesUpdate -- обновление справочника "сейлзы для клиента"(аналитические субсчета для разграничения прав)

	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

