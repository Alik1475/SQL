



-- exec QORT_ARM_SUPPORT.dbo.Report_CBA_FX_NEW @StartDateD = '2025-07-21',   @EndDateD = '2025-07-25'



CREATE PROCEDURE [dbo].[Report_CBA_FX_NEW]

@StartDateD date,   -- Дата начала в формате YYYYMMDD
 @EndDateD date-- Дата окончания в формате YYYYMMDD



AS



BEGIN
	BEGIN TRY
	    DECLARE @StartDate int = CAST(CONVERT(VARCHAR, @StartDateD, 112) AS INT)
		DECLARE @EndDate int = CAST(CONVERT(VARCHAR, @EndDateD, 112) AS INT)
		if OBJECT_ID('tempdb..#Result', 'U') is not null drop table #Result
		
		DECLARE @today
Date DATE = GETDATE()
		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
		DECLARE @Message VARCHAR(1024)
		DECLARE @ytdDate DATE

		DECLARE @n INT = 0

		--declare @Sheet1 varchar(32) = 'Client_portfolio'

        declare @sql nvarchar(max)

        -- Определяем вчерашний рабочий день

        WHILE dbo.fIsBusinessDay(DATEADD(DAY, -1-@n, @todayDate)) = 0 

        BEGIN    

            SET @n = @n + 1;

        END

        SET @ytdDate = (DATEADD(DAY, -1-@n, @todayDate)) -- определили вчерашний бизнес день

        DECLARE @ytdDateint INT = CAST(CONVERT(VARCHAR, @ytdDate, 112) AS INT);

        declare @ytdDatevarch varchar(32) = dbo.fIntToDateVarchar_dd_MMM_yyyy (@ytdDateint);

		PRINT @ytdDatevarch
		declare @res table(r varchar(255))

		declare @CurOrder table(Currency varchar(8) primary key, OrderBy int)

		insert into @CurOrder(Currency, OrderBy) values ('GBP', 1), ('EUR', 2), ('USD', 3), ('RUB', 4)

	/*	

	declare @cmd varchar(512)



		declare @execres varchar(1024)

		



	select @n = MAX(number) from #Recipients;



	while @n > 0

	begin



	select @NotifyEmail = email from #Recipients where number = @n

	select @SubAccount = SubAccount from #Recipients where number = @n



		set @cmd = 'copy "' + @TemplateFileName + '" "' + @TempFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd



		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @TempFileName

			RAISERROR (@execres, 16, 1);

		end

		--*/
		if OBJECT_ID('tempdb..#r', 'U') is not null drop table #r

		if OBJECT_ID('tempdb..##Template_01', 'U') is not null drop table ##Template_01

		if OBJECT_ID('tempdb..##Template_02', 'U') is not null drop table ##Template_02

		SELECT      ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowN,

					Tra.TradeDate as TradeDate,

					/*'42000' +

					RIGHT('0' + CAST(Tra.TradeDate % 100 AS VARCHAR(2)), 2) +       -- DD

					RIGHT('0' + CAST((Tra.TradeDate / 100) % 100 AS VARCHAR(2)), 2) +-- MM

					RIGHT(CAST(Tra.TradeDate / 10000 AS VARCHAR(4)), 2)             -- YY*/

					cast('' as varchar(50)) AS A1
					, '' as B2
					, isnull(co.Code_Alfa_3,'') as C3
					, IIF (fir.IsResident = 'y', 'Resident', 'NonResident') as D4
					, IIF (fir.IsFirm = 'y', 'Leg', 'Nat') as E5
					, case 

							when cath.Name like '%Central (Federal) governing authorities%' then 'CentGov'

							when cath.Name like '%Local self-government authorities%' then 'LocGov'

							when cath.Name like '%State Social Security Fund%' then 'SSFund'

							when cath.Name like '%Central bank%' then 'CB'

							when cath.Name like '%Bank%' then 'Bank'

							when cath.Name like '%Credit organization%' then 'CredOrg'

							when cath.Name like '%Insurance company%' then 'InsComp'

							when cath.Name like '%Pension fund%' then 'PensFund'

							when cath.Name like '%Investment company%' then 'InvComp'

							when cath.Name like '%Investment fund%' then 'InvFund'

							when cath.Name like '%Investment fund manager%' then 'InvFundMan'

							when cath.Name like '%Clearing & Settlement organization%' then 'PaySys'

							when cath.Name like '%Pawn shop%' then 'Lombard'

							when cath.Name like '%Deposit Guarantee fund%' then 'DepGuarFund'

							when cath.Name like '%Regulated market%' then 'RegMarket'

							when cath.Name like '%Other financial organization%' then 'OthFinOrg'

							when cath.Name like '%Other supporting financial organization%' then 'OthAuxFinOrg'

							when cath.Name like '%Non-financial entity%' then 'NonFinOrg'

							when cath.Name like '%Private entrepreneurship%' then 'SoleEnt'

							when cath.Name like '%Other household entity%' then 'OthHousehold'

							when cath.Name like '%Non-profit organizations serving households%' then 'NonProfit'

							else ''

						end as F6

						, 'N/A' as G7

						, isnull(firP.MIC, '') as H8

						, '' as I9

						, isnull(coZ.Code_Alfa_3,'') as J10
						, cast(firZ.INN as varchar(50)) as K11
						, IIF (firZ.IsResident = 'y', 'Resident', 'NonResident') as L12
						, IIF (firZ.IsFirm = 'y', 'Leg', 'Nat') as M13
						, case 

							when cathZ.Name like '%Central (Federal) governing authorities%' then 'CentGov'

							when cathZ.Name like '%Local self-government authorities%' then 'LocGov'

							when cathZ.Name like '%State Social Security Fund%' then 'SSFund'

							when cathZ.Name like '%Central bank%' then 'CB'

							when cathZ.Name like '%Bank%' then 'Bank'

							when cathZ.Name like '%Credit organization%' then 'CredOrg'

							when cathZ.Name like '%Insurance company%' then 'InsComp'

							when cathZ.Name like '%Pension fund%' then 'PensFund'

							when cathZ.Name like '%Investment company%' then 'InvComp'

							when cathZ.Name like '%Investment fund%' then 'InvFund'

							when cathZ.Name like '%Investment fund manager%' then 'InvFundMan'

							when cathZ.Name like '%Clearing & Settlement organization%' then 'PaySys'

							when cathZ.Name like '%Pawn shop%' then 'Lombard'

							when cathZ.Name like '%Deposit Guarantee fund%' then 'DepGuarFund'

							when cathZ.Name like '%Regulated market%' then 'RegMarket'

							when cathZ.Name like '%Other financial organization%' then 'OthFinOrg'

							when cathZ.Name like '%Other supporting financial organization%' then 'OthAuxFinOrg'

							when cathZ.Name like '%Non-financial entity%' then 'NonFinOrg'

							when cathZ.Name like '%Private entrepreneurship%' then 'SoleEnt'

							when cathZ.Name like '%Other household entity%' then 'OthHousehold'

							when cathZ.Name like '%Non-profit organizations serving households%' then 'NonProfit'

							else ''

						end as N14
						, 'N/A' as O15
						, isnull(firPZ.MIC, '') as P16
						, '' as Q17
						, '' as R18
						, '' as S19
						, '' as T20
						, '' as U21
						, '' as V22
						, '' as W23
						, '' as X24
						, iif(tra.BuySell = 1 , assD.N
ame , assP.name) as Y25
						, iif(tra.BuySell = 2 , assD.Name , assP.name) as Z26
						, iif(tra.BuySell = 1 , tra.Qty , tra.volume1) as AA27
						, iif(tra.BuySell = 2 , tra.Qty , tra.volume1) as AB28
						, Tra.Price as AC29
						, 'N/A' as AD30
	
					, case when FX.AE31 < 100000 then  N'<100.000'
								when FX.AE31 < 400000 then  N'100.000 – 400.000'
								when FX.AE31 < 1500000 then  N'400.000 – 1.500.000'
								when FX.AE31 < 3000000 then  N'1.500.000 – 3.000.000'
								when FX.AE31 < 6
000000 then  N'3.000.000 – 6.000.000'
								when FX.AE31 < 11000000 then  N'6.000.000 – 11.000.000'
								when FX.AE31 < 20000000 then  N'11.000.000 – 20.000.000'
								when FX.AE31 < 40000000 then  N'20.000.000 – 40.000.000'
								when FX.AE31 < 
180000000 then  N'40.000.000 – 80.000.000'
								when FX.AE31 < 220000000then  N'80.000.000 – 220.000.000'
								when FX.AE31 < 800000000 then  N'220.000.000 – 800.000.000'
								else N'>800.000.000' end as AE31
						, 'NonCash' as AF32
						, 'No
nCash' as AG33
						, IIF (sub.SubAccCode in ('ARMBR_Subacc') , 'OnItsBehalf', 'OnCustBehalf') as AH34
						, IIF (sub.SubAccCode in ('ARMBR_Subacc') , 'OnItsName', 'OnCustName') as AI35
						, 'Direct' as AJ36
						, '' as AK37
						, dbo.fIntToDate
Varchar (Tra.TradeDate) as AL38
						, dbo.fIntToDateVarchar (Tra.PutPlannedDate) as AM39
						, case

						when tra.tradetime <   3000000   then '00:00:00 – 00:30:00'

						when tra.tradetime <  10000000   then '00:30:00 – 01:00:00'

						when tra.tradetime <  13000000   then '01:00:00 – 01:30:00'

						when tra.tradetime <  20000000   then '01:30:00 – 02:00:00'

						when tra.tradetime <  23000000   then '02:00:00 – 02:30:00'

						when tra.tradetime <  30000000   then '02:30:00 – 03:00:00'

						when tra.tradetime <  33000000   then '03:00:00 – 03:30:00'

						when tra.tradetime <  40000000   then '03:30:00 – 04:00:00'

						when tra.tradetime <  43000000   then '04:00:00 – 04:30:00'

						when tra.tradetime <  50000000   then '04:30:00 – 05:00:00'

						when tra.tradetime <  53000000   then '05:00:00 – 05:30:00'

						when tra.tradetime <  60000000   then '05:30:00 – 06:00:00'

						when tra.tradetime <  63000000   then '06:00:00 – 06:30:00'

						when tra.tradetime <  70000000   then '06:30:00 – 07:00:00'

						when tra.tradetime <  73000000   then '07:00:00 – 07:30:00'

						when tra.tradetime <  80000000   then '07:30:00 – 08:00:00'

						when tra.tradetime <  83000000   then '08:00:00 – 08:30:00'

						when tra.tradetime <  90000000   then '08:30:00 – 09:00:00'

						when tra.tradetime <  93000000   then '09:00:00 – 09:30:00'

						when tra.tradetime < 100000000   then '09:30:00 – 10:00:00'

						when tra.tradetime < 103000000   then '10:00:00 – 10:30:00'

						when tra.tradetime < 110000000   then '10:30:00 – 11:00:00'

						when tra.tradetime < 113000000   then '11:00:00 – 11:30:00'

						when tra.tradetime < 120000000   then '11:30:00 – 12:00:00'

						when tra.tradetime < 123000000   then '12:00:00 – 12:30:00'

						when tra.tradetime < 130000000   then '12:30:00 – 13:00:00'

						when tra.tradetime < 133000000   then '13:00:00 – 13:30:00'

						when tra.tradetime < 140000000   then '13:30:00 – 14:00:00'

						when tra.tradetime < 143000000   then '14:00:00 – 14:30:00'

						when tra.tradetime < 150000000   then '14:30:00 – 15:00:00'

						when tra.tradetime < 153000000   then '15:00:00 – 15:30:00'

						when tra.tradetime < 160000000   then '15:30:00 – 16:00:00'

						when tra.tradetime < 163000000   then '16:00:00 – 16:30:00'

						when tra.tradetime < 170000000   then '16:30:00 – 17:00:00'

						when tra.tradetime < 173000000   then '17:00:00 – 17:30:00'

						when tra.tradetime < 180000000   then '17:30:00 – 18:00:00'

						when tra.tradetime < 183000000   then '18:00:00 – 18:30:00'

						when tra.tradetime < 190000000   then '18:30:00 – 19:00:00'

						when tra.tradetime < 193000000   then '19:00:00 – 19:30:00'

						when tra.tradetime < 200000000   then '19:30:00 – 20:00:00'

						when tra.tradetime < 203000000   then '20:00:00 – 20:30:00'

						when tra.tradetime < 210000000   then '20:30:00 – 21:00:00'

						when tra.tradetime < 213000000   then '21:00:00 – 21:30:00'

						when tra.tradetime < 220000000   then '21:30:00 – 22:00:00'

						when tra.tradetime < 223000000   then '22:00:00 – 22:30:00'

						when tra.tradetime < 230000000   then '22:30:00 – 23:00:00'

						when tra.tradetime < 233000000   then '23:00:00 – 23:30:00'

						else '23:30:00 – 00:00:00'

					end as AN40

					, IIF (fir.name LIKE '%Raiffeisenbank%' OR fir.name LIKE '%ULTIMA INVESTMENTS CYPRUS LIMITED%', N'áã ÐÐ ãÏ³ñ·³íáñíáÕ ßáõÏ³', N'ÐÐ ãÏ³ñ·³íáñíáÕ ßáõÏ³') as AO41

					, 'WEB' as AP42

					, cast (0 as float) as AQ43

					, cast (0 as float) as AR44

					, cast (0 as float) as AS45

					, cast (0 as float) as AT46

					, cast (0 as float) as AU47

					, cast (0 as float) as AV48

					, 0 as AW49

					, iif(isnull(co2.OrderBy, 5) < isnull(co1.OrderBy, 5) , 1, 0) as BackOrder



		, sub.SubAccCode
		, cast('' as varchar(500)) as Subaccs
		, Tra.id
		, cast('' as varchar(500)) as SumID
			
		INTO #r
		FROM QORT_BACK_DB.dbo.Trades Tra 
		OUTER APPLY (

			SELECT isnull(firCP.id, Tra.CpFirm_ID) as CpFirm_ID

			FROM QORT_BACK_DB.dbo.Trades TraCP 

			LEFT OUTER JOIN QORT_BACK_DB.dbo.Subaccs subCP ON subCP.id = TraCP.subacc_ID 

			LEFT OUTER JOIN QORT_BACK_DB.dbo.Firms firCP ON firCP.id = subCP.OwnerFirm_ID

			WHERE TraCP.id = Tra.CpTrade_ID

		) AS CP
		left outer join QORT_BACK_DB.dbo.Firms fir on fir.id = CP.CpFirm_ID
		left outer join QORT_BACK_DB.dbo.Countries co on co.id = fir.Country_ID
		left outer join QORT_BACK_DB.dbo.OrgCathegories cath on cath.id = fir.OrgCathegoriy_ID
		left outer
 join QORT_BACK_DB.dbo.FirmProperties FirP on FirP.Firm_ID = fir.ID
		left outer join QORT_BACK_DB.dbo.Subaccs sub on sub.id = tra.subacc_ID -- FirP on FirP.Firm_ID = fir.ID
		left outer join QORT_BACK_DB.dbo.Firms firZ on firZ.id = sub.OwnerFirm_ID
		lef
t outer join QORT_BACK_DB.dbo.Countries coZ on coZ.id = firZ.Country_ID
		left outer join QORT_BACK_DB.dbo.OrgCathegories cathZ on cathZ.id = firZ.OrgCathegoriy_ID
		left outer join QORT_BACK_DB.dbo.FirmProperties FirPZ on FirPZ.Firm_ID = firZ.ID
		left o
uter join QORT_BACK_DB.dbo.Securities sec on sec.id = Tra.Security_ID
		left outer join QORT_BACK_DB.dbo.Assets assD on assD.id = sec.Asset_ID
		left outer join QORT_BACK_DB.dbo.Assets assP on assP.id = Tra.CurrPayAsset_ID
		left outer join @CurOrder co1 
on co1.Currency =  iif(tra.BuySell = 2 , assD.Name , assP.name)

		left outer join @CurOrder co2 on co2.Currency = iif(tra.BuySell = 1 , assD.Name , assP.name)
		OUTER APPLY (

				SELECT 

					dbo.fn_Quote_AMD(

						CASE 

							WHEN ISNULL(co2.OrderBy, 5) < ISNULL(co1.OrderBy, 5) 

								 THEN sec.Asset_ID 

								 ELSE Tra.CurrPayAsset_ID 

						END, 

						Tra.TradeDate

					) * (CASE 

							WHEN ISNULL(co2.OrderBy, 5) < ISNULL(co1.OrderBy, 5) 

								 THEN Tra.Qty

								 ELSE Tra.Volume1

						END) AS AE31

			) AS FX

		outer apply ( select id from QORT_BACK_DB.dbo.TradeInstrLinks where Trade_ID = Tra.id or Trade_ID = Tra.CpTrade_ID) as CheckOrder 


		WHERE Tra.TradeDate >= @StartDate and Tra.TradeDate <= @EndDate
		AND Tra.TSSection_ID = 155
		 AND Tra.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND tra.NullStatus = 'n'

          AND tra.Enabled = 0

          AND tra.IsDraft = 'n'

          AND tra.IsProcessed = 'y'

		  and (CheckOrder.id is not Null 

				or 

			   Tra.CpTrade_ID < 0)

		 and sub.SubAccCode not in ('ARMBR_Subacc')


		  UPDATE t

			SET AW49 = isnull(matches.total_count, 0)

			FROM #r t

			JOIN (

				SELECT 

					B2, C3, D4, E5, F6, G7, H8, I9, J10, L12, M13, N14, O15, P16, Q17, R18, S19, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, AL38, AM39, AN40, AO41, AP42,

					COUNT(*) AS total_count

				FROM #r

				GROUP BY B2, C3, D4, E5, F6, G7, H8, I9, J10, L12, M13, N14, O15, P16, Q17, R18, S19, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, AL38, AM39, AN40, AO41, AP42

				--HAVING COUNT(*) > 1  -- если нужно учитывать только группы, где 2+ совпали

			) matches

			ON t.B2 = matches.B2 AND

			   t.C3 = matches.C3 AND

			   t.D4 = matches.D4 AND

			   t.E5 = matches.E5 AND

			   t.F6 = matches.F6 AND

			   t.G7 = matches.G7 AND

			   t.H8 = matches.H8 AND

			   t.I9 = matches.I9 AND

			   t.J10 = matches.J10 AND

			   t.L12 = matches.L12 AND

			   t.M13 = matches.M13 AND

			   t.N14 = matches.N14 AND

			   t.O15 = matches.O15 AND

			   t.P16 = matches.P16 AND

			   t.Q17 = matches.Q17 AND

			   t.R18 = matches.R18 AND

			   t.S19 = matches.S19 AND

			   t.Y25 = matches.Y25 AND

			   t.Z26 = matches.Z26 AND

			   t.AC29 = matches.AC29 AND

			   t.AD30 = matches.AD30 AND

			   t.AE31 = matches.AE31 AND

			   t.AF32 = matches.AF32 AND

			   t.AG33 = matches.AG33 AND

			   t.AH34 = matches.AH34 AND

			   t.AI35 = matches.AI35 AND

			   t.AJ36 = matches.AJ36 AND

			   t.AL38 = matches.AL38 AND

			   t.AM39 = matches.AM39 AND

			   t.AN40 = matches.AN40 AND

			   t.AO41 = matches.AO41 AND

			   t.AP42 = matches.AP42;



-- Обновим таблицу с медианой

WITH MedianCTE AS (

    SELECT 

        *,

        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(iif(backorder = 0 , AB28, AA27) AS FLOAT)) 

   OVER (PARTITION BY 

                B2, C3, D4, E5, F6, G7, H8, I9, J10, L12, M13, N14, O15, P16, Q17, 

                R18, S19, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

                AL38, AM39, AN40, AO41, AP42

            ) AS MedianVal,

		MIN(AA27) OVER (PARTITION BY 

                B2, C3, D4, E5, F6, G7, H8, I9, J10, L12, M13, N14, O15, P16, Q17, 

                R18, S19, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

                AL38, AM39, AN40, AO41, AP42

            ) AS MinAA27,

		MAX(AA27) OVER (PARTITION BY 

                B2, C3, D4, E5, F6, G7, H8, I9, J10, L12, M13, N14, O15, P16, Q17, 

                R18, S19, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

                AL38, AM39, AN40, AO41, AP42

            ) AS MaxAA27,

		MIN(AB28) OVER (PARTITION BY 

                B2, C3, D4, E5, F6, G7, H8, I9, J10, L12, M13, N14, O15, P16, Q17, 

                R18, S19, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

                AL38, AM39, AN40, AO41, AP42

            ) AS MinAB28,

		MAX(AB28) OVER (PARTITION BY 

                B2, C3, D4, E5, F6, G7, H8, I9, J10, L12, M13, N14, O15, P16, Q17, 

                R18, S19, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

                AL38, AM39, AN40, AO41, AP42

            ) AS MaxAB28,

		STDEV(iif(backorder = 0 , AB28, AA27)) OVER (PARTITION BY 

                B2, C3, D4, E5, F6, G7, H8, I9, J10, L12, M13, N14, O15, P16, Q17, 

                R18, S19, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

                AL38, AM39, AN40, AO41, AP42

            ) AS StdevVal

				 FROM #r

				),

				IDAgg AS (

							SELECT 

								B2, C3, D4, E5, F6, G7, H8, I9, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

								AL38, AM39, AN40, AO41, AP42,

								STRING_AGG(CAST(ID AS VARCHAR(MAX)), ',') AS IDList

							FROM #r

							GROUP BY B2, C3, D4, E5, F6, G7, H8, I9, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

									 AL38, AM39, AN40, AO41, AP42

						),

				SubAgg AS (

							SELECT 

								B2, C3, D4, E5, F6, G7, H8, I9, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

								AL38, AM39, AN40, AO41, AP42,

								STRING_AGG(CAST(SubAccCode AS VARCHAR(MAX)), ',') AS SUBList

							FROM #r

							GROUP BY B2, C3, D4, E5, F6, G7, H8, I9, Y25, Z26, AC29, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

									 AL38, AM39, AN40, AO41, AP42

						)

				UPDATE t

				SET 

				AQ43 = cte.MinAA27,

				AR44 = cte.MaxAA27,

				AS45 = cte.MinAB28,

				AT46 = cte.MaxAB28,

				AU47 = cte.MedianVal,

				AV48 = isnull(round(cte.StdevVal,3),0),

				Subaccs = ida2.SUBList,

				SumID = ida.IDList



				FROM #r t

				JOIN MedianCTE cte ON t.B2 = cte.B2 AND t.C3 = cte.C3 AND t.D4 = cte.D4 AND t.E5 = cte.E5 AND

									  t.F6 = cte.F6 AND t.G7 = cte.G7 AND t.H8 = cte.H8 AND t.I9 = cte.I9 AND

									  t.J10 = cte.J10 AND t.L12 = cte.L12 AND t.M13 = cte.M13 AND t.N14 = cte.N14 AND

									  t.O15 = cte.O15 AND t.P16 = cte.P16 AND t.Q17 = cte.Q17 AND t.R18 = cte.R18 AND

									  t.S19 = cte.S19 AND t.Y25 = cte.Y25 AND t.Z26 = cte.Z26 AND t.AC29 = cte.AC29 AND 

									  t.AD30 = cte.AD30 AND t.AE31 = cte.AE31 AND t.AF32 = cte.AF32 AND t.AG33 = cte.AG33 AND

									  t.AH34 = cte.AH34 AND t.AI35 = cte.AI35 AND t.AJ36 = cte.AJ36 AND t.AL38 = cte.AL38 AND

									  t.AM39 = cte.AM39 AND t.AN40 = cte.AN40 AND t.AO41 = cte.AO41 AND t.AP42 = cte.AP42

				JOIN IDAgg ida ON t.B2 = ida.B2 AND t.C3 = ida.C3 AND t.D4 = ida.D4 AND t.E5 = ida.E5 AND

									  t.F6 = ida.F6 AND t.G7 = ida.G7 AND t.H8 = ida.H8 AND t.I9 = ida.I9 AND

									  t.Y25 = ida.Y25 AND t.Z26 = ida.Z26 AND t.AC29 = ida.AC29 AND 

									  t.AD30 = ida.AD30 AND t.AE31 = ida.AE31 AND t.AF32 = ida.AF32 AND t.AG33 = ida.AG33 AND

									  t.AH34 = ida.AH34 AND t.AI35 = ida.AI35 AND t.AJ36 = ida.AJ36 AND t.AL38 = ida.AL38 AND

									  t.AM39 = ida.AM39 AND t.AN40 = ida.AN40 AND t.AO41 = ida.AO41 AND t.AP42 = ida.AP42

				JOIN SubAgg ida2 ON t.B2 = ida2.B2 AND t.C3 = ida2.C3 AND t.D4 = ida2.D4 AND t.E5 = ida2.E5 AND

									  t.F6 = ida2.F6 AND t.G7 = ida2.G7 AND t.H8 = ida2.H8 AND t.I9 = ida2.I9 AND

									  t.Y25 = ida2.Y25 AND t.Z26 = ida2.Z26 AND t.AC29 = ida2.AC29 AND 

									  t.AD30 = ida2.AD30 AND t.AE31 = ida2.AE31 AND t.AF32 = ida2.AF32 AND t.AG33 = ida2.AG33 AND

									  t.AH34 = ida2.AH34 AND t.AI35 = ida2.AI35 AND t.AJ36 = ida2.AJ36 AND t.AL38 = ida2.AL38 AND

									  t.AM39 = ida2.AM39 AND t.AN40 = ida2.AN40 AND t.AO41 = ida2.AO41 AND t.AP42 = ida2.AP42

				where t.AW49 <> 0







		--select * from #r;
		;WITH RankedCTE AS (

						SELECT *,

							   ROW_NUMBER() OVER (

								   PARTITION BY 

									   B2, C3, D4, E5, F6, G7, H8, I9, J10, L12, M13, N14, O15, P16, Q17, 

									   R18, S19, Y25, Z26, AD30, AE31, AF32, AG33, AH34, AI35, AJ36, 

									   AL38, AM39, AN40, AO41, AP42

								   ORDER BY (SELECT NULL)  -- порядок не важен, просто одна из группы

							   ) AS rn

						FROM #r

					)

					DELETE FROM RankedCTE

					WHERE rn > 1;

					;WITH NumberedRows AS (

					SELECT 

						*,

						ROW_NUMBER() OVER (ORDER BY (TradeDate)) AS RowNum

					FROM #r

				)

				UPDATE t

				SET A1 = '42000' +

					RIGHT('0' + CAST(t.TradeDate % 100 AS VARCHAR(2)), 2) +       -- DD

					RIGHT('0' + CAST((t.TradeDate / 100) % 100 AS VARCHAR(2)), 2) +-- MM

					RIGHT(CAST(t.TradeDate / 10000 AS VARCHAR(4)), 2)  + -- YY

					IIF(CONCAT(t.A1, RowNum) < 10, '0','')+

					cast (CONCAT(t.A1, RowNum) as varchar(5))

				FROM #r t

				JOIN NumberedRows nr ON t.RowN = nr.RowN 

------------------обнуляем значения в покупках, где старшая валюта в продаже

	--/*			

				UPDATE t

				SET AA27 = 0,

					AQ43 = 0,

					AR44 = 0

				FROM #r t

				where t.BackOrder = 0

--*/
------------------обнуляем значения в продажах, где старшая валюта в покупке
				UPDATE t

				SET AB28 = 0,

					AS45 = 0,

					AT46 = 0

				FROM #r t

				where t.BackOrder = 1 

		select * from #r order by A1
	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		SET @Message = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Mess
age, 1001)
		PRINT @Message
		SELECT @Message AS Result, 'red' AS ResultColor
	END CATCH
END

