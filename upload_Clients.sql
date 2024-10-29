



-- exec QORT_ARM_SUPPORT_TEST.dbo.upload_Clients

CREATE PROCEDURE [dbo].[upload_Clients]



AS



BEGIN



	begin try



		SET NOCOUNT ON



		declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\clients.xlsx';

		

		declare @Sheet1 varchar(64) = 'Busines Partners' 

		declare @Sheet2 varchar(64) = 'SubAccounts' 

		declare @Sheet3 varchar(64) = 'Agreement' 

		declare @Sheet4 varchar(64) = 'SSI (FirmAccounts)' 



		declare @sql varchar(1024)



		if OBJECT_ID('tempdb..##bp', 'U') is not null drop table ##bp

		if OBJECT_ID('tempdb..##s', 'U') is not null drop table ##s

		if OBJECT_ID('tempdb..##a', 'U') is not null drop table ##a

		if OBJECT_ID('tempdb..##ssi', 'U') is not null drop table ##ssi

	

		SET @sql = 'SELECT * INTO ##bp

		FROM OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$A1:BB1000000]'')'



		exec(@sql)



		SET @sql = 'SELECT * INTO ##s

		FROM OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet2 + '$A1:BB1000000]'')'



		exec(@sql)



		SET @sql = 'SELECT * INTO ##a

		FROM OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet3 + '$A1:BB1000000]'')'



		exec(@sql)





		SET @sql = 'SELECT * INTO ##ssi

		FROM OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet4 + '$A1:BB1000000]'')'



		exec(@sql)





		delete t

		from ##bp t 

		where t.BOCode is null



		delete t

		from ##s t 

		where t.OwnerFirm_ID is null



		delete bp

		from ##bp bp

		where bp.BOCode = 'BO Code'



		delete s

		from ##s s

		where OwnerFirm_ID = 'BO Code'



		delete a

		from ##a a

		where a.BOCode = 'BO Code'



		delete ssi

		from ##ssi ssi

		where AccName = 'Наименование счета' or isnull(AccName, '') = ''



		declare @Message varchar(1024)

		declare @rowsAdded int

		declare @rowsError int

		declare @aid int = 0

		declare @WaitCount int



		set @aid = isnull((select max(aid) from QORT_BACK_TDB_TEST.dbo.Firms with (nolock)), 0)

		--/*

		insert into QORT_BACK_TDB_TEST.dbo.Firms(IsProcessed, ET_Const

			, BOCode, FirmShortName, Name, LatAddrJu, Emails, Phones, INN, IDocNum, IsFirm

			, IDocDate, IDocDateEnd, IsResident, IsQualified, FDocOfficial

			, IDocType_Name, FT_Flags, DateOfBirth, STAT_Const, IsCheckedKYC, AddrPoIndex, LEI, LEIStatDate, BIK, SWIFT, IsOurs, IsBranch

			, IsHeadBrok, IsHeadDepo, OTCForm, OriginalDocStatus, OriginalDocSendStatus, AddToBrokerReport, IsSpam, VT_Const, IsCPartyDVP, DOCSTAT_Const) --*/

		--/*

		select 1 IsProcessed, iif(f.id is null, 2, 4) ET_Const

			, bp.BOCode, bp.Name FirmShortName, bp.Name, bp.LatAddrJu, bp.Email, bp.Phones, bp.INN, bp.IDocNum, bp.IsFirm

			, cast(convert(varchar, bp.IDocDate, 112) as int) IDocDate, cast(convert(varchar, bp.IDocDateEnd, 112) as int) IDocDateEnd, iif(lower(bp.IsResident) = 'n', 'n', 'y') IsResident, bp.IsQualified, bp.FDocOfficial

			, bp.FDocType_ID, bp.FT_Flags, cast(convert(varchar, bp.DateOfBirth, 112) as int) DateOfBirth, bp.STAT_Const, bp.IsCheckedKYC, bp.AddrPoIndex, bp.LEI, bp.LEIStatDate, bp.BIC, bp.SWIFT, bp.IsOurs, bp.IsBranch

			, bp.IsHeadBrok, bp.IsHeadDepo, bp.OTCForm, bp.OriginalDocStatus, bp.OriginalDocSendStatus, bp.AddToBrokerReport, bp.IsSpam, bp.VT_Const, bp.IsCPartyDVP, BP.DocStat

		from ##bp bp

		left outer join QORT_BACK_DB_TEST.dbo.Firms f with (nolock) on f.BOCode = bp.BOCode

		where f.id is null



		set @rowsAdded = @@ROWCOUNT

		set @rowsError = 0



		if @rowsAdded > 0 begin



				set @WaitCount = 1200

				while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.Firms t with (nolock) where t.IsProcessed in (1,2)))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end



				insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

				select 'TDB Firms Error: BOCode = ' + t.BOCode  + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

				from QORT_BACK_TDB_TEST.dbo.Firms t with (nolock)

				where aid > @aid

					and IsProcessed = 4



				set @rowsError = @@ROWCOUNT

		end



		set @Message = 'File Uploaded - "'+@filename+'" - Firms: ' + cast(@rowsAdded - @rowsError as varchar) + ' / ' + cast(@rowsAdded as varchar) ; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) select @message, iif(@rows
Error > 0, 1001, 2001), @rowsAdded - @rowsError; 



		--*/







		--/*

		set @aid = isnull((select max(aid) from QORT_BACK_TDB_TEST.dbo.Firms with (nolock)), 0)



		insert into QORT_BACK_TDB_TEST.dbo.Firms (IsProcessed, ET_Const, Name, EngName, FirmShortName, BOCode, FT_Flags, IsFirm)

		select 1 IsProcessed, 2 ET_Const, Issuer Name, Issuer EngName, Issuer FirmShortName, NewBo BOCode, FT_Flags, 'y' IsFirm

		from (

			select t.Issuer, right('00000' + cast(maxBo + rn as varchar), 5) newBo, 2 FT_Flags

			from (

				select a.Issuer, row_number() over (order by a.Issuer) rn

				from (



					select distinct ssi.BankAccBank_BOCode issuer

					from ##ssi ssi

					left outer join QORT_BACK_DB_TEST.dbo.Firms f with (nolock) on f.FirmShortName = ssi.BankAccBank_BOCode and f.Enabled = 0

					where ssi.BankAccBank_BOCode <> ''

						and f.FirmShortName is null

				) a

				left join QORT_BACK_DB_TEST.dbo.Firms f with (nolock) on f.FirmShortName = a.Issuer and f.Enabled = 0

				where f.id is null

			) t

			outer apply (select max(try_convert(int, BOCode)) maxBo from QORT_BACK_DB_TEST.dbo.Firms f with (nolock)) f

		) t

		--*/



		set @rowsAdded = @@ROWCOUNT

		set @rowsError = 0



		if @rowsAdded > 0 begin



				set @WaitCount = 1200

				while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.Firms t with (nolock) where t.IsProcessed in (1,2)))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end



				insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

				select 'TDB Firms Error: BOCode = ' + t.BOCode  + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

				from QORT_BACK_TDB_TEST.dbo.Firms t with (nolock)

				where aid > @aid

					and IsProcessed = 4



				set @rowsError = @@ROWCOUNT

		end



		set @Message = 'File Uploaded - "'+@filename+'" - Banks: ' + cast(@rowsAdded - @rowsError as varchar) + ' / ' + cast(@rowsAdded as varchar) ; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) select @message, iif(@rows
Error > 0, 1001, 2001), @rowsAdded - @rowsError; 





		set @aid = isnull((select max(aid) from QORT_BACK_TDB_TEST.dbo.FirmAccounts with (nolock)), 0)



		--/*

		insert into QORT_BACK_TDB_TEST.dbo.FirmAccounts (IsProcessed, ET_Const, AccName, FirmShortName, FirmBOCode

			, BankAccNum, GetFirm, Type_Flags, Comment, BankAccBank_BOCode

			, SettlementAsset_ShortName

		) --*/

		--/*

		select 1 IsProcessed, iif(facc.AccName is null, 2, 4) ET_Const, ssi.AccName, fo.FirmShortName FirmShortName, ssi.FirmBOCode FirmBOCode

			, ssi.BankAccNum BankAccNum, fg.Name GetFirm, ssi.Type_Flags, ssi.Comment, fb.BOCode BankAccBank_BOCode

			, ssi.SettlementAsset_ShortName SettlementAsset_ShortName

		-- IBAN	БИК	SWIFT-код

		--	, ssi.*, fo.BOCode, fg.BOCode, fb.BOCode

		from ##ssi ssi

		left outer join QORT_BACK_DB_TEST.dbo.Firms fo with (nolock) on fo.BOCode = ssi.FirmBOCode and fo.Enabled = 0

		left outer join QORT_BACK_DB_TEST.dbo.Firms fg with (nolock) on fg.BOCode = ssi.FirmBOCode and fg.Enabled = 0

		left outer join QORT_BACK_DB_TEST.dbo.Firms fb with (nolock) on fb.FirmShortName = ssi.BankAccBank_BOCode and fb.Enabled = 0

		left outer join QORT_BACK_DB_TEST.dbo.FirmAccounts facc with (nolock) on facc.Firm_ID = fo.id and facc.AccName = ssi.AccName

		where fg.BOCode is not null

			and facc.AccName is null



		set @rowsAdded = @@ROWCOUNT

		set @rowsError = 0



		if @rowsAdded > 0 begin



				set @WaitCount = 1200

				while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.FirmAccounts t with (nolock) where t.IsProcessed in (1,2)))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end



				insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

				select 'TDB Firms Error: BOCode = ' + t.FirmBOCode  + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

				from QORT_BACK_TDB_TEST.dbo.FirmAccounts t with (nolock)

				where aid > @aid

					and IsProcessed = 4



				set @rowsError = @@ROWCOUNT

		end



		set @Message = 'File Uploaded - "'+@filename+'" - SSI: ' + cast(@rowsAdded - @rowsError as varchar) + ' / ' + cast(@rowsAdded as varchar) ; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) select @message, iif(@rowsE
rror > 0, 1001, 2001), @rowsAdded - @rowsError; 





		--*/

		set @aid = isnull((select max(aid) from QORT_BACK_TDB_TEST.dbo.Subaccs with (nolock)), 0)



		insert into QORT_BACK_TDB_TEST.dbo.Subaccs(IsProcessed, ET_Const, ConstitutorCode, Code, OwnerFirm_BOCode, StatusChangeDate, SubaccName, BrokerFirm_BOCode, ACSTAT_Const/*, Comment*/, IsAnalytic, AccountType_Name, FirmCode) --*/

		select 1 IsProcessed, 2 ET_Const, s.ConstitutorCode, s.SubAccCode, s.OwnerFirm_ID, cast(convert(varchar, s.StatusChangeDate, 112) as int) StatusChangeDate, s.SubaccName, s.BrokerFirm_ID, s.ACSTAT_Const/*, s.[Depo account number] DepoAccountNumber*/, 'n'
 IsAnalytic, s.AccountType_Name, s.FirmCode

		--select 1 IsProcessed, 2 ET_Const, s.ConstitutorCode, s.SubAccCode, s.OwnerFirm_ID, cast(convert(varchar, s.StatusChangeDate, 112) as int) StatusChangeDate, s.SubaccName, s.BrokerFirm_ID, s.ACSTAT_Const, s.[Depo account number] DepoAccountNumber, 'n' I
sAnalytic, s.AccountType_Name

		from ##s s

		left outer join QORT_BACK_DB_TEST.dbo.Firms f with (nolock) on f.BOCode = s.OwnerFirm_ID

		left outer join QORT_BACK_DB_TEST.dbo.Subaccs ss with (nolock) on ss.SubAccCode = s.SubAccCode collate Cyrillic_General_CS_AS

		where f.BOCode is not null

			and ss.SubAccCode is null



		set @rowsAdded = @@ROWCOUNT

		set @rowsError = 0



		if @rowsAdded > 0 begin



				set @WaitCount = 1200

				while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.Subaccs t with (nolock) where t.IsProcessed in (1,2)))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end



				insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

				select 'TDB SubAccs Error: BOCode, SubAccCode = ' + t.OwnerFirm_BOCode  + ', ' + t.Code collate Cyrillic_General_CI_AS + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

				from QORT_BACK_TDB_TEST.dbo.Subaccs t with (nolock)

				where aid > @aid

					and IsProcessed = 4



				set @rowsError = @@ROWCOUNT

		end



		set @Message = 'File Uploaded - "'+@filename+'" - SubAccs: ' + cast(@rowsAdded - @rowsError as varchar) + ' / ' + cast(@rowsAdded as varchar) ; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) select @message, iif(@ro
wsError > 0, 1001, 2001), @rowsAdded - @rowsError; 







		set @aid = isnull((select max(aid) from QORT_BACK_TDB_TEST.dbo.ClientAgrees with (nolock)), 0)



		insert into QORT_BACK_TDB_TEST.dbo.ClientAgrees(IsProcessed, ET_Const, ClientAgreeTypeShortName, OwnerFirm_BOCode, SubAccCode, Num, DateCreate, DateSign, DateEnd)

		select  1 IsProcessed, iif(ca.id is null, 2, 4) ET_Const, cat.ShortName ClientAgreeTypeShortName

			, a.BOCode OwnerFirm_BOCode, a.SubAccCode SubAccCode, a.Num, cast(convert(varchar, a.DateSign, 112) as int) DateCreate, cast(convert(varchar, a.DateSign, 112) as int) DateSign

			, cast(convert(varchar, cast(a.DateEnd as date), 112) as int) DateEnd

		from ##a a

		left outer join QORT_BACK_DB_TEST.dbo.Firms f with (nolock) on f.BOCode = a.BOCode

		left outer join QORT_BACK_DB_TEST.dbo.Subaccs ss with (nolock) on ss.SubAccCode = a.SubAccCode collate Cyrillic_General_CS_AS

		left outer join QORT_BACK_DB_TEST.dbo.ClientAgreeTypes cat with (nolock) on cat. ShortName = 'AFPBS'

		left outer join QORT_BACK_DB_TEST.dbo.ClientAgrees ca with (nolock) on ca.OwnerFirm_ID = f.id and ca.SubAcc_ID = ss.id and ca.ClientAgreeType_ID = cat.id

		where a.BOCode <> ''

			and f.BOCode <> '' and ss.SubAccCode <> ''

			and ca.id is null



		set @rowsAdded = @@ROWCOUNT

		set @rowsError = 0



		if @rowsAdded > 0 begin



				set @WaitCount = 1200

				while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.ClientAgrees t with (nolock) where t.IsProcessed in (1,2)))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end



				insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

				select 'TDB SubAccs Error: BOCode, SubAccCode = ' + t.OwnerFirm_BOCode  + ', ' + isnull(t.SubAccCode, 'NULL') collate Cyrillic_General_CI_AS + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

				from QORT_BACK_TDB_TEST.dbo.ClientAgrees t with (nolock)

				where aid > @aid

					and IsProcessed = 4



				set @rowsError = @@ROWCOUNT

		end



		set @Message = 'File Uploaded - "'+@filename+'" - ClientAgrees: ' + cast(@rowsAdded - @rowsError as varchar) + ' / ' + cast(@rowsAdded as varchar) ; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) select @message, i
if(@rowsError > 0, 1001, 2001), @rowsAdded - @rowsError; 



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

