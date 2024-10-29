



-- exec QORT_ARM_SUPPORT.dbo.upload_DAILY_10_minutes

CREATE PROCEDURE [dbo].[upload_DAILY_10_minutes]



AS



BEGIN



	begin try



		declare @Message varchar(1024)



		--exec QORT_ARM_SUPPORT.dbo.upload_Deals

		exec QORT_ARM_SUPPORT.dbo.upload_NTTs -- загрузка non-trade transaction

		--exec QORT_ARM_SUPPORT.dbo.upload_Commissions

		exec QORT_ARM_SUPPORT.dbo.upload_Conversions

		--exec QORT_ARM_SUPPORT.dbo.upload_TradeInstructions

		--exec QORT_ARM_SUPPORT.dbo.upload_ClientsUnicode	

		exec QORT_ARM_SUPPORT.dbo.BonusFromPhaseToTradeForm -- добавление значения бонуса в сделку для отражения в отчете

		exec QORT_ARM_SUPPORT.dbo.OrdersUpdate -- обновление реестра ордеров(инфо о пользователе, статусе)

		exec QORT_ARM_SUPPORT.dbo.CheckClientsTerminated -- уведомление о закрытии счета

		exec QORT_ARM_SUPPORT.dbo.CheckTradeAssetsSanction -- отправка уведомлений о сделках с бумагами в санкционном списке

		exec QORT_ARM_SUPPORT.dbo.upload_Reconcilation  -- загрузка файлов для сверки с Армсофт/Деполайт/Депенд/Ексель

		exec QORT_ARM_SUPPORT.dbo.SalesUpdate -- обновление справочника "сейлзы для клиента"(аналитические субсчета для разграничения прав)

		exec QORT_ARM_SUPPORT.dbo.uploadAIX -- загрузка сделок AIX

		exec QORT_ARM_SUPPORT..BlockingForOrders -- блокировка денежных средств(make CorrectPosition) под ордера с признаком

		exec QORT_ARM_SUPPORT.dbo.CorrectPositionForAlertMoney -- аллерт про пополнение счета клиента

		exec QORT_ARM_SUPPORT.dbo.CheckClientsTariff -- уведомление об изменении тарифного плана у клиента.



	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

