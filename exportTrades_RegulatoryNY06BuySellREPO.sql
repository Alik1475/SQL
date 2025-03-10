







-- exec QORT_ARM_SUPPORT.dbo.exportTrades_RegulatoryNY06BuySellREPO '20250304'



CREATE PROCEDURE [dbo].[exportTrades_RegulatoryNY06BuySellREPO]

	@TradeDate date

AS

BEGIN



	begin try

	--select 'Report Done: ' + cast(@TradeDate as varchar(36)) ResultStatus, 'green' ResultColor return

		SET NOCOUNT ON



		declare @Message varchar(1024)

		--declare @TradeDateFrom int = cast(convert(varchar, dateadd(day, -1, @TradeDate), 112) as int)

		declare @TradeDateFrom int = cast(convert(varchar, QORT_ARM_SUPPORT.dbo.fGetPrevBusinessDay(@TradeDate), 112) as int)

		declare @TradeDateTo int = cast(convert(varchar, convert(date, @TradeDate,101), 112) as int)

		declare @TradeTimeFrom int = 160000000 --(16:00:00.000)

		declare @ArmBrokFirmShortName varchar(16) = 'Armbrok OJSC'

		

		--select 'Report Done: ' + cast(@TradeDateFrom  as varchar(36)) + '/' + cast(@TradeDate as varchar(36)) + '/'+ cast(@TradeDateTo as varchar(36)) ResultStatus, 'green' ResultColor return



		declare @TradeDateToTXT varchar(32) = QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(@TradeDateTo)



		declare @sql nvarchar(max)

		/*declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\test_42000_NY06_workTemplate.xls'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\temp\42000_NY06_workTemplate_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xls'

		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\42000_NY06_'+cast(@TradeDateTo as varchar)+'.xls'*/

		declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\template\42000_NY06_workTemplate (10).xls'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\archive\42000_NY06_workTemplate_'+cast(@TradeDateTo as varchar) + '_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, g
etdate(), 108), ':', '') + '.xls'

		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\42000_NY06_'+cast(@TradeDateTo as varchar)+'.xls'

		declare @Sheet1 varchar(32) = '1.buy-sell'

		declare @Sheet2 varchar(32) = '2.repo-r.repo'

		declare @Sheet10 varchar(32) = '10.OPTION (SEC)'



		declare @res table(r varchar(255))

		declare @cmd varchar(512)



		declare @execres varchar(1024)

		--/*

		set @cmd = 'copy "' + @TemplateFileName + '" "' + @TempFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd



		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @TempFileName

			RAISERROR (@execres, 16, 1);

		end

		--*/



		if OBJECT_ID('tempdb..#r', 'U') is not null drop table #r

		if OBJECT_ID('tempdb..##42000_NY06_workTemplate_01', 'U') is not null drop table ##42000_NY06_workTemplate_01

		if OBJECT_ID('tempdb..##42000_NY06_workTemplate_02', 'U') is not null drop table ##42000_NY06_workTemplate_02

		if OBJECT_ID('tempdb..##42000_NY06_workTemplate_10', 'U') is not null drop table ##42000_NY06_workTemplate_10



		select t.id TradeId, row_number() over(partition by tt.tt order by t.TradeDate, t.TradeTime, t.id) Num_A

			, iif(fo.IsResident = 'y', isnull(nullif(cast(fpo.MIC as nvarchar), ''), N'é»½Ç¹»Ýï'), N'áã é»½Ç¹»Ýï') Code_B

			--, '$$$' + isnull(fpo.MIC, '') Code_B

			, '42000' ArmCode_C

			, case

				when isnull(pRepo1.PhaseTime,0) <> 0 then QORT_ARM_SUPPORT.dbo.fIntToTimeVarchar(pRepo1.PhaseTime)

				else

					iif(ttt.TradeTime <= 1900, '', QORT_ARM_SUPPORT.dbo.fIntToTimeVarchar(ttt.TradeTime)) 

					end Time_D -- change time 1000 to 1900 alik 20/02/2024

			, iif(t.BuySell = 1, N'³éù', N'í³×³éù') BuySell_E

			, iif(a.Country = 'Armenia', '',iif(t.PT_Const=1, N'áã µ³ÅÝ³ÛÇÝ', N'µ³ÅÝ³ÛÇÝ')) PriceType_F -- 1 - %, 2 - abs -- Алик 26/02/2024 добавил условие iif(a.Country = 'Armenia'. Если страна эмитента Армения,но название не указываем.

			, a.ISIN ISIN_G

			--, '??? - ' + fEmit.Name + iif(EmitCountry.Name <> '', ', ' + EmitCountry.Name, '') Emitent_H

	        , iif(a.Country = 'Armenia', '', isnull(fEmitProp.NameU,'')) + iif(a.Country = 'Armenia', '', iif(AssetCountry.NameU <> '', ', ' + substring(AssetCountry.NameU, Charindex('/',AssetCountry.NameU) + 1, LEN(AssetCountry.NameU) - Charindex('/',Asset
Country.NameU)), '')) 

						Emitent_H -- Алик 26/02/2024 добавил условие iif(a.Country = 'Armenia'. Если страна эмитента Армения,но название не указываем.

			--, iif(a.Country = 'Armenia', N'',isnull(fEmitProp.NameU, N'')) + iif(a.Country = 'Armenia', N'', iif(AssetCountry.NameU <> '', N', ' + AssetCountry.NameU, N'')) collate Latin1_General_CI_AS Emitent_H -- Алик 26/02/2024 добавил условие iif(a.Country =
 'Armenia'. Если страна эмитента Армения,но название не указываем.

			--, cast(iif(a.Country = 'Armenia', N'',isnull(fEmitProp.NameU, N'')) + iif(a.Country = 'Armenia', N'', iif(AssetCountry.NameU <> '', N', ' + AssetCountry.NameU, N'')) collate Latin1_General_CI_AS as nvarchar(255)) Emitent_H -- Алик 26/02/2024 добавил 
условие iif(a.Country = 'Armenia'. Если страна эмитента Армения,но название не указываем.

			--, cast(iif(a.Country = 'Armenia', '',isnull(fEmitProp.NameU, '')) + iif(a.Country = 'Armenia', '', iif(AssetCountry.NameU <> '', ', ' + AssetCountry.NameU, '')) as varchar(255)) Emitent_H -- Алик 26/02/2024 добавил условие iif(a.Country = 'Armenia'. 
Если страна эмитента Армения,но название не указываем.

			--, iif(a.BaseValueOrigin * t.QTY <> 0, QORT_ARM_SUPPORT.dbo.fFloatToCurrency(a.BaseValueOrigin * t.QTY), '') BaseValueVolume_I

			, iif(a.BaseValue * t.QTY <> 0, cast(a.BaseValue * t.QTY as decimal(32,2)), NULL) BaseValueVolume_I -- Алик 04/03/2024 - поправил количество знаков после запятой на 2

			--, QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.Price) Price_J

			, iif(t.PT_Const=2, cast(t.volume1/t.Qty as decimal(32,5)), cast(t.volume1/t.Qty as decimal(32,5))) Price_J -- 1 - %, 2 - abs --Alik 25/09/2024 add for abs - t.volume1/t.Qty; Алик 26/02/2024 если тип цены %, то вычисляем сумма/количество=цена

			--, iif(a.Country = 'Armenia', '', QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.Qty)) [Qty_K]

			, CASE WHEN a.ISIN = 'XS2080321198' THEN

				cast(a.BaseValue * t.QTY as decimal(32,2))

				ELSE

				iif(a.EmitentFirm_ID = 137 Or (a.Country = 'Armenia' and a.assetSort_Const in(3)) , NULL, cast(t.Qty as decimal(32,5)))  END [Qty_K] -- Алик 04/03/2024 поправил количество знаков после запятой на 5; 26/02/2024 a.EmitentFirm_ID = 137 это REPUBLIC OF AR
MENIA. Исключение для гос.бумаг

			--, QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.Volume1) Volume_L

			, convert(decimal(32,8), t.Volume1) Volume_L

			, aPay.ShortName PayCurrency_M

			--, iif(t.Yield <> 0, QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.Yield /** 100*/)+'%', '') Yield_N -- Alik 27/02/2024 решили вести значения в Корт в процентах

			, iif(t.Yield <> 0, convert(decimal(32,8), t.Yield/100), null) Yield_N -- Alik 27/02/2024 решили вести значения в Корт в процентах

			--, '$$$' TradePlace_O

			--, isnull(fpts.NameU, '') TradePlace_O

			, case when tss.Name = 'OTC_Securities' then N'ãÏ³ñ·³íáñíáÕ ßáõÏ³' 

				   when tss.Name = 'AMX_Securities' then N'86100' 

				   when tss.Name = 'AIX_Securities' then N'²ëï³Ý³ÛÇ ØÇç³½·³ÛÇÝ ýáÝ¹³ÛÇÝ µáñë³' 

				   when tss.Name = 'AMEX_Securities' then N'²Ù»ñÇÏÛ³Ý üáÝ¹³ÛÇÝ ´áñë³' 

				   when tss.Name = 'NASDAQ (XNAS-US)' then N'Ü³ë¹³ùÇ ýáÝ¹³ÛÇÝ µáñë³' 

				   when tss.Name = 'NYSE (XNYS-US)' then N'ÜÛáõ ÚáñùÇ ýáÝ¹³ÛÇÝ µáñë³' 

				   when tss.Name = 'LSE (XLON-LN)' then N'ÈáÝ¹áÝÇ ýáÝ¹³ÛÇÝ µáñë³' 

				   when tss.Name = 'MOEX_Securities' then N'ØáëÏí³ÛÇ ýáÝ¹³ÛÇÝ µáñë³' 

				   when tss.Name = 'OPRA' then N'úöÇ²ñ¾Û'

				   else isnull(fpts.NameU, '') end TradePlace_O

			, left(QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(t.TradeDate),6)+right(QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(t.TradeDate),2) TradeDate_P

			--, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(iif(t.PutDate > 0, t.PutDate, t.PutplannedDate)) PutDate_Q

			,  left(QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(t.PutplannedDate),6)+right(QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(t.PutplannedDate),2) PutDate_Q

			--, '$$$'  + isnull(fpcp.MIC, '') CPCode_R

			, iif(t.CpTrade_ID > 0, '42000', iif(ts.code in ('AMX', 'AIX', 'AMEX', 'LSE', 'NASDAQ', 'NYSE'), 

						          CASE when ts.code in ('AMX') and t.CpFirm_ID <> 3333333 

												then cast(fpcp.mic as varchar(12)) 

									   else N'Ï³½Ù³Ï»ñåí³Í ßáõÏ³' end

									   , iif(fcp.IsResident = 'y', isnull(fpcp.MIC, ''), N'áã é»½Ç¹»Ýï'))) CPCode_R

			--, isnull(fExtBro.FirmShortName, '') ExternalBroker_S

			, isnull(fExtBroP.NameU,'') ExternalBroker_S

			, tt.tt

			, left (t.AgreeNum,iif(charindex( '/', t.AgreeNum) = 0, len(t.AgreeNum ), charindex( '/', t.AgreeNum ) - 1))  AgreeNum_R_D -- Алик 26/02/2024 значение договора t.AgreeNum до '/'

			, iif(t.BuySell = 2, N'é»åá', N'Ñ³Ï³¹³ñÓ é»åá') RepoType_R_F

			--, iif(tt.tt=2, iif(p.TransactionDate > 0, N'»ñÏ³ñ³Ó·í³Í', N'Ýáñ ÏÝùí³Í'), '') RepoType2_R_G

			, iif(isnull(pRepo1.id,0) <> 0, iif(pRepo1.dateafter1 > pRepo2.dateafter2, N'»ñÏ³ñ³Ó·í³Í', N'Ïñ×³ïí³Í'), N'Ýáñ ÏÝùí³Í') RepoType2_R_G

			--, iif(tt.tt=2 and t.RepoRate > 1e-8, QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.RepoRate) + '%' + ' ???', '???') RepoRate_R_O

			--, iif(tt.tt=2 and t.RepoRate > 1e-8, QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.RepoRate) + '%', NULL) RepoRate_R_O

			, iif(tt.tt=2 and t.RepoRate > 1e-8, convert(decimal(32,8), t.RepoRate), NULL) RepoRate_R_O

			,/* QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(iif(tt.tt=2, t.BackDate, 19000101))*/ QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort (t.BackDate) RepoBackDate_R_P

			, iif(tt.tt=2, iif(t.TT_Const = 3 OR t.TSSection_ID = 157, N'86100', N'ãÏ³ñ·³íáñíáÕ ßáõÏ³'), '') RepoLocation_Q -- Alik 26/02/2024 "OR t.TSSection_ID = 157" - секция AMX_REPO

			, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(iif(t.RepoTrade_ID > 0 and tp.AgreeHeaderDate > 19010101, tp.AgreeHeaderDate, t.TradeDate)) TradeDate_R_R

			, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(t.TradeDate) TradeDate2_R_S -- в форму не выводится. Выводится TradeDate_R_R. Возможно в будущем потребуется, если вдруг не будет равно.

			, iif(tt.tt=2 and p.TransactionDate > 0, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(p.TransactionDate), '') TransactionDate_R_T

			, pRepo1.PhaseTime

			, fpo.NameU FNameU

			, fo.INN FINN

			, iif(t.BuySell = 2, N'ûåóÇáÝ í³×³éù', N'ûåóÇáÝ ³éù') OPT_Type

			, iif(a.AssetSort_Const = 19, N'·ÝÙ³Ý ûåóÇáÝ', N'í³×³éùÇ ûåóÇáÝ') OPT_Sort -- 19 Options CALL

			, iif(b.AssetClass_Const in(5), N'´³ÅÝ³ÛÇÝ', N'àã µ³ÅÝ³ÛÇÝ') OPT_BaseAssType -- 5	Equity RF

			, b.ISIN as OPT_BaseISIN

			, fEmitPropOPT.NameU as NameUEmitOPT

			, a.OptionStrike as OPT_OptionStrik

			, (a.OptionStrike * t.Qty * a.BaseAssetSize) as TotalOPT

			, (t.Qty * a.BaseAssetSize) as TotalQtyOPT

			, bC.ShortName as CurOPT

			, left(QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(a.CancelDate),6)+right(QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(a.CancelDate),2) as CancelDateOPT

			--, t.RepoTrade_ID

			--, pRepo1.dateafter1

			--, pRepo2.dateafter2



		into #r

		from (

			select t.id TradeId, t.TradeDate, t.TradeTime

			from QORT_BACK_DB.dbo.Trades t with (nolock, index = PK_Trades)

			where t.TradeDate between @TradeDateFrom and @TradeDateTo

				and NOT (t.TradeDate = @TradeDateFrom and t.TradeTime < @TradeTimeFrom)

				and NOT (t.TradeDate = @TradeDateTo and t.TradeTime >= @TradeTimeFrom)

				--and (t.EventDate < 20010101 or t.EventDate = @TradeDateTo)

				and (t.EventDate = t.TradeDate) -- Alik change 20/02/2024

			union

			select t.id TradeId, t.EventDate TradeDate, 0 TradeTime 

			from QORT_BACK_DB.dbo.Trades t with (nolock, index = PK_Trades)

			where t.EventDate = @TradeDateTo and t.EventDate <> t.TradeDate 

			union

			select t.RepoTrade_ID TradeId, t.EventDate TradeDate, 0 TradeTime

			from QORT_BACK_DB.dbo.Trades t with (nolock, index = PK_Trades)

			      OUTER APPLY (

						SELECT TOP 1 *

						FROM QORT_BACK_DB.dbo.Phases ph

						WHERE ph.PhaseDate = @TradeDateTo

						AND ph.PC_Const in (13,14)

						and ph.Trade_ID = t.id 

								) AS ph

			where

			  t.TT_Const in (6) and ph.id is not Null

			  

		) ttt

		inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = ttt.TradeId

		left outer join QORT_BACK_DB.dbo.TradeProperties tp with (nolock) on tp.Trade_ID = t.id

		left outer join QORT_BACK_DB.dbo.TSSections tss with (nolock) on tss.id = t.TSSection_ID

		left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

		left outer join QORT_BACK_DB.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fpo with (nolock) on fpo.Firm_ID = fo.id

		left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

		left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		left outer join QORT_BACK_DB.dbo.Assets b with (nolock) on b.id = a.BaseAsset_ID

		left outer join QORT_BACK_DB.dbo.Assets bC with (nolock) on bC.id = a.BaseCurrencyAsset_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fEmitPropOPT with (nolock) on fEmitPropOPT.id = b.EmitentFirm_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fEmitProp with (nolock) on fEmitProp.Firm_ID = a.EmitentFirm_ID

		--left outer join QORT_BACK_DB.dbo.Countries EmitCountry with (nolock) on EmitCountry.id = fEmit.Country_ID

		left outer join QORT_BACK_DB.dbo.Countries AssetCountry with (nolock) on AssetCountry.Name = a.Country

		left outer join QORT_BACK_DB.dbo.Assets aPay with (nolock) on aPay.id = t.CurrPayAsset_ID

		left outer join QORT_BACK_DB.dbo.Firms fcp with (nolock) on fcp.id = t.CpFirm_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fpcp with (nolock) on fpcp.Firm_ID = fcp.id

		--left outer join QORT_BACK_DB.dbo.TSs cpts with (nolock) on cpts.Code = fcp.FirmShortName

		left outer join QORT_BACK_DB.dbo.Firms fExtBro with (nolock) on fExtBro.id = t.ExtBrokerFirm_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fExtBroP with (nolock) on fExtBroP.Firm_ID = fExtBro.id



		left outer join QORT_BACK_DB.dbo.TSs ts with (nolock) on ts.id = tss.TS_ID

		left outer join QORT_BACK_DB.dbo.Firms fts with (nolock) on fts.FirmShortName = ts.Name and fts.Enabled = 0

		left outer join QORT_BACK_DB.dbo.FirmProperties fpts with (nolock) on fpts.Firm_ID = fts.id



		outer apply(select case when t.TT_Const in (1,5,7) then 1 

								when t.TT_Const in (3,6) then 2 

								when t.TT_Const in (11,4) AND t.TSSection_ID IN(167) then 3 --OTC_Derivatives

								end tt) tt

		outer apply(select top 1 p.PhaseDate TransactionDate from QORT_BACK_DB.dbo.Phases p with (nolock) where p.Trade_ID = t.RepoTrade_ID and p.IsCanceled = 'n' order by ID desc) p

		outer apply(select top 1 p.PhaseTime, p.id, p.DateAfter as DateAfter1 from QORT_BACK_DB.dbo.Phases p with (nolock) 

			where p.Trade_ID = t.RepoTrade_ID and p.IsCanceled = 'n' and p.PC_Const in (14) order by id desc) pRepo1

			OUTER APPLY (

    SELECT TOP 1 p.BackDate as DateAfter2, p.id

    FROM QORT_BACK_DB.dbo.TradesHist p WITH (NOLOCK)

    WHERE 

        p.Founder_ID = t.RepoTrade_ID 

        AND p.id < (

            SELECT TOP 1 p1.id

            FROM QORT_BACK_DB.dbo.TradesHist p1 WITH (NOLOCK)

            WHERE 

                p1.Founder_ID = t.RepoTrade_ID 

                AND p1.BackDate = pRepo1.DateAfter1

            ORDER BY p1.id asc

        )

    ORDER BY p.id DESC

) pRepo2

		where /*t.TradeDate between @TradeDateFrom and @TradeDateTo

			and NOT (t.TradeDate = @TradeDateFrom and t.TradeTime < @TradeTimeFrom)

			and NOT (t.TradeDate = @TradeDateTo and t.TradeTime >= @TradeTimeFrom)

			and*/ t.NullStatus = 'n' and t.Enabled = 0 and t.IsDraft = 'n' and t.IsProcessed = 'y'

			--and t.TT_Const in (5) -- 	OTC buy/sell securities

			and t.TT_Const in (1, 5, 4, 3, 6 , 7, 11) -- 5 - OTC buy/sell securities, 3,6 - Repo, 11,4 - OTC derivatives market

			and not (t.IsRepo2 = 'y') -- для РЕПО только 1-ая нога???

			and not tss.Name in ('OTC_SPOT_Delivery_by_FWD')

	

	--select * from #r return

		select r.Num_A, r.Code_B, r.ArmCode_C, r.Time_D Time_D, r.BuySell_E, r.PriceType_F, r.ISIN_G, r.Emitent_H, r.BaseValueVolume_I, r.Price_J, r.Qty_K, r.Volume_L

			, r.PayCurrency_M, r.Yield_N, r.TradePlace_O, r.TradeDate_P, r.PutDate_Q, r.CPCode_R, r.ExternalBroker_S

		into ##42000_NY06_workTemplate_01

		from #r r

		where r.tt = 1



		select r.Num_A, r.Code_B, r.ArmCode_C, r.AgreeNum_R_D, r.Time_D Time_E, RepoType_R_F, RepoType2_R_G

			, r.PriceType_F PriceType_H, r.ISIN_G ISIN_I, r.Emitent_H Emitent_J, FORMAT(ROUND(r.BaseValueVolume_I, 5), 'N5') BaseValueVolume_K

			, FORMAT(ROUND(r.Qty_K, 5), 'N5') Qty_L, FORMAT(ROUND(r.Volume_L, 5), 'N5')  Volume_M, r.PayCurrency_M PayCurrency_N, FORMAT(ROUND(r.RepoRate_R_O, 5), 'N5') + '%' RepoRate_R_O, dbo.fVarcharDateYYYYToVarcharDateYY(r.RepoBackDate_R_P) RepoBackDate_R_P

			, RepoLocation_Q, /*r.TradeDate_P*/ dbo.fVarcharDateYYYYToVarcharDateYY(r.TradeDate_R_R) TradeDate_R, dbo.fVarcharDateYYYYToVarcharDateYY(r.TradeDate_R_R) TradeDate_R_R, dbo.fVarcharDateYYYYToVarcharDateYY(r.TransactionDate_R_T) TransactionDate_R_T --
 Алик 26/02/2024 поменял r.TradeDate2_R_S на r.TradeDate_R_R. выводим равное значение, до настройки механизма отражения РЕПО вендором

			, r.CPCode_R CPCode_U, r.ExternalBroker_S ExternalBroker_V

		into ##42000_NY06_workTemplate_02

		from #r r

		where r.tt = 2

		--print dbo.fVarcharDateYYYYToVarcharDateYY('02/10/2024'), r.ISIN_G ISIN_I

		

		

		select r.Num_A,  r.Code_B, r.FNameU as FNameU_C, r.FINN as FINN_D, r.ArmCode_C as ArmCode_E, ' ' as column_F, ' ' as column_D, r.AgreeNum_R_D as AgreeNum_H, r.Time_D Time_I

			, r.OPT_Type as OPT_Type_J, r.OPT_Sort as OPT_Sort_K, N'Ýáñ ÏÝùí³Í'  as Typetrade_L, r.OPT_BaseAssType as OPT_BaseAssType_M, r.OPT_BaseISIN ISIN_N, r.NameUEmitOPT NameUEmitOPT_O

			, FORMAT(ROUND(r.Qty_K, 5), 'N5') Qty_P, FORMAT(ROUND(r.OPT_OptionStrik, 5), 'N5') as OPT_OptionStrik_Q, FORMAT(ROUND(r.TotalQtyOPT, 5), 'N5') as TotalQtyOPT_R

			, FORMAT(ROUND(r.TotalOPT, 5), 'N5') TotalOPT_S, r.CurOPT as CurOPT_T, ' ' Column_U, FORMAT(ROUND(r.Volume_L, 5), 'N5')  Volume_R, r.PayCurrency_M PayCurrency_W

			, dbo.fVarcharDateYYYYToVarcharDateYY(r.CancelDateOPT) CancelDateOPT_X, N'³é³ùáõÙ' asTyprExp_Y, dbo.fVarcharDateYYYYToVarcharDateYY(r.TradeDate_R_R) TradeDate_Z

			, ' ' as Column_AA, N'áã é»½Ç¹»Ýï' as CP_Type_AB, ' ' as Column_AC, ' ' as Column_AD, ' ' as Column_AE, r.TradePlace_O as Place_Trade_AF, r.ExternalBroker_S ExternalBroker_AG

			, ' ' as Column_AH,' ' as Column_AI, N'³é³Ýó ·ñ³íÇ' as Column_AJ, ' ' as Column_AK, ' ' as Column_AL, N'³Ù»ñÇÏÛ³Ý' as Column_AM, ' ' as Column_AN, ' ' as Column_AO, N'Ñ³Ù³Ó³ÛÝ ã»Ù' as Column_AP

		into ##42000_NY06_workTemplate_10

		from #r r

		where r.tt = 3

		--/*

		--select * from #r r

		--select * from ##42000_NY06_workTemplate_01

	--	select * from ##42000_NY06_workTemplate_02

		--select * from ##42000_NY06_workTemplate_10

		--return --*/



		declare @SheetDates table(sdId int identity primary key, DateLocation varchar(32))

		insert into @SheetDates(DateLocation) values ('1.buy-sell$D7:D8'), ('2.repo-r.repo$E4:E5'), ('3.Forward (FX)$F4:F5'), ('4.Futures (FX)$D5:D6')

			, ('5.Forward (SEC)$E4:E5'), ('6.Futures (SEC)$E5:E6'), ('7.Forward (AYL)$D4:D5'), ('8.Futures(AYL)$E5:E6'), ('9.OPTION (FX)$D4:D5'), ('10.OPTION (SEC)$D4:D5')

			, ('11.OPTION(AYL)$E5:E6'), ('12# Swap(POXAJEQ)$D5:D6'), ('13# Swap (FX)$D5:D6'), ('14.Swap(INTRATE)$D5:D6'), ('15# CFD (FX)$D5:D6'), ('16# CFD (SEC)$D5:D6')



		declare @i int = 0

		declare @s varchar(32) = ''



		while @s is not null begin

			select @i = @i + 1, @s = null

			select top 1 @s = DateLocation from @SheetDates where sdId = @i

			SET @sql = N'UPDATE t SET t.[²ðØ´ðàÎ ´´À] = ''' + @TradeDateToTXT + '''

				from OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

				''SELECT * FROM [' + @s + ']'') t'

			print @sql

			if @sql is not null exec(@sql)

		end



		--RETURN

		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$A11:S11]'')

			select * from ##42000_NY06_workTemplate_01 order by Num_A'

		print @sql

		exec(@sql)



		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet2 + '$A8:V8]'')

			select * from ##42000_NY06_workTemplate_02 order by Num_A'

		print @sql

		exec(@sql)



		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet10 + '$A9:AP9]'')

			select * from ##42000_NY06_workTemplate_10 order by Num_A'

		print @sql

		exec(@sql)



		/*

		SET @sql = N'UPDATE t SET t.[²ðØ´ðàÎ ´´À] = ''' + @TradeDateToTXT + '''

			from OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$D7:D8]'') t'

		print @sql

		exec(@sql)

		*/



		set @cmd = 'copy "' + @TempFileName + '" "' + @ResultFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))

		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @ResultFileName

			RAISERROR (@execres, 16, 1);

		end



		select 'Report Done: ' + @ResultFileName ResultStatus, 'green' ResultColor

		--print @ResultFileName 



	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		select @Message ResultStatus, 'red' ResultColor

	end catch



END

