



--exec QORT_ARM_SUPPORT_TEST.dbo.upload_CrossRates_CBA



/*

	--insert into QORT_BACK_TDB_TEST.dbo.CrossRates(IsProcessed, Date, TradeAsset_ShortName, Bid, Ask, PriceAsset_ShortName, InfoSource, Qty)

	select 1 IsProcessed, c.Date, aTr.ShortName TradeAsset, c.Bid, c.Ask, aPr.ShortName PriceAsset, c.InfoSource, c.Qty

	--select c.*, aTr.ShortName, aPr.ShortName

	from QORT_BACK_DB.dbo.CrossRatesHist c with (nolock)

	left outer join QORT_BACK_DB.dbo.Assets aTr with (nolock) on aTr.id = c.TradeAsset_ID

	left outer join QORT_BACK_DB.dbo.Assets aPr with (nolock) on aPr.id = c.PriceAsset_ID

	left outer join QORT_BACK_DB.dbo.CrossRatesHist c2 with (nolock) on c2.OldDate = c.date and c2.InfoSource = c.InfoSource and c2.TradeAsset_ID = c.TradeAsset_ID and c2.PriceAsset_ID = c.PriceAsset_ID

	where c.InfoSource = 'CBA' and c.OldDate < 20230412

		and c2.OldDate is null

	order by c.olddate





	declare @sql varchar(max)

	set @sql = cast((

		select ' union all select '''+s.name+''' TableName, IsProcessed, count(*) tc from QORT_BACK_TDB_TEST.dbo.' + s.name + ' with (nolock) where IsProcessed in (1,2) group by isProcessed'

		from QORT_BACK_TDB_TEST.sys.columns c with (nolock)

		inner join QORT_BACK_TDB_TEST.sys.objects s with (nolock) on s.object_id = c.object_id

		where c.name = 'IsProcessed'

		order by 1

		for xml path(''))

	as varchar(max))

	set @sql = right(@sql, len(@sql) - 10) + ' order by 1,2'

	exec(@sql)

*/



CREATE PROCEDURE [dbo].[upload_CrossRates_CBA_TEST]

AS

BEGIN



	SET NOCOUNT ON



	begin try



		declare @Message varchar(1024)

		declare @rows int

		declare @aid int = 0

		declare @WaitCount int



		declare @LocationType varchar(32) = 'CrossRates_CBA'

		declare @Dir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\CrossRates_CBA'

		if right(@dir, 1) <> '\' set @dir = @dir + '\'



		declare @BaseCurrencyAsset varchar(3) = 'AMD'

		declare @InfoSource varchar(16) = 'CBA'

		declare @cr table(linenum int, rownum int, val varchar(16))



		declare @fullfilename varchar(255)

		declare @sql varchar(max)  

		declare @columns varchar(max)  

		declare @t table(cols varchar(max))  

		Declare @RowDelim Varchar(10)

		declare @RowDelimStarts int = 0





		declare @locationId int = null

		declare @locationPath varchar(255) = null



		select top 1 @locationId = l.locationId, @locationPath = l.locationPath

		from QORT_ARM_SUPPORT_TEST.dbo.uploadFileLocations l with (nolock)

		where l.locatoinType = @LocationType



		if @locationId is null begin

			insert into QORT_ARM_SUPPORT_TEST.dbo.uploadFileLocations(locationPath, locatoinType)

			select @Dir, @LocationType



			select top 1 @locationId = l.locationId, @locationPath = l.locationPath

			from QORT_ARM_SUPPORT_TEST.dbo.uploadFileLocations l with (nolock)

			where l.locatoinType = @LocationType

		end



		select @Dir = @locationPath

		if right(@dir, 1) <> '\' set @dir = @dir + '\'





		declare @FileDate int

		declare @filename varchar(255) = null

		declare @fileId int = 0

		declare @rc int





		declare @dirCom varchar(300) = 'dir /b "' + @Dir + '*.csv"';

		declare @files table(fId int identity primary key, fname varchar(255))



		-- получаем список файлов

		insert into @files (fName)

		exec master..xp_cmdshell @DirCom



		delete f

		from @files f

		where f.fname is null or not f.fname like 'CrossRates_CBA%.csv'



		delete f

		from @files f

		inner join QORT_ARM_SUPPORT_TEST.dbo.uploadFileNames uf with (nolock) on uf.locationId = @locationId and uf.fileName = f.fname





		while 2 > 1 begin



			select @filename = null



			select top 1 @fileId = f.fid, @filename = fname, @fullfilename = @Dir + fname

			from @files f

			where f.fid > @fileId

			order by 1



			if @filename is null break



			print @filename



			set @sql = 'select BulkColumn from (SELECT top 1 * FROM OPENROWSET(BULK '''+@fullfilename+''', SINGLE_CLOB) AS x) t'  



			delete t

			from @t t



			insert into @t  

			exec(@sql)  



	

			select @RowDelimStarts = 0

			if @RowDelimStarts = 0 begin set @RowDelim = Char(13)+Char(13)+Char(10); select top 1 @RowDelimStarts = CHARINDEX(@RowDelim, cols) from @t; end

			if @RowDelimStarts = 0 begin set @RowDelim =          Char(13)+Char(10); select top 1 @RowDelimStarts = CHARINDEX(@RowDelim, cols) from @t; end

			if @RowDelimStarts = 0 begin set @RowDelim =                   Char(10); select top 1 @RowDelimStarts = CHARINDEX(@RowDelim, cols) from @t; end



			delete cr

			from @cr cr

	

			insert into @cr(linenum, rownum, val)

			select t.num linenum, t2.num rownum, t2.val val

			from (

				select * 

				from QORT_ARM_SUPPORT_TEST.dbo.fnt_ParseString_Num((select top 1 cols from @t), @RowDelim)

				where len(val) > 10

			) t

			outer apply (

				select * from QORT_ARM_SUPPORT_TEST.dbo.fnt_ParseString_Num(t.val, ',')

			) t2

			order by 2,1



			update cr set cr.val = 'date'

			from @cr cr

			where cr.linenum = 1 and cr.rownum = 1

	

			update cr set cr.val = SUBSTRING(d,7,4)+SUBSTRING(d,4,2)+SUBSTRING(d,1,2)

			from @cr cr

			outer apply(select right(val, 10) d) t

			where linenum > 1 and rownum = 1



			set @aid = isnull((select max(aid) from QORT_BACK_TDB_TEST.dbo.CrossRates with (nolock)), 0)



			insert into QORT_BACK_TDB_TEST.dbo.CrossRates(IsProcessed, Date, TradeAsset_ShortName, Bid, Ask, PriceAsset_ShortName, InfoSource, Qty)

			select 1 IsProcessed, d.val Date, n.val TradeAsset, t1.val Bid, t1.Val Ask, @BaseCurrencyAsset PriceAsset, @InfoSource InfoSource, 1 Qty

			from @cr v

			inner join @cr n on n.linenum = 1 and n.rownum = v.rownum

			inner join @cr d on d.linenum = v.linenum and d.rownum = 1

			outer apply (select cast(v.val as decimal(16,4)) Val) t1

			where v.linenum > 1 and v.rownum > 1 and len(v.val) > 1

			order by 2,1

	

			set @rows = @@ROWCOUNT; if @rows > 0 begin set @Message = 'File Uploaded - "'+@filename+'": ' + cast(@rows as varchar) + ' rates'; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) values (@message, 2001, @rows); end;




			set @WaitCount = 1200

			while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.CrossRates t with (nolock) where t.IsProcessed in (1,2)))

			begin

				waitfor delay '00:00:03'

				set @WaitCount = @WaitCount - 1

			end



			insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

			select distinct 'CrossRate TDB ERROR:' + t.ErrorLog, 1001

			from QORT_BACK_TDB_TEST.dbo.CrossRates t with (nolock)

			where t.aid > @aid and t.IsProcessed = 4



			insert into QORT_ARM_SUPPORT_TEST.dbo.uploadFileNames(locationId, fileName)

			select @locationId, @filename



		end



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

