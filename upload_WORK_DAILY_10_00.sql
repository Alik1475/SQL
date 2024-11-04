



-- exec QORT_ARM_SUPPORT.dbo.upload_WORK_DAILY_10_00

CREATE PROCEDURE [dbo].[upload_WORK_DAILY_10_00]



AS



BEGIN



	begin try

		declare @IP varchar(16) = '192.168.13.80'

		declare @Message varchar(1024)

		DECLARE @todayDate DATE = GETDATE()
        DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

		DECLARE @n INT = 0;

		declare @WaitCount int

		WHILE dbo.fIsBusinessDay(DATEADD(DAY, -1-@n, @todayDate)) = 0 

        BEGIN    

            SET @n = @n + 1;

        END

		DECLARE @ytdDate date = (DATEADD(DAY, -1-@n, @todayDate)) -- определили вчерашний бизнес день

        DECLARE @ytdDateint INT = CAST(CONVERT(VARCHAR, @ytdDate, 112) AS INT);



		--exec QORT_ARM_SUPPORT.dbo.UpdateCouponForREPO -- обнуление ставки и объема купоня для заведения пролонгации РЕПО

		--exec QORT_ARM_SUPPORT.dbo.DepoReconcil @sendmail = 1 -- сверка клиентских позиций с отправкой уведомления

		--exec QORT_ARM_SUPPORT.dbo.CheckRepoFor7daysCoupon @sendmail = 1 -- уведомление за 7 дней до выплаты купонов по открытым сделкам РЕПО

		--exec QORT_ARM_SUPPORT.dbo.AssetsRedemptionEmail @SendMail = 1 -- уведомление о купонах сегодня

		--exec QORT_ARM_SUPPORT.dbo.SalesUpdate -- обновление справочника "сейлзы для клиента"(аналитические субсчета для разграничения прав)

		--exec QORT_ARM_SUPPORT..BDP_FlaskRequest -- обновление QORT_arm_sUPPORT.DBO.BloombergData данными из блумберг(справочник ценных бумаг)



		----------------------------------------------------------------------------------------------------------------------------------------

		if (isnull((select top 1 found from QORT_ARM_SUPPORT.dbo.BloombergData where Date = @todayInt and Code = 'US0378331005 EQUITY'),0) = 1) begin

			exec QORT_ARM_SUPPORT.dbo.ReconcilAssetsBloomberg -- сверка справочника ЦБ Qort и Bloomberg

			exec QORT_ARM_SUPPORT.dbo.upload_MarketInfo @IP, @IsinCode = 'US0378331005 EQUITY'

					set @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили котировку----------------------

					while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.ImportMarketInfo q with (nolock) where q.IsProcessed in (1,2)))

					begin

						waitfor delay '00:00:03'

						set @WaitCount = @WaitCount - 1

					end

			if (isnull((select top 1 LastPrice from QORT_BACK_DB..MarketInfoHist where modified_date = @todayInt and Asset_ID = 217 and TSSection_ID = 154 and OldDate = @ytdDateint),0) > 0) begin

				exec QORT_ARM_SUPPORT.dbo.upload_MarketInfo @IP, @IsinCode = NULL -- загрузка котировок из Блумберга в Qort

				 print 'connect server:' + @IP

				 end

				 else print 'dont connect server:' + @IP

		  end

		  else print 'dont connect server'

		  --------------------------------------------------------------------------------------------------------------------------------------

	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

