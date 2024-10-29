

-- exec QORT_ARM_SUPPORT.dbo.upload_Commissions



CREATE PROCEDURE [dbo].[upload_Commissions]



AS



BEGIN



	begin try



		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Commissions'

		declare @Sheet varchar(16) = 'Commissions'

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

		declare @HistPath varchar(255) = @FilePath + 'history\'

		declare @InfoSource varchar(64) = object_name(@@procid)



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







			if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL DROP TABLE #comms;

	

			SET @sql = 'SELECT * INTO ##comms

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

				, row_number() over(order by isnull(TradeId, 0)*0) rn

				, cast(null as bigint) trueTradeId

				, cast(null as varchar(1)) IsDraft

			into #comms 

			from ##comms



			if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms



			delete 

			from #comms

			where isnull(TradeId, 0) <= 0 and isnull(Amount, 0) <= 0







			select @rowsInFile = count(*) from #comms

			select @rowsDone = 0, @rowsNew = 0, @rowsError = 0



			if @rowsInFile > 0 BEGIN



				update t set t.AssetId = a.Id, t.AssetShortName = isnull(a.ShortName, isnull(t.Currency, 'NULL') + ' - asset not found')

					, t.SubAccId = s.id, t.SubAccCode = s.SubAccCode

					, t.GetSubAccId = gs.id, t.GetSubAccCode = isnull(gs.SubAccCode, isnull(t.SubAccForCrediting, 'NULL') + ' - NOT FOUND')

					, t.AccountId = acc.id, t.AccountExportCode = acc.ExportCode

					, t.GetAccountId = acc.id, t.GetAccountExportCode = acc.ExportCode

					, t.trueTradeId = tt.id

					, t.IsDraft = tt.IsDraft

				from #comms t

				left outer join QORT_BACK_DB.dbo.Trades tt with (nolock) on tt.id = t.TradeId-- * 1000

				left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = tt.SubAcc_ID

				left outer join QORT_BACK_DB.dbo.Subaccs gs with (nolock) on gs.SubAccCode = t.SubAccForCrediting collate Cyrillic_General_CS_AS

				left outer join QORT_BACK_DB.dbo.Accounts acc with (nolock) on acc.id = tt.PayAccount_ID

				outer apply (

					select top 1 a.id, a.ShortName

					from QORT_BACK_DB.dbo.Assets a with (nolock) 

					where a.ShortName = t.Currency and a.AssetType_Const = 3

						and a.Enabled = 0 and a.IsTrading = 'y'

					order by 1

				) a





				update t set t.BackId = left(

						'Commission_on_Trade ' + isnull(cast(t.TradeId as varchar), 'NULL')

						+ ', line ' + cast(rn as varchar) 

						+ '_from_' + cast(cast(convert(varchar, getdate(), 112) as int) as varchar)

						+ '_' + convert(varchar, getdate(), 114)

						, 64)

				from #comms t





--select * from #comms t



				set @aid = isnull((select max(aid) from QORT_BACK_TDB.dbo.Phases with (nolock)), 0)



				/*

				delete p

				from #comms t

				left outer join QORT_BACK_TDB.dbo.Phases p with (nolock) on p.Trade_SID = t.TradeId and p.PC_Const = 9 --*/



				--/*

				insert into QORT_BACK_TDB.dbo.Phases( IsProcessed, ET_Const, PC_Const, BackID, Date

					, InfoSource, PhaseAccount_ExportCode, Subacc_Code, PhaseAsset_ShortName, CurrencyAsset_ShortName

					, QtyBefore, QtyAfter, GetSubacc_Code, GetAccount_ExportCode, Trade_SID, SystemID

					, Comment) --*/

				select distinct 1 IsProcessed, 2 ET_Const, 9 PC_Const, t.BackID, cast(convert(varchar, t.Date, 112) as int) PhaseDate

					, left(@InfoSource, 64) InfoSource, t.AccountExportCode, isnull(t.SubaccCode, '') + iif(t.IsDraft = 'y', ' - DRAFT TRADE', '') SubaccCode, t.AssetShortName, t.AssetShortName CurrencyShortName

					, cast(t.Amount as decimal(32,2)) QtyBefore, -1 QtyAfter, t.GetSubaccCode, t.GetAccountExportCode, t.TradeId, -1 SystemID

					, left(@FileName, 64) Comment

				from #comms t

				left outer join QORT_BACK_DB.dbo.Phases p with (nolock) on p.Trade_ID = t.TradeId and p.PC_Const = 9 and p.IsCanceled = 'n' and p.Enabled = 0

				where p.id is null or t.trueTradeId is null



				set @rowsNew = @@ROWCOUNT



				set @WaitCount = 1200

				while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.Phases t with (nolock) where t.IsProcessed in (1,2)))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end



				insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel)

				select 'TDB Commission Error: ' + @FileName +', ' + isnull(BackId, '') + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

				from QORT_BACK_TDB.dbo.Phases a with (nolock)

				where aid > @aid

					and IsProcessed = 4

					and InfoSource = @InfoSource



				set @rowsError = @@ROWCOUNT



				select @rowsDone = count(*)

				from #comms t

				inner join QORT_BACK_DB.dbo.Phases p with (nolock) on p.Trade_ID = t.TradeId and p.BackId = t.BackId and p.IsCanceled = 'n'

					

				if @rowsInFile > 0 begin

					insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel, logRecords)

					select 'File uploaded: ' + @FileName + ', lines: ' + cast(@rowsInFile as varchar) +', new Commissions: ' + cast((@rowsNew - @rowsError) as varchar) + ' / ' + cast((@rowsNew) as varchar) logMessage, iif(@rowsError > 0, 1001, 2001) errorLevel, (@rowsN
ew - @rowsError) logRecords

				end



				--select @rowsInFile, @rowsNew, @rowsError, @rowsDone



			END



			if (@rowsInFile > 0) begin-- and (@rowsInFile = @rowsDone) begin

				-- весь файл обработан, надо переложить в history

				select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

				set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

				exec master.dbo.xp_cmdshell @cmd, no_output

				--select @NewFileName, @cmd

			end



			IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL DROP TABLE #comms;

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

