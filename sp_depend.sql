

create PROCEDURE [dbo].[sp_depend]

@searchString varchar(128)

, @searchDB varchar(32) = null

AS

BEGIN

SET NOCOUNT ON;



if (len(@searchString) < 2)or(@searchString is null) return

if @searchDB is null set @searchDB = 'QORT_ARM_SUPPORT_TEST'



if charindex('%', @searchString) = 0 set @searchString = '%' + @searchString + '%'

declare @strAdd int = 255



declare @res table (uniqId int identity primary key, objectId int, colid int, comment varchar(8000), startPos int, comLen int)



if @searchDB = 'QORT_ARM_SUPPORT_TEST' begin

insert into @res (objectId, colid, comment)

select sc1.Id, sc1.colid, cast(sc1.text as varchar(max)) + isnull(sc2.text, '')

from QORT_ARM_SUPPORT_TEST.sys.syscomments sc1

left outer join QORT_ARM_SUPPORT_TEST.sys.syscomments sc2 on sc2.id = sc1.id and sc2.colid = sc1.colid + 1

where (sc1.text + isnull(sc2.text, '')) like @searchString

end else begin

select 'Can''t search in DataBase ' + @searchDB ERROR

return

end



update r set startPos = patindex(@searchString, comment), comLen = len(comment)

from @res r



delete r2

from @res r1

inner join @res r2 on r2.objectId = r1.objectId and r2.colid > r1.colid



update r set r.comment = substring(r.comment, t1, t2-t1)

, startPos = startPos - t1+1

, comLen = t2-t1

from (

select r.uniqId

, case when startPos > @strAdd then startPos - @strAdd else 1 end t1

, case when startPos + @strAdd > comLen then comLen else startPos + @strAdd end t2

from @res r

) t

inner join @res r on r.uniqId = t.uniqId



while @@ROWCOUNT > 0 begin

update r set r.comment = substring(r.comment, newLine, comLen-newLine)

, startPos = startPos - newLine+1

, comLen = comLen-newLine

from (

select uniqId, charindex(char(10), comment) + 1 newLine

from @res r

where charindex(char(10), comment) < startPos

) t

inner join @res r on r.uniqId = t.uniqId

where comLen>newLine

end





update r set r.comment = substring(r.comment, 1, newLine)

, comLen = newLine

from (

select uniqId, charindex(char(13), comment, startPos)-1 newLine

from @res r

where charindex(char(13), comment) > startPos

) t

inner join @res r on r.uniqId = t.uniqId





update r set r.comment =ltrim(rtrim(replace(r.comment, char(9), ''))) from @res r







if @searchDB = 'QORT_ARM_SUPPORT_TEST' begin

select o.name, r.comment, o.type--, o.object_id

from @res r

inner join QORT_ARM_SUPPORT_TEST.sys.objects o on o.object_id = r.objectId

union

select o.name, '', o.type--, o.object_id

from QORT_ARM_SUPPORT_TEST.sys.objects o

left join @res r on o.object_id = r.objectId

where o.name like @searchString and r.objectId is null and type not in ('D', 'PK', 'TR')

order by 1,3

end else begin

select 'Can''t search in DataBase ' + @searchDB ERROR

return

end





END



