

CREATE PROCEDURE [dbo].[SelectFromCSV_otl_AutoRowDelim_PG]

	@fileName varchar(255)

	, @delim varchar(10) = '","'  

	, @tabName varchar(64) = '##tBULK'

	, @ColReplaceSymbols bit = 1

	, @FirstDataRow int = 2

	, @SkipLinesTillTitle varchar(255) = null -- пропускать строки, пока не будет с содержанием данной подстроки

	, @IncludeFileName bit = 0

	, @RemoveDoubleQuotes bit = 0 -- удалить двойные кавычки во всех полях

	, @IncFirstDataRowWhileSkipping bit = 1

	, @headersFileName varchar(255) = null -- если заголовки лежат в отдельном файле

AS  

BEGIN  

	SET NOCOUNT ON;  

 

	declare @sql varchar(max)  

	declare @columns varchar(max)  

	Declare @RowDelim Varchar(10)



	declare @TempTabName varchar(64)

	if @IncludeFileName = 1 begin

		set @TempTabName = '##' + replace(newid(), '-', '')

		declare @ShortFileName varchar(255)

		set @ShortFileName = @fileName

		while charindex('\', @ShortFileName) > 0 set @ShortFileName = right(@ShortFileName, len(@ShortFileName) - charindex('\', @ShortFileName))

	end else begin

		set @TempTabName = @TabName

	end

 

	if @headersFileName is NOT null set @sql = 'select BulkColumn from (SELECT top 1 * FROM OPENROWSET(BULK '''+@headersFileName+''', SINGLE_CLOB) AS x) t'  

	else set @sql = 'select BulkColumn from (SELECT top 1 * FROM OPENROWSET(BULK '''+@FileName+''', SINGLE_CLOB) AS x) t'  



	declare @t table(cols varchar(max))  



	insert into @t  

	exec(@sql)  

 

	declare @RowDelimStarts int = 0

	if @RowDelimStarts = 0 begin set @RowDelim = Char(13)+Char(13)+Char(10); select top 1 @RowDelimStarts = CHARINDEX(@RowDelim, cols) from @t; end

	if @RowDelimStarts = 0 begin set @RowDelim =          Char(13)+Char(10); select top 1 @RowDelimStarts = CHARINDEX(@RowDelim, cols) from @t; end

	if @RowDelimStarts = 0 begin set @RowDelim =                   Char(10); select top 1 @RowDelimStarts = CHARINDEX(@RowDelim, cols) from @t; end



	-- если в начале файла идут "левые строки", то пропустим их, пока не встретится строка, содержащая в себе @SkipLinesTillTitle

	if @SkipLinesTillTitle is not null begin

		declare @p0 int

		select @p0 = CHARINDEX(@SkipLinesTillTitle, cols),  @RowDelimStarts = CHARINDEX(@RowDelim, cols) from @t;

		while @p0 > 0 and @RowDelimStarts < @p0 begin

			if @IncFirstDataRowWhileSkipping = 1 set @FirstDataRow = @FirstDataRow + 1

			update t set t.cols = right(t.cols, len(t.cols) - @RowDelimStarts - (len(@RowDelim)-1)) from @t t

			select @p0 = CHARINDEX(@SkipLinesTillTitle, cols),  @RowDelimStarts = CHARINDEX(@RowDelim, cols) from @t;

		end

	end



	if @RowDelimStarts > 0 update t set t.cols = replace(left(t.cols, @RowDelimStarts-1), '''', '') from @t t



	set @delim = @delim

	while @@ROWCOUNT > 0 and @headersFileName is not null update t set cols = left(cols, len(cols) - len(@delim)) from @t t where right(cols, len(@delim)) = @delim



	Select @sql = 'Select '''+Replace(cols, @Delim, ''' Union All Select ''')+'''' From @t



	declare @ColNames table(cols varchar(max), id Int Not null Identity(1, 1))  



	Insert @ColNames

	Exec (@SQL)



	If @ColReplaceSymbols = 1 Update @ColNames Set Cols = Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Cols, '"', ''), ' ', ''), '/', ''), '\', ''), '(', ''), ')', ''), '.', '_'), '''', '')



	update c1 set c1.cols = 'Col' + cast(c1.id as varchar)

	from @ColNames c1

	where c1.cols = '' or (@FirstDataRow = 1 and @headersFileName is null)



	update c1 set c1.Cols = c1.Cols + '_'

	from @ColNames c1

	inner join @ColNames c0 on c0.Cols = c1.Cols and c0.id < c1.id

 

	while @@ROWCOUNT > 0 begin

	update c1 set c1.Cols = c1.Cols + '_'

	from @ColNames c1

	inner join @ColNames c0 on c0.Cols = c1.Cols and c0.id < c1.id

	end



	Select @Sql = ''

	Select @Sql = @Sql+'['+Cols+'] varchar(1024)'+', ' From @ColNames

 

	Select @Sql = Left(@Sql, Len(@sql) - 1)

 



	--Select @Sql ='create table '+@tabName+' (' + @sql + ');'  

	-- будем создавать таблицу только в том случае, если ее еще нет

	Select @Sql = 'if OBJECT_ID(''tempdb..'+@TempTabName+''',''U'') is null' + ' create table '+@TempTabName+' (' + @sql + ');'  

	Exec (@sql)



	--print @sql



	set @sql = '  

	BULK INSERT '+@TempTabName+'  

	FROM ''' + @fileName +'''  

	WITH  

	(  

	CODEPAGE = ''1252'',  

	FIELDTERMINATOR = '''+@delim+''',

	ROWTERMINATOR = '''+@RowDelim+''',  

	CHECK_CONSTRAINTS,  

	firstrow=' + cast(@FirstDataRow as varchar) +'

	);  

	--select * from #tBULK;  

	--drop table #tBULK';  

	-- Select @SQL

	--   firstrow=2

	exec(@sql)  



	if @RemoveDoubleQuotes = 1 begin

		Select @Sql = ''

		Select @Sql = @Sql+'['+Cols+'] = replace(['+Cols+'], ''"'', '''')'+', ' From @ColNames

		Select @Sql = Left(@Sql, Len(@sql) - 1)

		Select @Sql = ' update '+@TempTabName+' set ' + @sql + ';'  

		--print @SQL

		Exec (@sql)

	end



	if @IncludeFileName = 1 begin

		Select @Sql = ' alter table '+@TempTabName+'  add ShortFileName255 varchar(255) not null default '''+@ShortFileName+''';'  

		Exec (@sql)

		Select @Sql = 'if OBJECT_ID(''tempdb..'+@TabName+''',''U'') is null' + ' select * into '+@TabName+' from '+@TempTabName+'  else insert into '+@TabName+' select * from '+@TempTabName+ '; drop table ' + @TempTabName + ';'

		--print @sql

		Exec (@sql)

	end

End 
