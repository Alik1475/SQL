







-- exec QORT_ARM_SUPPORT.dbo.ReconcilAssetsDepoliteEmail

CREATE PROCEDURE [dbo].[ReconcilAssetsDepoliteEmail]



AS



BEGIN



	begin try

		

		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)



		declare @Message varchar(1024)



		--declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Firms_ARM\Clients_from_register_apgrade.xlsx';

		--declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\test\Copy of Clients_from_register_apgrade.xlsx';

		declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Clients\Copy of Clients_from_register_apgrade.xlsx'

	    declare @Sheet1 varchar(64) = 'Sheet1' 



		declare @SendMail bit = 0

		declare @Result varchar(128) 

		declare @NotifyEmail varchar(1024) = 'aleksandr.mironov@armbrok.am;sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am;armine.khachatryan@armbrok.am;dianna.petrosyan@armbrok.am;anahit.titanyan@armbrok.am'

		

		declare @sql varchar(1024)



		

		 if OBJECT_ID('tempdb..##result', 'U') is not null drop table ##result

		if OBJECT_ID('tempdb..##f', 'U') is not null drop table ##f

		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t





    select  kind.NAME_ARM as NAMEKIND_ARM, kind.NAME_ENG as NAMEKIND_ENG , type.NAME_ARM as NAMETYPE_ARM, type.NAME_ENG as NAMETYPE_ENG 

	 , assCur.Name as curAss

	, sec.secur

	, sec.num

	, ass.ISIN

	, ass.Name NameQ

	, s2.StatusTXT

	--,* 

	into ##result

	from [192.168.13.8].[Depositary].[dbo].[SECURKIND] sec

  outer apply(select top 1 NAME_A as NAME_ARM, NAME_E as NAME_ENG from [192.168.13.8].[Depositary].[dbo].[DICTION_S] where NUMID = sec.KIND and CCOLUMN = 'KIND') KIND

  outer apply(select top 1 NAME_A as NAME_ARM, NAME_E as NAME_ENG from [192.168.13.8].[Depositary].[dbo].[DICTION_S] where NUMID = sec.TYPE and CCOLUMN = 'TYPE') TYPE

  full outer join [QORT_BACK_DB].[dbo].[Assets] ass on ass.ISIN = Sec.num COLLATE SQL_Latin1_General_CP1_CI_AS and Enabled = 0 

	left outer join QORT_BACK_DB.dbo.Assets assCur on assCur.id =  ass.BaseCurrencyAsset_ID

		outer apply (

SELECT 

    CASE 

        WHEN sec.num IS NULL THEN 

            'Missed In Depolite ' + ass.ISIN COLLATE SQL_Latin1_General_CP1_CI_AS

        WHEN ass.ISIN IS NULL THEN 

            'Missed In Qort ' + sec.num COLLATE SQL_Latin1_General_CP1_CI_AS

        ELSE 

            ''

            + CASE 

                WHEN sec.kind = 2 AND ass.AssetClass_Const NOT IN (6) THEN 

                    ', KIND: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' '

                ELSE ''

              END

            + CASE 

                WHEN sec.scur COLLATE SQL_Latin1_General_CP1_CI_AS <> assCur.Name COLLATE SQL_Latin1_General_CP1_CI_AS THEN 

                    ', CURRENCY: ' + sec.scur COLLATE SQL_Latin1_General_CP1_CI_AS + ' depolite/qort ' + assCur.Name COLLATE SQL_Latin1_General_CP1_CI_AS

                ELSE ''

              END

            + CASE 

                WHEN sec.MINAMNT <> ass.BaseValue THEN 

                    ', NOMINAL: ' + CAST(sec.MINAMNT AS VARCHAR(12)) + ' depolite/qort ' + CAST(ass.BaseValue AS VARCHAR(12))

                ELSE ''

              END

            + CASE 

                WHEN sec.kind = 4 AND ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS IN ('Armenia') THEN 

                    ', KIND: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-Armenia'

                WHEN sec.kind = 3 AND ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN ('Armenia') THEN 

                    ', KIND: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notArmenia'

                WHEN sec.kind IN (1, 5) AND (ass.AssetClass_Const IN (6) OR ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS IN ('Armenia')) THEN 

                    ', KIND: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notOther'

                ELSE ''

              END

            + CASE 

                WHEN sec.type = 1 AND ((ass.AssetClass_Const NOT IN (6, 7, 9) OR ass.IsCouponed = 'y')) THEN 

                    ', TYPE: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-withCoupon'

                WHEN sec.type = 2 AND ((ass.AssetClass_Const NOT IN (6, 7, 9) OR ass.IsCouponed = 'n')) THEN 

                    ', TYPE: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notCoupon'

                WHEN sec.type IN (3, 7, 8) AND ((ass.AssetClass_Const NOT IN (8,5) OR ass.AssetSort_Const NOT IN (1))) THEN 

                    ', TYPE: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-NOTcommon'

                WHEN sec.type IN (4) AND ((ass.AssetClass_Const NOT IN (8,5) OR ass.AssetSort_Const NOT IN (2))) THEN 

                    ', TYPE: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-NOTpreferred'

                WHEN sec.type IN (5) AND ass.AssetClass_Const NOT IN (18) THEN 

                    ', TYPE: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notETF'

                WHEN sec.type IN (6) AND ass.AssetClass_Const NOT IN (16) THEN 

                    ', TYPE: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notADR'

                ELSE ''

              END



		/*				+ iif(isnull(t.IDocDate, 0) <> isnull(ca.DateSign, 0), ', IDocDate(agreement)', '')

						--+ iif(isnull(QORT_ARM_SUPPORT.dbo.fDateVarcharToInt2(t.IDocDateEnd), 0) <> isnull(f.IDocDateEnd, 0), ', IDocDateEnd', '')

						+ iif(IsClosedFile <> IsClosedQort, ', IDocDateEnd', '')

						+ iif(isnull(t.IsResident, '') <> isnull(f.IsResident, ''), ', IsResident', '')

						+ iif(isnull(t.Email, '') <> isnull(f.Email, ''), ', Email', '')

						+ iif(isnull(t.Phones, '') <> isnull(f.Phones, ''), ', Phones', '')

						--+ iif(isnull(QORT_ARM_SUPPORT.dbo.fDateVarcharToInt2(t.DateOfBirth), 0) <> isnull(f.DateOfBirth, 0), ', DateOfBirth', '')

						+ iif(t.IsFirm = 0 and (isnull(QORT_ARM_SUPPORT.dbo.fDateVarcharToInt2Back(t.DateOfBirth), 0) <> isnull(f.DateOfBirth, 0)), ', DateOfBirth', '')

						+ iif(isnull(t.INN, '') <> isnull(f.INN, ''), ', INN', '')

						+ iif(isnull(t.ResidentCountry, '') <> isnull(f.TaxResidentCountry, ''), ', ResidentCountry_'+t.ResidentCountry+'_REGISTER/QORT_'+ISNULL(f.TaxResidentCountry,''), '')

						--+ iif(isnull(t.AddrJuSettlement, '') <> isnull(f.AddrJuSettlement, ''), ', AddrJuSettlement', '')

						--+ iif(isnull(t.LatAddrJu, '') <> isnull(f.LatAddrJu, ''), ', LatAddrJu', '') -- пока не сверяем

						+ iif(isnull(t.DEPODivisionCode, '') <> isnull(depo.DEPODivisionCode, ''), ', DEPOlITE_ACC_'+t.DEPODivisionCode+'_REGISTER/QORT_'+ISNULL(depo.DEPODivisionCode,''), '')

						+ iif(isnull(t.DEPOCode, '') <> isnull(depo.DEPOCode, ''), ', DEPEND'+t.DEPOCode+'_REGISTER/QORT_'+ISNULL(depo.DEPOCode,''), '')

						+ iif(isnull(t.ManagerSales, -1) <> isnull(f.Sales_ID, -1), ', Sales_ID', '')

						+ iif(isnull(t.ASComment, '') <> isnull(f.SubAccComment, ''), ', AS (Comment)', '')			

						+ iif(t.IsFirm = 0 and (isnull(QORT_ARM_SUPPORT.dbo.fDateVarcharToInt2Back(t.ExpiryDate), 0) <> isnull(f.ExpiryDate, 0)), ', ExpiryDate', '')

						+ iif(isnull(t.ResidencePermitNumber, '') <> isnull(f.FDocNum, ''), ', ResidencePermitNumber', '')						

						+ iif((isnull(QORT_ARM_SUPPORT.dbo.fDateVarcharToInt2Back(t.ResidencyExpire), 0) <> isnull(f.FDocDateEnd, 0)), ', ResidencyExpire', '')

						+ iif(case isnull(t.IsRussian, '') when 'Russian' then 2 when 'Non-russian' then 4 when '' then -1 else 999 end <> f.OrgCathegoriy_ID, ', IsRussian', '')

							+ iif(isnull(t.IsSegregated, -1) <> isnull(f.AccountType_ID, -1), ', IsSegregated', '')

--*/

				end StatusTXT

		) s1

		outer apply (

			select case when left(s1.StatusTXT, 2) = ', ' then 'Mismatched: ' + right(StatusTXT, len(StatusTXT) - 2)

						when StatusTXT = '' then 'OK'

						else StatusTXT end StatusTXT

		) s2

		outer apply (select iif(s2.StatusTXT = 'OK', 'green', 'red') ResultColor) s3

	

  where NOT (Sec.num IS NULL AND ass.ISIN IS NULL) and ass.AssetClass_Const not in(2,3,4,12,13,14,15,17) and ass.Enabled = 0 and ass.CancelDate < @todayInt



	select * from ##result --order by BOCode

	return

	set @SendMail = 0 -- начало блока отпраки сообщений

	--if exists (select tradeID from @result) begin

	set @SendMail = 1

	--end



	if @SendMail = 1 begin

/*

	declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Reports'

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

		declare @SheetClient varchar(32) = 'Assets'

		declare @fileTemplate varchar(512) = 'template_Asset_Check_Bloomberg.xlsx'

		declare @fileReport varchar(512) = 'Asset_Check_Bloomberg_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '.xlsx'

		declare @cmd varchar(512)

		declare @sql2 varchar(1024)



		set @cmd = 'copy "' + @FilePath + @fileTemplate + '" "' + @FilePath + @fileReport + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		SET @sql2 = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FilePath + @fileReport + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @SheetClient + '$A1:Q1000000]'')

			select ISIN, ISINQ, Issue_date, Issue_dateQ, Ticker, AssetShortNameQ, Nominal, NominalQ

			, Maturity_date, Maturity_dateQ, Issuer, IssuerQ, Sanction, SanctionQ, Result'

			+ ' from ##Result order by ISINQ'

		exec(@sql2)

		*/

		declare @NotifyMessage varchar(max)

		declare @NotifyTitle varchar(1024) = null

	set @NotifyMessage = cast(

		(

			select '//1\\' + isnull(tt.SECUR,'NULL')	

				+ '//2\\' + isnull(tt.NameQ,'NULL')

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + isnull(tt.num ,'NULL')

				+ '//2\\' + tt.Result

				+ '//2\\' + isnull(a.subaccName, t.NameU) 

				+ '//2\\' + isnull(b.AddrJuSettlement, t.AddrFSettlementU) collate Cyrillic_General_CI_AS

			--	+ '//2\\' + isnull(a.subaccName, t.EngName) 

			--	+ '//2\\' + t.EngName

			--	+ '//2\\' + tt.Result

			--	+ '//2\\' + tt.ResultColor

			--	+ '//2\\' + tt.ResultColor

			--	+ '//2\\' + tt.ResultColor

			--	+ '//2\\' + tt.ResultColor

			--	+ '//2\\' + tt.ResultColor

			--	+ '//2\\' + tt.ResultColor

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

		

			from ##result tt

			--inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = tt.tradeId

			left outer join #t t on tt.SubAccCode = t.SubAccCode

			left outer join QORT_BACK_DB.dbo.Subaccs a with (nolock) on tt.SubAccCode = a.SubAccCode collate Cyrillic_General_CI_AS

			left outer join QORT_BACK_DB.dbo.Firms b with (nolock) on tt.BOCode = a.OwnerFirm_ID --collate Cyrillic_General_CI_AS

			/*left outer join QORT_BACK_DB.dbo.Assets aPrice with (nolock) on aPrice.id = t.CurrPriceAsset_ID

			left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

			left outer join QORT_BACK_DB.dbo.Firms fCp with (nolock) on fCp.id = t.CpFirm_ID

			--outer apply (select datediff(day, cast(cast(t.PutPlannedDate as varchar) as date), @ReportDate) DaysDelayed) dd

			outer apply (select case when DaysDelayed > @MaxDaysPercent then @MaxDaysPercent + @MaxDaysPercent

								when DaysDelayed < -@MaxDaysPercent then 0

								else @MaxDaysPercent + @MaxDaysPercent * DaysDelayed / @MaxDaysPercent

								end * 100 / 2 / @MaxDaysPercent DelayPercent 

						) DelayPercent*/

			where tt.result <> 'OK' --and  tt.SubAccCode <> 'AS1105' and  tt.SubAccCode <> 'AS1347' and  tt.SubAccCode <> 'AS1402'

			order by tt.BOCode asc

			

			for xml path('')

		) as varchar(max))

		

	--set @fileReport = @FilePath + @fileReport*/

	set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		set @NotifyMessage = 'is an automatically generated message.<br/><br/><b>Below is the result of reconciliation Register.xlsx VS Qort.<br/><br/><b> http://192.168.14.20/reports/report/QORT_PROD/Reconciliation/Reconciliatio_Clients_Statics'

		+ '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>BOCode'

			+ '</td><td>SubAccCode'

			+ '</td><td>CustomerCode'

			+ '</td><td>Result'

			+ '</td><td>Name'

			+ '</td><td>Address'

		--	+ '</td><td>Nominal(Bloomberg)'

		--	+ '</td><td>Nominal(Qort)'

		--	+ '</td><td>MaturityDate(Bloomberg)'

		--	+ '</td><td>MaturityDate(Qort)'

		--	+ '</td><td>Issuer(Bloomberg)'

		--	+ '</td><td>Issuer(Qort)'

		--	+ '</td><td>Sanction'

		--	+ '</td><td>SanctionQ'

		--	+ '</td><td>Result' 

			+ '</tr>' + @NotifyMessage + '</table>'



	--		set @fileReport = @FilePath + @fileReport

	set @NotifyTitle = 'Alert!!! Сlient attributes to check'

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage --*/

			--, @file_attachments = @fileReport



		--set @cmd = 'del "' + @FilePath + 'Asset_Check_Bloomberg_*.*"'

		--exec master.dbo.xp_cmdshell @cmd, no_output



		print @NotifyTitle

		--print @NotifyMessage

			end -- конец блока отправки сообщения

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END

