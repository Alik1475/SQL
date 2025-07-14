



-- exec QORT_ARM_SUPPORT.dbo.upload_DAILY_11_00

CREATE PROCEDURE [dbo].[upload_DAILY_11_00]



AS



BEGIN



	begin try



		declare @Message varchar(1024)



		-----------------------------процедуры запускаемые по армянскому календарю праздников--------------------------------

						  IF QORT_ARM_SUPPORT.dbo.fIsBusinessDay(GETDATE()) = 1
				BEGIN
				
				exec QORT_ARM_SUPPORT.dbo.DepoReconcil @sendmail = 1 -- сверка клиентских позиций с отправкой уведомления
				exec QORT_ARM_SUPPORT.dbo.Portfolio_Valuation_email -- ежедневны
й отчет по оценке портфеля клиента (фонды Glocal) (PM-15)
				END
				ELSE
				BEGIN
					PRINT 'Сегодня праздник. Задание не будет выполняться.';
				END;



------------------------------------------------------------------------------------------------------------------------------



		--exec QORT_ARM_SUPPORT.dbo.UpdateCouponForREPO -- обнуление ставки и объема купоня для заведения пролонгации РЕПО после доработкт Аркой не используется

		

		exec QORT_ARM_SUPPORT.dbo.CheckRepoFor7daysCoupon @sendmail = 1 -- уведомление за 7 дней до выплаты купонов по открытым сделкам РЕПО + OPTIONS

		exec QORT_ARM_SUPPORT.dbo.AssetsRedemptionEmail @SendMail = 1 -- уведомление о купонах сегодня

		exec QORT_ARM_SUPPORT.dbo.SalesUpdate -- обновление справочника "сейлзы для клиента"(аналитические субсчета для разграничения прав)

		exec QORT_ARM_SUPPORT.dbo.Alert_TerminationDate -- уведомление о закрытии счета через 3 рабочих дня

		exec QORT_ARM_SUPPORT.dbo.Alert_POA_DateEnd -- уведомление об окончании срока дествия доверенностей за 3 рабочих дня

		

	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

