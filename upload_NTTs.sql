			-- exec QORT_ARM_SUPPORT.dbo.upload_NTTs



CREATE PROCEDURE [dbo].[upload_NTTs]



AS



BEGIN



	begin try



		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\NTTS'

		declare @Sheet varchar(16) = 'NTTs'

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

		declare @HistPath varchar(255) = @FilePath + 'history\'



		declare @Message varchar(1024)

		declare @aid int = 0

		declare @WaitCount int

		declare @rowsInFile int

		declare @rowsNew int

		declare @rowsDone int

		declare @rowsError int



		SET NOCOUNT ON







		declare @cmd varchar(255)

		declare @sql varchar(1024)



		set @cmd = 'md "' + @HistPath + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		-----------------Список файлов в папке.

		declare @files table (fileId int identity, filename nvarchar(max));

		set @cmd = 'dir /b "'+@FilePath+'*.xlsx"'

		insert into @files(filename) exec master..xp_cmdshell @cmd



		delete f

		from @files f

		where not filename like '%.xlsx'



		declare @FileId int = 0

		declare @FileName varchar(255)

		declare @NewFileName varchar(255)



		select top 1 @FileId = f.fileId, @FileName = f.filename

		from @files f

		where f.fileId > @FileId



		while @FileName is not null	begin



			print @FileName







			if OBJECT_ID('tempdb..##ntts', 'U') is not null drop table ##ntts

			IF OBJECT_ID('tempdb..#ntts', 'U') IS NOT NULL DROP TABLE #ntts;

	

			SET @sql = 'SELECT * INTO ##ntts

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=YES;IMEX=0'',

				''SELECT * FROM [' + @Sheet + '$A1:BB1000000]'')'



			exec(@sql)



			select *

				, cast(null as int) AssetId

				, cast(null as int) SubAccId, cast(null as int) AccountId

				, cast(null as int) GetSubAccId, cast(null as int) GetAccountId

				, cast(null as varchar(64)) backId

				, cast(null as varchar(128)) AssetShortName

				, cast(null as varchar(128)) collate Cyrillic_General_CS_AS SubAccCode

				, cast(null as varchar(128)) collate Cyrillic_General_CI_AS AccountExportCode

				, cast(null as varchar(128)) collate Cyrillic_General_CS_AS GetSubAccCode

				, cast(null as varchar(128)) collate Cyrillic_General_CI_AS GetAccountExportCode

			into #ntts 

			from ##ntts



			if OBJECT_ID('tempdb..##ntts', 'U') is not null drop table ##ntts



			delete 

			from #ntts

			where CT_Const is null and Date is null





			select @rowsInFile = count(*) from #ntts

			select @rowsDone = 0, @rowsNew = 0, @rowsError = 0



			if @rowsInFile > 0 BEGIN



				update n set n.AssetId = a.Id, n.AssetShortName = a.ShortName

					, n.SubAccId = s.id, n.SubAccCode = s.SubAccCode

					, n.GetSubAccId = gs.id, n.GetSubAccCode = isnull(gs.SubAccCode, iif(n.GetSubAccount <> '', n.GetSubAccount + ' - NOT FOUND', null))

					, n.AccountId = acc.id, n.AccountExportCode = acc.ExportCode

					, n.GetAccountId = gacc.id, n.GetAccountExportCode = isnull(gacc.ExportCode, iif(n.GetAccount <> '', n.GetAccount + ' - NOT FOUND', null))

				from #ntts n

				left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.SubAccCode = n.SubAcc_ID collate Cyrillic_General_CS_AS

				left outer join QORT_BACK_DB.dbo.Subaccs gs with (nolock) on gs.SubAccCode = n.GetSubAccount collate Cyrillic_General_CS_AS

				left outer join QORT_BACK_DB.dbo.Accounts acc with (nolock) on acc.AccountCode = n.Account_ID collate Cyrillic_General_CS_AS or acc.ExportCode = n.Account_ID collate Cyrillic_General_CS_AS

				left outer join QORT_BACK_DB.dbo.Accounts gacc with (nolock) on gacc.AccountCode = n.GetAccount collate Cyrillic_General_CS_AS or gacc.ExportCode = n.GetAccount collate Cyrillic_General_CS_AS

				outer apply (

					select top 1 a.id, a.ShortName

					from QORT_BACK_DB.dbo.Assets a with (nolock) 

					where (a.ShortName = n.Asset_Id or (len(n.Asset_Id) = 12 and a.ISIN = n.Asset_Id)) 

						and a.Enabled = 0 and a.IsTrading = 'y'

					order by 1

				) a



				update n set n.BackId = left(cast(cast(convert(varchar, n.Date, 112) as int) as varchar)

						+ '_' + isnull(cast(n.CT_Const as varchar), 'n')

						+ '_' + isnull(cast(AssetId as varchar), 'n')

						+ '_' + isnull(cast(SubAccId as varchar), 'n')

						+ '_' + isnull(cast(AccountId as varchar), 'n')

						+ '_' + isnull(cast(cast(Size as decimal(32,2)) as varchar), 'n')

						+ '_' + isnull(cast(n.InfoSource as varchar), 'n')

						+ '_' + isnull(n.Comment, 'n')

						+ '_' + isnull(cast(GetSubAccId as varchar), 'n')

						+ '_' + isnull(cast(GetAccountId as varchar), 'n')

						, 64)

					, n.[Internal transfer] = iif(n.[Internal transfer] in ('yes', 'y'), 'y', 'n')

				from #ntts n





				delete cp

				from #ntts n

				inner join QORT_BACK_TDB.dbo.CancelCorrectPositions cp with (nolock) on cp.BackId = n.BackId





				insert into QORT_BACK_TDB.dbo.CancelCorrectPositions(IsProcessed, BackID)

				select distinct 1 IsProcessed, cp.BackId

				from #ntts n

				left outer join QORT_BACK_DB.dbo.CorrectPositions cp with (nolock) on cp.Date = cast(convert(varchar, n.Date, 112) as int) and cp.BackId = n.BackId and cp.IsCanceled = 'n'

				where cp.BackID is NOT null





				set @WaitCount = 1200

				while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.CancelCorrectPositions t with (nolock) where t.IsProcessed in (1,2)))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end





				set @WaitCount = 20

				while (@WaitCount > 0 and exists (

					select top 1 1

					from #ntts n

					inner join QORT_BACK_DB.dbo.CorrectPositions cp with (nolock) on cp.Date = cast(convert(varchar, n.Date, 112) as int) and cp.BackId = n.BackId and cp.IsCanceled = 'n'

				))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end





				set @aid = isnull((select max(aid) from QORT_BACK_TDB.dbo.CorrectPositions with (nolock)), 0)





				/*

				select IsProcessed, ET_Const, CT_Const, BackID, RegistrationDate, EventDate

					, date, PlanDate, InfoSource, Account_ExportCode, Subacc_Code, Asset

					, Size, Comment, Comment2, GetSubacc_Code, GetAccount_ExportCode, IsInternal

				from QORT_BACK_TDB.dbo.CorrectPositions

				*/



				--/*

				insert into QORT_BACK_TDB.dbo.CorrectPositions( IsProcessed, ET_Const, CT_Const, BackID, RegistrationDate, EventDate

					, date, PlanDate, InfoSource, Account_ExportCode, Subacc_Code, Asset

					, Size, Comment, Comment2, GetSubacc_Code, GetAccount_ExportCode, IsInternal) --*/

				--select 1 IsProcessed, 2 ET_Const, n.CT_Const, n.BackID, n.RegistrationDate, n.EventDate

					--, n.date, n.PlanDate, n.InfoSource, n.AccountExportCode, n.SubaccCode, n.AssetShortName

				select 1 IsProcessed, 2 ET_Const, n.CT_Const, n.BackID, cast(convert(varchar, n.RegistrationDate, 112) as int), cast(convert(varchar, n.EventDate, 112) as int)

					, cast(convert(varchar, n.date, 112) as int), cast(convert(varchar, n.PlanDate, 112) as int), n.InfoSource, n.AccountExportCode, n.SubaccCode, n.AssetShortName

					, cast(n.Size as decimal(32,2)), n.Comment, n.Comment2, n.GetSubaccCode, n.GetAccountExportCode, n.[Internal transfer] IsInternal

				from #ntts n

				/*

				left outer join QORT_BACK_DB.dbo.CorrectPositions cp with (nolock) on cp.Date = cast(convert(varchar, n.Date, 112) as int) and cp.BackId = n.BackId and cp.IsCanceled = 'n'

				where cp.BackID is null

				except

				select 100 IsProcessed, cp.ET_Const, cp.CT_Const, cp.BackID, cp.RegistrationDate, cp.EventDate

					, cp.date, cp.PlanDate, cp.InfoSource, cp.Account_ExportCode, cp.Subacc_Code, cp.Asset

					, cast(cp.Size as decimal(32,2)), cp.Comment, cp.Comment2, cp.GetSubacc_Code, cp.GetAccount_ExportCode, cp.IsInternal

				from #ntts n

				inner join QORT_BACK_TDB.dbo.CorrectPositions cp on cp.BackID = n.backId and cp.ImportInsertDate = cast(convert(varchar, getdate(), 112) as int)

				*/



				set @rowsNew = @@ROWCOUNT



				set @WaitCount = 1200

				while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.CorrectPositions t with (nolock) where t.IsProcessed in (1,2)))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end



				insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel)

				select 'TDB NTTs Error: ' + @FileName +', ' + isnull(BackId, '') + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

				from QORT_BACK_TDB.dbo.CorrectPositions a with (nolock)

				where aid > @aid

					and IsProcessed = 4



				set @rowsError = @@ROWCOUNT



				select @rowsDone = count(*)

				from #ntts n

				inner join QORT_BACK_DB.dbo.CorrectPositions cp with (nolock) on cp.Date = cast(convert(varchar, n.Date, 112) as int) and cp.BackId = n.BackId and cp.IsCanceled = 'n' -- on cp.Date = n.Date and cp.BackId = n.BackId and cp.IsCanceled = 'n'

					

				if @rowsNew > 0 begin

					insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel, logRecords)

					select 'File uploaded: ' + @FileName +', new NTTs: ' + cast((@rowsNew - @rowsError) as varchar) + ' / ' + cast((@rowsNew) as varchar) logMessage, iif(@rowsError > 0, 1001, 2001) errorLevel, (@rowsNew - @rowsError) logRecords

				end



				--select @rowsInFile, @rowsNew, @rowsError, @rowsDone



			END



			--if (@rowsInFile > 0) and (@rowsInFile = @rowsDone) begin

			if (@rowsInFile > 0) and (@rowsNew > 0) begin-- and (@rowsInFile = @rowsDone) begin

				-- весь файл обработан, надо переложить в history

				select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

				set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

				exec master.dbo.xp_cmdshell @cmd, no_output

				--select @NewFileName, @cmd

			end



			IF OBJECT_ID('tempdb..#ntts', 'U') IS NOT NULL DROP TABLE #ntts;

			set @FileName = null



			select top 1 @FileId = f.fileId, @FileName = f.filename

			from @files f

			where f.fileId > @FileId

		end



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE() + ISNULL(', ' + @FileName, ''); 

		if @message not like '%12345 Cannot initialize the data source%' insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

