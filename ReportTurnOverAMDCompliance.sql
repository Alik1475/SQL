/*

SELECT 

    p.name AS ProcedureName, 

    m.definition 

FROM sys.procedures p

JOIN sys.sql_modules m ON p.object_id = m.object_id

WHERE m.definition LIKE '%exec QORT_ARM_SUPPORT.dbo.ReportTurnOverAMDCompliance%';

*/





/*

	declare @OutputParam1 float

	declare @OutputParam2 float

 exec QORT_ARM_SUPPORT.dbo.ReportTurnOverAMDCompliance @DataFrom = '2024-12-31', @DataTo = '2024-12-31', @SubAccCode = 'AS1105', @OutputParam = @OutputParam1 OUTPUT ,@OutputParamCL = @OutputParam2 OUTPUT

print @OutputParam1 print @OutputParam2





*/

CREATE PROCEDURE [dbo].[ReportTurnOverAMDCompliance]

	  @DataFrom date, --= '2023-01-01',

      @DataTo date,-- = '2024-01-01'

	  @SubAccCode varchar(50),

	  @OutputParam float output, 

	  @OutputParamCL float output 

AS



BEGIN



	begin try

		declare @DataFromint int = cast(convert(varchar, @DataFrom, 112) as int)

		declare @DataToInt int = cast(convert(varchar, @DataTo, 112) as int)

		declare @Message varchar(1024)

		set @OutputParamCL = 0

	----------------набираем сделки в сумме по контрагенту

					IF OBJECT_ID('tempdb..#t2', 'U') IS NOT NULL DROP TABLE #t2

			

				select 
						tra.CpFirm_ID, 
						--tra.Volume1, 
						--tra.CurrPayAsset_ID, 
						--tra.TradeDate AS TrDate, 
						--isnull(crs.bid, 1) AS RatesAMD,
					SUM(tra.Volume1 * ISNULL(crs.bid, 1)) AS Volume_AMD
				INTO #t2
				FROM 
					QORT_BACK_
DB..Trades tra
				OUTER APPLY (
					SELECT TOP 1 *
					FROM QORT_BACK_DB..CrossRatesHist crs 
					WHERE 
						crs.TradeAsset_ID = tra.CurrPayAsset_ID 
						AND crs.OldDate = tra.TradeDate 
						AND crs.PriceAsset_ID = 17
				) crs
				WHERE tra.VT_
Const NOT IN (12, 10)
					AND tra.NullStatus = 'n'
					and tra.TradeDate < @DataToInt
					and tra.TradeDate > @DataFromint
					AND tra.CpTrade_ID < 0 
					AND tra.Enabled = 0 
					AND tra.TSSection_ID NOT IN (155) 
					AND tra.SubAcc_ID = 2
				GRO
UP BY 
					tra.CpFirm_ID;

					--select * from #t2

					---------------------------------набираем суммаы по фазам под сделками по клиентам------------------

					IF OBJECT_ID('tempdb..#t3', 'U') IS NOT NULL DROP TABLE #t3

					SELECT 

						pha.SubAcc_ID,

						SUM(IIF(ass.AssetType_Const = 1, 

								IIF(tra1.CurrPriceAsset_ID = 17, 1, crsTR.Bid) * pha.qtyBefore, 

								IIF(pha.PhaseAsset_ID = 17, 1, crsPH.Bid) * pha.qtyBefore)) AS volumeAMD

					into #t3

					FROM 

						QORT_BACK_DB..Phases pha

					LEFT OUTER JOIN 

						QORT_BACK_DB..Assets ass ON ass.id = pha.PhaseAsset_ID

					LEFT OUTER JOIN 

						QORT_BACK_DB..Trades tra1 ON tra1.id = pha.Trade_ID

					OUTER APPLY (

						SELECT TOP 1 *

						FROM QORT_BACK_DB..CrossRatesHist crs 

						WHERE 

							crs.TradeAsset_ID = tra1.CurrPriceAsset_ID

							AND crs.OldDate = pha.PhaseDate 

							AND crs.PriceAsset_ID = 17

					) crsTR

					OUTER APPLY (

						SELECT TOP 1 *

						FROM QORT_BACK_DB..CrossRatesHist crs 

						WHERE 

							crs.TradeAsset_ID = pha.PhaseAsset_ID

							AND crs.OldDate = pha.PhaseDate

							AND crs.PriceAsset_ID = 17

					) crsPH

					WHERE 

						pha.PC_Const NOT IN (2, 15, 17, 18, 26, 27, 29, 20, 35, 34)

						AND pha.PhaseDate < @DataToInt 

						AND pha.PhaseDate > @DataFromint

						AND pha.IsCanceled = 'n'

						AND pha.SubAcc_ID NOT IN (2)

					GROUP BY 

						pha.SubAcc_ID;

						--select * from #t3





						---------------------------------набираем суммаы по корректировкам  по клиентам------------------

						IF OBJECT_ID('tempdb..#t4', 'U') IS NOT NULL DROP TABLE #t4;

							WITH VolumeCalculation AS (

										SELECT 

											cor.Subacc_ID AS SubAccID,

											ISNULL(

												CASE 

													WHEN asse.AssetType_Const IN (1) THEN 

														CASE 

															WHEN asse.AssetClass_Const IN (2, 6, 7, 9) THEN 

																asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1, crsCrA.Bid)

															ELSE 

																



																	(SELECT COALESCE(
    (
        SELECT TOP 1
          IIF(isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) = 0, NULL , isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0))  AS Rate
     
   FROM 
            QORT_BACK_DB..MarketInfoHist mar
        OUTER APPLY (
            SELECT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = mar.PriceAsset_ID
                AND crs.OldD
ate =  Cor.RegistrationDate
                AND crs.PriceAsset_ID = 17
                AND InfoSource = 'CBA'
        ) crsCrTra
        WHERE 
            mar.TSSection_ID = 154 -- 'OTC_Securities'
            AND mar.Asset_ID = cor.Asset_ID
            
AND mar.OldDate = Cor.RegistrationDate
    ), 
    (
        SELECT TOP 1
            IIF(isnull(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) = 0, NULL , isnull(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 
0))  AS Rate
        FROM 
            QORT_BACK_DB..MarketInfoHist mar
        OUTER APPLY (
            SELECT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = mar.PriceAsset_ID
          
      AND crs.OldDate = Cor.RegistrationDate
                AND crs.PriceAsset_ID = 17
                AND InfoSource = 'CBA'
        ) crsCrTra
        WHERE 
            mar.TSSection_ID = 165 -- 'OTC_SWAP'
            AND mar.Asset_ID = cor.Asset_ID
 
           AND mar.OldDate = Cor.RegistrationDate
    )
	, 
    (
        -- Третье выражение (BaseValue)
        SELECT 
            asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1, crsCrA.Bid) AS Rate
        FROM 
            QORT_BACK_DB..Asset
s asse
        OUTER APPLY (
            SELECT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = asse.BaseCurrencyAsset_ID
                AND crs.OldDate = Cor.RegistrationDate
            
    AND crs.PriceAsset_ID = 17
                AND InfoSource = 'CBA'
        ) crsCrA
        WHERE 
            asse.ID = cor.Asset_ID
    )
	)

							)							END

													ELSE 

														IIF(cor.Asset_ID = 17, 1, crsCrP.bid)

												END, 0

											)    * iif(cor.Size < 0, cor.Size*(-1), cor.Size )

											AS VolumeAMD

										FROM 

											QORT_BACK_DB.dbo.CorrectPositions cor

										LEFT OUTER JOIN 

											QORT_BACK_DB.dbo.Assets asse ON asse.id = cor.Asset_ID

										OUTER APPLY (

											SELECT TOP 1 *

											FROM QORT_BACK_DB..CrossRatesHist crs 

											WHERE 

												crs.TradeAsset_ID = cor.Asset_ID

												AND crs.OldDate = cor.RegistrationDate

												AND crs.PriceAsset_ID = 17

										) crsCrP

										OUTER APPLY (

											SELECT TOP 1 *

											FROM QORT_BACK_DB..CrossRatesHist crs 

											WHERE 

												crs.TradeAsset_ID = asse.BaseCurrencyAsset_ID

												AND crs.OldDate = cor.RegistrationDate

												AND crs.PriceAsset_ID = 17

										) crsCrA

										WHERE 

											cor.Enabled = 0

											AND cor.IsCanceled = 'n'

											AND cor.RegistrationDate < @DataToInt

											AND cor.RegistrationDate > @DataFromint

											AND cor.CT_Const NOT IN (12)

											AND cor.Subacc_ID NOT IN (2)

											AND asse.AssetType_Const = 1

									)



									SELECT 

										SubAccID,

										SUM(VolumeAMD) AS TotalVolumeAMD



									INTO #t4



									FROM 

										VolumeCalculation

									GROUP BY 

										SubAccID;



									--	select * from #t4



---------------------------- с обнулением по деньгам-----------------------

	IF OBJECT_ID('tempdb..#t5', 'U') IS NOT NULL DROP TABLE #t5

					SELECT 

						pha.SubAcc_ID,

						SUM(IIF(ass.AssetType_Const = 1, 

								IIF(tra1.CurrPriceAsset_ID = 17, 1, crsTR.Bid) * pha.qtyBefore, 

								IIF(pha.PhaseAsset_ID = 17, 1, crsPH.Bid) * pha.qtyBefore * 0)) AS volumeAMD_Depo

					into #t5

					FROM 

						QORT_BACK_DB..Phases pha

					LEFT OUTER JOIN 

						QORT_BACK_DB..Assets ass ON ass.id = pha.PhaseAsset_ID

					LEFT OUTER JOIN 

						QORT_BACK_DB..Trades tra1 ON tra1.id = pha.Trade_ID

					OUTER APPLY (

						SELECT TOP 1 *

						FROM QORT_BACK_DB..CrossRatesHist crs 

						WHERE 

							crs.TradeAsset_ID = tra1.CurrPriceAsset_ID

							AND crs.OldDate = pha.PhaseDate 

							AND crs.PriceAsset_ID = 17

					) crsTR

					OUTER APPLY (

						SELECT TOP 1 *

						FROM QORT_BACK_DB..CrossRatesHist crs 

						WHERE 

							crs.TradeAsset_ID = pha.PhaseAsset_ID

							AND crs.OldDate = pha.PhaseDate

							AND crs.PriceAsset_ID = 17

					) crsPH

					WHERE 

						pha.PC_Const NOT IN (2, 15, 17, 18, 26, 27, 29, 20, 35, 34)

						AND pha.PhaseDate < @DataToInt 

						AND pha.PhaseDate > @DataFromint

						AND pha.IsCanceled = 'n'

						AND pha.SubAcc_ID NOT IN (2)

					GROUP BY 

						pha.SubAcc_ID;

						--select * from #t5

									---------------------------------набираем суммаы по корректировкам  по клиентам c обнулением------------------

						IF OBJECT_ID('tempdb..#t6', 'U') IS NOT NULL DROP TABLE #t6;

							WITH VolumeCalculation AS (

										SELECT 

											cor.Subacc_ID AS SubAccID,

											ISNULL(

												CASE 

													WHEN asse.AssetType_Const IN (1) THEN 

														CASE 

															WHEN asse.AssetClass_Const IN (2, 6, 7, 9) THEN 

																asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1, crsCrA.Bid)

															ELSE 

																



																	(SELECT COALESCE(
    (
        SELECT TOP 1
           IIF( isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) = 0, NULL , isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0)) AS Rate
   
     FROM 
            QORT_BACK_DB..MarketInfoHist mar
        OUTER APPLY (
            SELECT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = mar.PriceAsset_ID
                AND crs.Ol
dDate = Cor.RegistrationDate
                AND crs.PriceAsset_ID = 17
                AND InfoSource = 'CBA'
        ) crsCrTra
        WHERE 
            mar.TSSection_ID = 154 -- 'OTC_Securities'
            AND mar.Asset_ID = cor.Asset_ID
           
 AND mar.OldDate = Cor.RegistrationDate
    ), 
    (
        SELECT TOP 1
            IIF(isnull(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) = 0, NULL , isnull(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid),
 0)) AS Rate
        FROM 
            QORT_BACK_DB..MarketInfoHist mar
        OUTER APPLY (
            SELECT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = mar.PriceAsset_ID
          
      AND crs.OldDate = Cor.RegistrationDate
                AND crs.PriceAsset_ID = 17
                AND InfoSource = 'CBA'
        ) crsCrTra
        WHERE 
            mar.TSSection_ID = 165 -- 'OTC_SWAP'
            AND mar.Asset_ID = cor.Asset_ID
 
           AND mar.OldDate = Cor.RegistrationDate
    )
	, 
    (
        -- Третье выражение (BaseValue)
        SELECT 
            asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1, crsCrA.Bid) AS Rate
        FROM 
            QORT_BACK_DB..Asset
s asse
        OUTER APPLY (
            SELECT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = asse.BaseCurrencyAsset_ID
                AND crs.OldDate = Cor.RegistrationDate
            
    AND crs.PriceAsset_ID = 17
                AND InfoSource = 'CBA'
        ) crsCrA
        WHERE 
            asse.ID = cor.Asset_ID
    )
	)

							)							END

													ELSE 

														IIF(cor.Asset_ID = 17, 1, crsCrP.bid)

												END, 0

											)    * iif(cor.Size < 0, cor.Size*(-1), cor.Size )

											AS VolumeAMD

										FROM 

											QORT_BACK_DB.dbo.CorrectPositions cor

										LEFT OUTER JOIN 

											QORT_BACK_DB.dbo.Assets asse ON asse.id = cor.Asset_ID

										OUTER APPLY (

											SELECT TOP 1 *

											FROM QORT_BACK_DB..CrossRatesHist crs 

											WHERE 

												crs.TradeAsset_ID = cor.Asset_ID

												AND crs.OldDate = cor.RegistrationDate

												AND crs.PriceAsset_ID = 17

										) crsCrP

										OUTER APPLY (

											SELECT TOP 1 *

											FROM QORT_BACK_DB..CrossRatesHist crs 

											WHERE 

												crs.TradeAsset_ID = asse.BaseCurrencyAsset_ID

												AND crs.OldDate = cor.RegistrationDate

												AND crs.PriceAsset_ID = 17

										) crsCrA

										WHERE 

											cor.Enabled = 0

											AND cor.IsCanceled = 'n'

											AND cor.RegistrationDate < @DataToInt

											AND cor.RegistrationDate > @DataFromint

											AND cor.CT_Const NOT IN (12)

											AND cor.Subacc_ID NOT IN (2)

											AND asse.AssetType_Const = 1

									)



									SELECT 

										SubAccID,

										SUM(VolumeAMD) AS TotalVolumeAMD



									INTO #t6



									FROM 

										VolumeCalculation

									GROUP BY 

										SubAccID;

										---------------------------------набираем суммаы по остстакам  по клиентам c обнулением------------------

								IF OBJECT_ID('tempdb..#t7', 'U') IS NOT NULL DROP TABLE #t7;

							WITH VolumeCalculation1 AS (

										SELECT 

											pos.Subacc_ID AS SubAccID,

											ISNULL(

												CASE 

													WHEN asse.AssetType_Const IN (1) THEN 

														CASE 

															WHEN asse.AssetClass_Const IN (2, 6, 7, 9) THEN 

																asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1, crsCrA.Bid)

															ELSE 

																



																	(SELECT COALESCE(

    (

        SELECT TOP 1

            IIF(isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) = 0 , NULL, isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0))  AS Rate

        FROM 

            QORT_BACK_DB..MarketInfoHist mar

        OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB..CrossRatesHist crs 

            WHERE 

                crs.TradeAsset_ID = mar.PriceAsset_ID

                AND crs.OldDate = @DataToInt

                AND crs.PriceAsset_ID = 17

                AND InfoSource = 'CBA'

        ) crsCrTra

        WHERE 

            mar.TSSection_ID = 154 -- 'OTC_Securities'

            AND mar.Asset_ID = pos.Asset_ID

            AND mar.OldDate = @DataToInt

    ), 

    (

        SELECT TOP 1

           IIF( isnull(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) = 0 , NULL ,  isnull(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0)) AS Rate

        FROM 

            QORT_BACK_DB..MarketInfoHist mar

        OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB..CrossRatesHist crs

            WHERE 

                crs.TradeAsset_ID = mar.PriceAsset_ID

                AND crs.OldDate = @DataToInt

                AND crs.PriceAsset_ID = 17

                AND InfoSource = 'CBA'

        ) crsCrTra

        WHERE 

            mar.TSSection_ID = 165 -- 'OTC_SWAP'

            AND mar.Asset_ID = pos.Asset_ID

            AND mar.OldDate = @DataToInt

    )

	, 

    (

        -- Третье выражение (BaseValue)

        SELECT 

            asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1, crsCrA.Bid) AS Rate

        FROM 

            QORT_BACK_DB..Assets asse

        OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB..CrossRatesHist crs 

            WHERE 

                crs.TradeAsset_ID = asse.BaseCurrencyAsset_ID

                AND crs.OldDate = @DataToInt

                AND crs.PriceAsset_ID = 17

                AND InfoSource = 'CBA'

        ) crsCrA

        WHERE 

            asse.ID = pos.Asset_ID

    )

	)

							)							END

													ELSE 

														IIF(pos.Asset_ID = 17, 1, crsCrP.bid)

												END, 0

											)    * iif(pos.volfree < 0, 0, pos.VolFree )

											AS VolumeAMD

										FROM 

											QORT_BACK_DB.dbo.PositionHist pos

										LEFT OUTER JOIN 

											QORT_BACK_DB.dbo.Assets asse ON asse.id = pos.Asset_ID

										OUTER APPLY (

											SELECT TOP 1 *

											FROM QORT_BACK_DB..CrossRatesHist crs 

											WHERE 

												crs.TradeAsset_ID = pos.Asset_ID

												AND crs.OldDate = @DataToInt

												AND crs.PriceAsset_ID = 17

										) crsCrP

										OUTER APPLY (

											SELECT TOP 1 *

											FROM QORT_BACK_DB..CrossRatesHist crs 

											WHERE 

												crs.TradeAsset_ID = asse.BaseCurrencyAsset_ID

												AND crs.OldDate = @DataToInt

												AND crs.PriceAsset_ID = 17

										) crsCrA

										WHERE 

											pos.Date = @DataToInt and pos.VolFree > 0

									)



									SELECT 

										SubAccID,

										SUM(VolumeAMD) AS TotalVolumeAMD



									INTO #t7



									FROM 

										VolumeCalculation1

									GROUP BY 

										SubAccID;



									--	select * from #t7 order by SubAccID desc return

										---------------------------------набираем суммаы по остаткам в разбивке по местам хранения по клиентам ------------------

								IF OBJECT_ID('tempdb..#t8', 'U') IS NOT NULL DROP TABLE #t8;

							WITH VolumeCalculation1 AS (

										SELECT 

											pos.Subacc_ID AS SubAccID,

											pos.Account_ID as Account_ID,

											ISNULL(

												CASE 

													WHEN asse.AssetType_Const IN (1) THEN 

														CASE 

															WHEN asse.AssetClass_Const IN (2, 6, 7, 9) THEN 

																asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1, crsCrA.Bid)

															ELSE 

																



																	(SELECT COALESCE(

    (

        SELECT TOP 1

            IIF(isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) = 0 , NULL, isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0))  AS Rate

        FROM 

            QORT_BACK_DB..MarketInfoHist mar

        OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB..CrossRatesHist crs 

            WHERE 

                crs.TradeAsset_ID = mar.PriceAsset_ID

                AND crs.OldDate = @DataToInt

                AND crs.PriceAsset_ID = 17

                AND InfoSource = 'CBA'

        ) crsCrTra

        WHERE 

            mar.TSSection_ID = 154 -- 'OTC_Securities'

            AND mar.Asset_ID = pos.Asset_ID

            AND mar.OldDate = @DataToInt

    ), 

    (

        SELECT TOP 1

           IIF( isnull(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) = 0 , NULL ,  isnull(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0)) AS Rate

        FROM 

            QORT_BACK_DB..MarketInfoHist mar

        OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB..CrossRatesHist crs

            WHERE 

                crs.TradeAsset_ID = mar.PriceAsset_ID

                AND crs.OldDate = @DataToInt

                AND crs.PriceAsset_ID = 17

                AND InfoSource = 'CBA'

        ) crsCrTra

        WHERE 

            mar.TSSection_ID = 165 -- 'OTC_SWAP'

            AND mar.Asset_ID = pos.Asset_ID

            AND mar.OldDate = @DataToInt

    )

	, 

    (

        -- Третье выражение (BaseValue)

        SELECT 

            asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1, crsCrA.Bid) AS Rate

        FROM 

            QORT_BACK_DB..Assets asse

        OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB..CrossRatesHist crs 

            WHERE 

                crs.TradeAsset_ID = asse.BaseCurrencyAsset_ID

                AND crs.OldDate = @DataToInt

                AND crs.PriceAsset_ID = 17

                AND InfoSource = 'CBA'

        ) crsCrA

        WHERE 

            asse.ID = pos.Asset_ID

    )

	)

							)							END

													ELSE 

														IIF(pos.Asset_ID = 17, 1, crsCrP.bid)

												END, 0

											)    * iif(pos.volfree < 0, 0, pos.VolFree )

											AS VolumeAMD

										FROM 

											QORT_BACK_DB.dbo.PositionHist pos

										LEFT OUTER JOIN 

											QORT_BACK_DB.dbo.Assets asse ON asse.id = pos.Asset_ID

										OUTER APPLY (

											SELECT TOP 1 *

											FROM QORT_BACK_DB..CrossRatesHist crs 

											WHERE 

												crs.TradeAsset_ID = pos.Asset_ID

												AND crs.OldDate = @DataToInt

												AND crs.PriceAsset_ID = 17

										) crsCrP

										OUTER APPLY (

											SELECT TOP 1 *

											FROM QORT_BACK_DB..CrossRatesHist crs 

											WHERE 

												crs.TradeAsset_ID = asse.BaseCurrencyAsset_ID

												AND crs.OldDate = @DataToInt

												AND crs.PriceAsset_ID = 17

										) crsCrA

										WHERE 

											pos.Date = @DataToInt and pos.VolFree > 0

									)



									SELECT 

										SubAccID,Account_ID,

										SUM(VolumeAMD) AS TotalVolumeAMD



									INTO #t8



									FROM 

										VolumeCalculation1

									GROUP BY 

										SubAccID, Account_ID;



									--	select * from #t8 order by SubAccID desc--return

										
										
	IF OBJECT_ID('tempdb..#t9', 'U') IS NOT NULL DROP TABLE #t9;
	CREATE TABLE #t9 (
    SubAccID INT,
    ArmBrok_Mn_Client FLOAT DEFAULT 0,

    CLIENT_CDA_Own FLOAT DEFAULT 0,

    ARMBR_DEPO_BTA FLOAT DEFAULT 0,

    ARMBR_DEPO_MAREX FLOAT DEFAULT 0,

    ARMBR_DEPO FLOAT DEFAULT 0,

    ARMBR_DEPO_GTN FLOAT DEFAULT 0,

    ARMBR_DEPO_MAD FLOAT DEFAULT 0,

    ARMBR_DEPO_AIX FLOAT DEFAULT 0,

    ARMBR_DEPO_RON FLOAT DEFAULT 0,

    ARMBR_DEPO_MTD FLOAT DEFAULT 0,

    ARMBR_DEPO_HFN FLOAT DEFAULT 0,

    ARMBR_DEPO_GPP FLOAT DEFAULT 0,

    ARMBR_MONEY_BLOCK FLOAT DEFAULT 0,

    CLIENT_CDA_Own_Frozen FLOAT DEFAULT 0,

    ARMBR_DEPO_ALOR_PLUS FLOAT DEFAULT 0,

	OTHER FLOAT DEFAULT 0


);
	INSERT INTO #t9 (
    SubAccID,
    ArmBrok_Mn_Client,
    CLIENT_CDA_Own,
	CLIENT_CDA_Own_Frozen,
    ARMBR_DEPO_BTA,
    ARMBR_DEPO_MAREX,
    ARMBR_DEPO,
    ARMBR_DEPO_GTN,
    ARMBR_DEPO_MAD,
    ARMBR_DEPO_AIX,
    ARMBR_DEPO_RON,
    ARMBR_DEP
O_MTD,
    ARMBR_DEPO_HFN,
    ARMBR_DEPO_GPP,
    ARMBR_MONEY_BLOCK,
    ARMBR_DEPO_ALOR_PLUS,
	OTHER
)
SELECT 
    SubAccID,
    MAX(CASE WHEN Account_ID = 3 THEN TotalVolumeAMD ELSE 0 END) AS ArmBrok_Mn_Client,
    MAX(CASE WHEN Account_ID = 4 THEN Tot
alVolumeAMD ELSE 0 END) AS CLIENT_CDA_Own,
	MAX(CASE WHEN Account_ID = 171 THEN TotalVolumeAMD ELSE 0 END) AS CLIENT_CDA_Own_Frozen,
    MAX(CASE WHEN Account_ID = 29 THEN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_BTA,
    MAX(CASE WHEN Account_ID = 176 TH
EN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_MAREX,
    MAX(CASE WHEN Account_ID = 2 THEN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO,
    MAX(CASE WHEN Account_ID = 173 THEN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_GTN,
    MAX(CASE WHEN Account_ID = 174 THE
N TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_MAD,
    MAX(CASE WHEN Account_ID = 172 THEN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_AIX,
    MAX(CASE WHEN Account_ID = 22 THEN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_RON,
    MAX(CASE WHEN Account_ID = 19 TH
EN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_MTD,
    MAX(CASE WHEN Account_ID = 34 THEN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_HFN,
    MAX(CASE WHEN Account_ID = 33 THEN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_GPP,
    MAX(CASE WHEN Account_ID = 32 TH
EN TotalVolumeAMD ELSE 0 END) AS ARMBR_MONEY_BLOCK,
    MAX(CASE WHEN Account_ID = 180 THEN TotalVolumeAMD ELSE 0 END) AS ARMBR_DEPO_ALOR_PLUS,
	    SUM(
        CASE 
            WHEN Account_ID NOT IN (3, 4, 171, 29, 176, 2, 173, 174, 172, 22, 19, 34, 3
3, 32, 180) THEN TotalVolumeAMD
            ELSE 0
        END
    ) AS OTHER
FROM #t8
GROUP BY SubAccID;



--select * from #t9 order by SubAccID desc 

--return

										-------------------------------------------------------------- основной запрос------------------------------

					IF OBJECT_ID('tempdb..##t', 'U') IS NOT NULL DROP TABLE ##t

					select fir.Name BPName

					, cl.DateSign DateSign

					, cl.DateCreate DateCreate

					

					, sub.SubAccCode

					, fir.IsFirm IsLegal_y

					, isnull(countR.Name, 'Unfilled') Resident

					, isnull(countA.Name, 'Unfilled') ResidentDoc

					, isnull(org.Name, 'Unfilled') Russian_nonrussian

					, iif((select  * from dbo.FFGetIncludedFlags(fir.ff_flags) where flagname =  'FF_PEP') is null, 'no', 'YES') PEP

					, case when fir.CRS_Const = 1 then 'Financial Institution'

						   when fir.CRS_Const = 2 then 'Active NonFinancial Entity'

						   when fir.CRS_Const = 3 then 'Passive NonFinancial Entity'

						   else '	Not chosen' 

						   end 

	   						CRS_status

					, case when fir.RiskLevel = 2 then 'Medium'

						   when fir.RiskLevel = 3 then 'Low'

						   when fir.RiskLevel = 4 then 'High'

						   when fir.RiskLevel = 5 then 'Medium Low'

						   when fir.RiskLevel = 6 then 'Automatic High'

						   when fir.RiskLevel = 7 then 'Extreme'

						   when fir.RiskLevel = 8 then 'Initial'

						   else '	N/A' 

						   end 

	   						RiskLevel

					, iif((select * from dbo.FTGetIncludedFlags(fir.FT_Flags) where flagname =  'FT_CLIENT') is null, 'no', 'YES') IsClient

					, iif((select * from dbo.FTGetIncludedFlags(fir.FT_Flags) where flagname =  'FT_CPARTY') is null, 'no', 'YES') IsCParty

					, isnull(t2.Volume_AMD,0) Volume_AMD_CP

					, isnull(t3.VolumeAMD,0) Volume_AMD_Cl

					, isnull(t4.TotalVolumeAMD,0) Volume_AMD_NonTradeCl

					, isnull(t5.volumeAMD_Depo,0) Volume_AMD_Cl_Depo 

					, isnull(t6.TotalVolumeAMD,0) Volume_AMD_NonTradeCl_Depo 

					, isnull(t7.TotalVolumeAMD,0) Volume_AMD_CurrentPosition ,

						Isnull(t9.ArmBrok_Mn_Client, 0) ArmBrok_Mn_Client,

						Isnull(t9.CLIENT_CDA_Own, 0) CLIENT_CDA_Own,

						Isnull(t9.CLIENT_CDA_Own_Frozen, 0) CLIENT_CDA_Own_Frozen,

						Isnull(t9.ARMBR_DEPO_BTA, 0) ARMBR_DEPO_BTA,

						Isnull(t9.ARMBR_DEPO_MAREX, 0) ARMBR_DEPO_MAREX,

						Isnull(t9.ARMBR_DEPO, 0) ARMBR_DEPO,

						Isnull(t9.ARMBR_DEPO_GTN, 0) ARMBR_DEPO_GTN,

						Isnull(t9.ARMBR_DEPO_MAD, 0) ARMBR_DEPO_MAD,

						Isnull(t9.ARMBR_DEPO_AIX, 0) ARMBR_DEPO_AIX,

						Isnull(t9.ARMBR_DEPO_RON, 0) ARMBR_DEPO_RON,

						Isnull(t9.ARMBR_DEPO_MTD, 0) ARMBR_DEPO_MTD,

						Isnull(t9.ARMBR_DEPO_HFN, 0) ARMBR_DEPO_HFN,

						Isnull(t9.ARMBR_DEPO_GPP, 0) ARMBR_DEPO_GPP,

						Isnull(t9.ARMBR_MONEY_BLOCK, 0) ARMBR_MONEY_BLOCK,

						Isnull(t9.ARMBR_DEPO_ALOR_PLUS, 0) ARMBR_DEPO_ALOR_PLUS,

						Isnull(t9.OTHER , 0) OTHER

					--,  * 





					into ##t

					FROM QORT_BACK_DB..Firms fir
					OUTER APPLY (
						SELECT TOP 1 *
						FROM QORT_BACK_DB..Subaccs sub
						WHERE sub.OwnerFirm_ID = fir.id 
						  AND sub.Enabled = 0 
						  AND LEFT(ISNULL(sub.SubAccCode, '2'), 2) NOT IN ('AA', 'AB', '00', '
AR') 
						  AND ISNULL(sub.OwnerFirm_ID, 0) NOT IN (3,5)
					) sub
					OUTER APPLY (
						SELECT TOP 1 *
						FROM QORT_BACK_DB..ClientAgrees cl
						WHERE cl.OwnerFirm_ID = sub.OwnerFirm_ID 
						  AND cl.Enabled = 0 
						  AND cl.ClientAgreeTy
pe_ID IN (68) 
						  AND ISNULL(cl.DateSign, 0) <> 0 
						  AND cl.DateSign < @DataToInt
					) cl
					LEFT OUTER JOIN QORT_BACK_DB..FirmProperties FirmP 
						ON FirmP.Firm_ID = sub.OwnerFirm_ID
					LEFT OUTER JOIN QORT_BACK_DB..Countries countR 

						ON countR.id = FirmP.TaxResidentCountry_ID
					LEFT OUTER JOIN QORT_BACK_DB..Countries countA 
						ON countA.id = Fir.Country_ID
					LEFT OUTER JOIN QORT_BACK_DB..OrgCathegories org 
						ON org.id = fir.OrgCathegoriy_ID
					full JOIN #t2 t2
	
					ON t2.CpFirm_ID = fir.ID
					full JOIN #t3 t3
						ON t3.SubAcc_ID = sub.ID
					full JOIN #t4 t4
						ON t4.SubAccID = sub.ID
					full JOIN #t5 t5
						ON t5.SubAcc_ID = sub.ID
					full JOIN #t6 t6
						ON t6.SubAccID = sub.ID
					full JOIN 
#t7 t7
						ON t7.SubAccID = sub.ID
					full JOIN #t9 t9
						ON t9.SubAccID = sub.ID

					

					

					WHERE fir.Enabled = 0;



					delete ##t where (IsClient = 'no' and IsCParty = 'no') or (IsClient = 'YES' and DateSign is null) and Volume_AMD_CP is null



					if (isnull(@SubAccCode, '') <> '')

					begin

							SET @OutputParam = (
								SELECT TOP 1 
									(Volume_AMD_CP + Volume_AMD_Cl + Volume_AMD_NonTradeCl + Volume_AMD_NonTradeCl_Depo + Volume_AMD_NonTradeCl_Depo) * b.Bid
								FROM ##t
								OUTER APPLY (
									SELECT TOP 1 bid 
								
	FROM QORT_BACK_DB.dbo.CrossRates 
									WHERE InfoSource = 'MainCurBank' AND TradeAsset_ID = 17
								) b
								WHERE SubAccCode = @SubAccCode
							);



								SET @OutputParamCL = (
								SELECT TOP 1 
									iif(@DataToInt = @DataFromint, volume_AMD_CurrentPosition , Volume_AMD_Cl) * b.Bid
								FROM ##t
								OUTER APPLY (
									SELECT TOP 1 bid 
									FROM QORT_BACK_DB.dbo.CrossRatesHis
t 
									WHERE InfoSource = 'MainCurBank' AND TradeAsset_ID = 17 and Date = @DataToInt
								) b
								WHERE SubAccCode = @SubAccCode
							);

					end 



					select * from ##t





				



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END
