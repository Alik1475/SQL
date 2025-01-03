﻿







-- exec QORT_ARM_SUPPORT.dbo.ReconcilClientsStaticsEmail

CREATE PROCEDURE [dbo].[ReconcilClientsStaticsEmail]



AS



BEGIN



	begin try

		EXEC xp_cmdshell 'powershell.exe -Command "Invoke-Command -ComputerName 192.168.14.22 -ScriptBlock { schtasks /run /tn ''StartExcelUpgradeCl'' } -Credential (Import-Clixml -Path D:\Secure\MyCredentials.xml)"';

	WAITFOR DELAY '00:01:00' 

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



		

		 if OBJECT_ID('tempdb..##resultClients', 'U') is not null drop table ##resultClients

		if OBJECT_ID('tempdb..##f', 'U') is not null drop table ##f

		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t

	

		SET @sql = 'SELECT * INTO ##f

		FROM OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$A3:ZZ1000000]'')'



		exec(@sql)





		select

		      ff.BOCode

			, [Customer Code] CustomerCode -- ?????

			, [Full Name] NameU

			, [Address] AddrFSettlementU

			, [Contract number] IDocNum

			--, [Date of contract] IDocDate

			, try_convert(int, convert(varchar, [Date of contract], 112)) IDocDate

			, [Contract Termination Date] IDocDateEnd

			, case  when [Residency] = 'Russia' then 'Russian Federation (the)'

					when [Residency] = 'USA' then 'United States of America (the)'

					when [Residency] = 'UAE' then 'United Arab Emirates (the)'

					when [Residency] = 'Kyrgyz Republic' then 'Kyrgyzstan'

					when [Residency] = 'UK' then 'United Kingdom of Great Britain and Northern Ireland (the)'

					when [Residency] = 'British Virgin Islands' then 'Virgin Islands (British)'

					when [Residency] = 'Republic of Belarus' then 'Belarus'

					when [Residency] = 'Netherlands' then 'Netherlands (the)'

					when [Residency] = 'Republic of Uzbekistan' then 'Uzbekistan'

					when [Residency] = 'Russia tbc' then 'Russian Federation (the)'

					when [Residency] = 'Armenia tbc' then 'Armenia'

					when [Residency] = 'Slovak Republic' then 'Slovakia'

					when [Residency] = 'Republic of Panama' then 'Panama'

					when [Residency] = 'Cayman Islands' then 'Cayman Islands (the)'

					when [Residency] = 'Russian' then 'Russian Federation (the)'

					when [Residency] = 'Kyrgystan' then 'Kyrgyzstan'

					when [Residency] = 'Czech Republic' then 'Czechia'

					when [Residency] = 'Marshall Islands' then 'Marshall Islands (the)'

					when [Residency] = 'Cayman Islands' then 'Cayman Islands (the)'

					when [Residency] = 'Republic of Panama' then 'Panama'

					when [Residency] = 'BVI' then 'Virgin Islands (British)'

					when [Residency] = 'United Arab Emirates' then 'United Arab Emirates (the)'

				    else [Residency] 

			  end  ResidentCountry

			, iif([Residency RA of the client] in ('Resident', 'Rezident'), 'y', 'n') IsResident

			, [e-mail] Email

			, [Tel#] Phones

			, [Birthday] DateOfBirth

			--, [TIN] INN

			, try_convert(varchar(32), [TIN]) INN

			, [Customer Code(New)] SubAccCode

			--, [  Name for full name (other lang#)] EngName

			--, [Settlement (Register address)] AddrFSettlementU --AddrJuSettlement

			, [DEPOLITE] DEPODivisionCode

			, [DEPEND] DEPOCode	

			, s.id SubAccId

			, [Date of issue] DateOfIssue

			, [Manager-Sales] ManagerSales

			, [AS] ASComment

			, [Type] CorpInd

			, [Expiry date] ExpiryDate

			, [Residence permit number] ResidencePermitNumber

			, [Residency expire] ResidencyExpire

			, [Russian/Non-russian person] IsRussian

			, case [Tariffs plan] when 'Base' then 'Brokerage_fee_10' 

								  when '0.5' then 'Brokerage_fee_50'

								  when '0.3' then 'Brokerage_fee_30'

								  when 'Glocal' then 'Brokerage_fee_10'

								  else ''

								  end

			TariffsPlan

			, case [Segregated/ Not segregated] when 'Segregated' then 2 when 'Not segregated' then 4 else -1 end IsSegregated

			, dnd2 DocNumber

			, dnd3 DocDate

			, iif([Type] = 'ind', 0, 1) IsFirm

		into #t

		from ##f f

		left join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.SubAccCode = f.[Customer Code(New)] collate Cyrillic_General_CS_AS and s.Enabled = 0

		left outer join QORT_BACK_DB.dbo.Firms ff with (nolock) on ff.id = s.OwnerFirm_ID --and f.Enabled = 0

		outer apply (select replace([Documents number, date], ';', ',') dnd1) dnd1

		outer apply (select val dnd2 from dbo.fnt_ParseString_Num(dnd1, ',') where num = 1) dnd2

		outer apply (select dbo.fDateVarcharToInt2(replace(val, '.', '/')) dnd3 from dbo.fnt_ParseString_Num(dnd1, ',') where num = 2) dnd3

		where f.[Customer Code(New)] <> '#REF!' and f.[Customer Code(New)] <> '' and f.[Residency RA of the client] <> '' and f.[Full Name] <> ''







		select isnull(t.BOCOde, f.BOCode) BOCode

			, isnull(t.SubAccCode, f.SubAccCode) SubAccCode

			, s2.StatusTXT Result

			, s3.ResultColor

			--, t.DEPODivisionCode, t.DEPOCode

			--, depo.DEPODivisionCode, depo.DEPOCode

			--, isnull(t.NameU, f.NameU) NameU

		/*	, isnull(t.EngName, f.EngName) EngName

			, isnull(t.LatAddrJu, f.LatAddrJu) LatAddrJu*/

			, isnull(f.NameU, 'NULL') NameU

			, isnull(t.AddrFSettlementU, 'null') AddrFSettlementU

			, isnull(f.AddrJuSettlementU, 'NULL') AddrJuSettlementU

			, isnull(f.EngName, 'NULL') EngName

		--	, isnull(f.LatAddrJu, 'NULL') LatAddrJu

			--, *

		into ##resultClients

		from #t t

		full outer join (

			select f.BOCode, s.ConstitutorCode CustomerCode, f.IDocNum, f.IDocDate

				, f.IDocDateEnd ExpiryDate

				, f.IsResident

				, isnull(nullif(s.MarginEMail, ''), f.Email) Email

				--, f.Email

				, f.Phones

				, f.DateOfBirth, f.INN, f.EngName, f.LatAddrJu --f.AddrJuSettlement

				, fp.NameU, fp.AddrJuSettlementU

				, 'f.DEPODivisionCode' DEPODivisionCode, 'f.DEPOCode' DEPOCode

				, f.id FirmId

				, iif(f.IsFirm = 'y', 1, 0) IsFirm, fp.FDocNum, fp.FDocDateEnd

				, s.id SubAccId, s.SubAccCode, s.ConstitutorCode, s.Comment SubAccComment, s.AccountType_ID

				, f.Sales_ID, f.OrgCathegoriy_ID

				, f.RegistrName				

				, iif(s.ACSTAT_Const = 7, s.StatusChangeDate, 0) IDocDateEnd

				, cntr.Name TaxResidentCountry

			from QORT_BACK_DB.dbo.Subaccs s with (nolock)

			inner join QORT_BACK_DB.dbo.Firms f with (nolock) on f.id = s.OwnerFirm_ID

			--from QORT_BACK_DB.dbo.Firms f with (nolock)

			left outer join QORT_BACK_DB.dbo.FirmProperties fp with (nolock) on fp.Firm_ID = f.id

			left outer join QORT_BACK_DB.dbo.Countries cntr with (nolock) on cntr.ID = fp.TaxResidentCountry_ID

			--left outer join QORT_BACK_DB.dbo.Tariffs tf with (nolock) on tf.ID = tr.Tariff_ID

			where f.Enabled = 0 and f.FT_Flags & 1 = 1

		) f on f.BOCode = t.BOCode and f.SubAccId = t.SubAccId

			outer apply (

			select Tariff_ID

			from QORT_BACK_DB.dbo.ClientTariffs tr with (nolock) 

			where (tr.Firm_ID = f.FirmId and tr.Enabled <> tr.id and tr.Agent_ID = '-1') -- исключаем тарифы, где указан агент

			and (tr.CalcSubAcc_ID = -1 or tr.CalcSubAcc_ID = f.SubAccId ) --отбираем тех, кто не имеет разбивку тарифов по счетам или имеет (иначе дублируются)

			) ta1 

			outer apply (

			select tr.Name

			from QORT_BACK_DB.dbo.Tariffs tr with (nolock) 

			where tr.ID = ta1.Tariff_ID

			) ta



		outer apply (

			select top 1 DEPODivisionCode, DEPOCode

			from QORT_BACK_DB.dbo.FirmDEPOAccs fd with (nolock) 

			where fd.Firm_ID = f.FirmId and fd.Code = t.SubAccCode collate Cyrillic_General_CS_AS

			order by id desc

		) depo

		outer apply (

			--select top 1 ca.Num, ca.DateCreate DateSign --, ca.DateSign

			select top 1 ca.Num, ca.DateSign --, ca.DateSign

			from QORT_BACK_DB.dbo.ClientAgrees ca with (nolock)

			where ca.SubAcc_ID = t.SubAccId

			order by 2 desc, DateCreate desc--, ca.DateSign desc

		) ca

		outer apply (

			select isnull(QORT_ARM_SUPPORT.dbo.fDateVarcharToInt2Back(t.IDocDateEnd), 0) FileCloseDate

				, isnull(f.IDocDateEnd, 0) QortCloseDate

		) closeDates

		outer apply (

			select iif(FileCloseDate > 19000000 and FileCloseDate < @todayInt, 1, 0) IsClosedFile

				, iif(QortCloseDate > 19000000 and QortCloseDate < @todayInt, 1, 0) IsClosedQort

		) IsClosed

		outer apply (

			select case when t.BOCode is null and t.SubAccCode <> '' then 'SubAcc not found: ' + t.SubAccCode

					when t.BOCOde is null then 'Missed In File'

					when f.BOCode is null then 'Missed In Qort'

					else ''

						+ iif(IsClosedFile = 1 and IsClosedQort = 0, ', NOT CLOSED IN QORT', '')

						+ iif(IsClosedFile = 0 and IsClosedQort = 1, ', CLOSED IN QORT', '')

						+ iif(isnull(t.IsFirm, 0) <> isnull(f.IsFirm, 0), ', IsFirm', '')

						+ iif(isnull(t.NameU, '') <> isnull(f.NameU, ''), ', NameU', '')

						+ iif(isnull(t.AddrFSettlementU, '') <> isnull(f.AddrJuSettlementU, ''), ', AddrFSettlementU', '')

						+ iif(isnull(t.CustomerCode, '') <> isnull(f.CustomerCode, ''), ', CustomerCode', '')

						+ iif(isnull(t.TariffsPlan, '') <> LEFT(isnull(ta.name,''),16), ', TariffsPlan', '')

						+ iif(isnull(t.IDocNum, '') <> isnull(ca.Num, ''), ', NumOfContract', '')

						+ iif(t.IsFirm = 0 and (isnull(t.DocNumber, '') <> isnull(f.IDocNum, '')), ', NumRegistr', '')

						+ iif(t.IsFirm = 1 and (isnull(t.DocNumber, '') <> isnull(f.RegistrName, '')), ', NumRegistr', '')

						--+ iif(t.IsFirm = 1 and (isnull(t.IDocNum, '') <> isnull(ca.Num, '')), ', NumAgrees', '')

						--+ iif(isnull(QORT_ARM_SUPPORT.dbo.fDateVarcharToInt2(t.IDocDate), 0) <> isnull(f.IDocDate, 0), ', IDocDate', '')

						+ iif(isnull(t.IDocDate, 0) <> isnull(ca.DateSign, 0), ', IDocDate(agreement)', '')

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

				end StatusTXT

		) s1

		outer apply (

			select case when left(s1.StatusTXT, 2) = ', ' then 'Mismatched: ' + right(StatusTXT, len(StatusTXT) - 2)

						when StatusTXT = '' then 'OK'

						else StatusTXT end StatusTXT

		) s2

		outer apply (select iif(s2.StatusTXT = 'OK', 'green', 'red') ResultColor) s3

		where (t.BOCOde is not null or t.SubAccCode is not null or f.BOCode is not null)

			and (IsClosedFile = 0 or IsClosedQort = 0)

			and not (IsClosedFile = 1 and f.BOCode is null)

			and not (IsClosedQort = 1 and t.BOCode is null)

			and not (t.CustomerCode in ('0', '') and t.SubAccCode in ('0', ''))

			and not (t.SubAccCode in ('AS1897','AS1913','AS1775','AS1865','AS1841','AS1702','AS1762'

										,'AS1711','AS1863','AS1728','AS1766','AS1800','AS1774','AS1899','AS1928') and t.BOCode is null)

		order by 1

	select * from ##resultClients order by BOCode



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

			select '//1\\' + isnull(tt.BOCode,'NULL')

			--iif(tt.Issue_date is NULL, 'NULL', cast(convert(tt.Issue_date,105 ) as varchar))

				+ '//2\\' + tt.SubAccCode

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + isnull(a.ConstitutorCode,t.CustomerCode)

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

		

			from ##resultClients tt

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

