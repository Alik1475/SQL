





/*

	declare @OutputParam1 float

 exec QORT_ARM_SUPPORT.dbo.ReportTurnOverAMDCompliance @DataFrom = '2024-01-01', @DataTo = '2024-11-14', @SubAccCode = 'AS1105', @OutputParam = @OutputParam1 OUTPUT

print @OutputParam1





*/

CREATE PROCEDURE [dbo].[ReportTurnOverAMDCompliance]

	  @DataFrom date, --= '2023-01-01',

      @DataTo date,-- = '2024-01-01'

	  @SubAccCode varchar(50),

	  @OutputParam float output 



AS



BEGIN



	begin try

		declare @DataFromint int = cast(convert(varchar, @DataFrom, 112) as int)

		declare @DataToInt int = cast(convert(varchar, @DataTo, 112) as int)

		declare @Message varchar(1024)

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
            isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) AS Rate
        FROM 
            QORT_BACK_DB..MarketInfoHist mar
        OUTER APPLY (
            SELE
CT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = mar.PriceAsset_ID
                AND crs.OldDate =  Cor.RegistrationDate
                AND crs.PriceAsset_ID = 17
                AND I
nfoSource = 'CBA'
        ) crsCrTra
        WHERE 
            mar.TSSection_ID = 154 -- 'OTC_Securities'
            AND mar.Asset_ID = cor.Asset_ID
            AND mar.OldDate = Cor.RegistrationDate
    ), 
    (
        SELECT TOP 1
            isnull
(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) AS Rate
        FROM 
            QORT_BACK_DB..MarketInfoHist mar
        OUTER APPLY (
            SELECT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHER
E 
                crs.TradeAsset_ID = mar.PriceAsset_ID
                AND crs.OldDate = Cor.RegistrationDate
                AND crs.PriceAsset_ID = 17
                AND InfoSource = 'CBA'
        ) crsCrTra
        WHERE 
            mar.TSSection_I
D = 165 -- 'OTC_SWAP'
            AND mar.Asset_ID = cor.Asset_ID
            AND mar.OldDate = Cor.RegistrationDate
    )
	, 
    (
        -- Третье выражение (BaseValue)
        SELECT 
            asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1
, crsCrA.Bid) AS Rate
        FROM 
            QORT_BACK_DB..Assets asse
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

																asse.BaseValue * IIF(asse.BaseCurrencyAsset_ID = 17, 1, crsCrA.Bid)*0

															ELSE 

																



																	(SELECT COALESCE(
    (
        SELECT TOP 1
            isnull(mar.LastPrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) AS Rate
        FROM 
            QORT_BACK_DB..MarketInfoHist mar
        OUTER APPLY (
            SELE
CT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = 8 -- mar.PriceAsset_ID
                AND crs.OldDate = 20230816 -- Cor.RegistrationDate
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
  
          isnull(mar.SettlePrice * IIF(mar.LinkedCurrency_ID = 17, 1, crsCrTra.Bid), 0) AS Rate
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
            asse.BaseValue * IIF(asse.BaseCurrency
Asset_ID = 17, 1, crsCrA.Bid) AS Rate
        FROM 
            QORT_BACK_DB..Assets asse
        OUTER APPLY (
            SELECT TOP 1 *
            FROM QORT_BACK_DB..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = asse.BaseC
urrencyAsset_ID
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

														0 --IIF(cor.Asset_ID = 17, 1, crsCrP.bid)

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
									WHERE InfoSource = 'MainCurBank' AND TradeAsset_ID = 2
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
