







 -- exec QORT_ARM_SUPPORT_TEST.dbo.upload_ClientsUnicode



CREATE PROCEDURE [dbo].[upload_ClientsUnicode]

AS

BEGIN



	SET NOCOUNT ON



	begin try



		declare @Message varchar(1024)

		declare @rows int

		declare @aid int = 0

		declare @WaitCount int

		declare @rowsInFile int

		declare @rowsNew int



		set @aid = isnull((select max(aid) from QORT_BACK_TDB_TEST.dbo.Firms with (nolock)), 0)



		declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Clients\Clients_Import UniCode_TEST.xlsx';

		declare @Sheet1 varchar(64) = 'Sheet1' 

		declare @sql varchar(1024)



		if OBJECT_ID('tempdb..##fUnicode', 'U') is not null drop table ##fUnicode

		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t

	

		SET @sql = 'SELECT * INTO ##fUnicode

		FROM OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$A1:ZZ1000000]'')'



		exec(@sql)



		select nullif([BO Code], '') BOCode

			, nullif([Full Name], '') NameU

			, nullif([Address], '') AddrFSettlementU

			, nullif([NEW], '') OrgCathegoriyID

		into #t

		from ##fUnicode





		insert into QORT_BACK_TDB_TEST.dbo.Firms (ET_Const, IsProcessed, BOCode, NameU, AddrFSettlementU, OrgCathegoriy_NAME)

		select 4 ET_Const, 1 IsProcessed, f.BOCode, t.NameU, t.AddrFSettlementU, t.OrgCathegoriyID

		from #t t

		inner join QORT_BACK_DB_TEST.dbo.Firms f with (nolock) on f.BOCode = t.BOCode

		inner join QORT_BACK_DB_TEST.dbo.FirmProperties fp with (nolock) on fp.Firm_ID = f.id

		--where (t.NameU <> '' and t.NameU <> fp.NameU) or (t.AddrFSettlementU <> '' and t.AddrFSettlementU <> fp.AddrFSettlementU)

		where (t.NameU <> '' and t.NameU <> isnull(fp.NameU, '')) or (t.AddrFSettlementU <> '' and t.AddrFSettlementU <> isnull(fp.AddrFSettlementU, ''))



		set @rows = @@ROWCOUNT; if @rows > 0 begin set @Message = 'File Uploaded - "'+@filename+'": ' + cast(@rows as varchar) + ' updated clients'; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) values (@message, 2001, @ro
ws); end;



		set @WaitCount = 1200

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.Firms t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

		

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

		select 'TDB Clients Error: Bocode ' + BOCode +' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

		from QORT_BACK_TDB_TEST.dbo.Firms a with (nolock)

		where aid > @aid

			and IsProcessed = 4



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		if @message not like '%Cannot initialize the data source%' insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

