

-- exec QORT_ARM_SUPPORT.dbo.SalesUpdate



CREATE PROCEDURE [dbo].[SalesUpdate]

AS

BEGIN



    begin try

        declare @Message varchar(1024)

        if OBJECT_ID('tempDB_UAT..#t', 'U') is not null

            drop table #t

        if OBJECT_ID('tempDB_UAT..#t1', 'U') is not null

            drop table #t1

        if OBJECT_ID('tempDB_UAT..#t3', 'U') is not null

            drop table #t3

        if OBJECT_ID('tempDB_UAT..#t4', 'U') is not null

            drop table #t4





        ----------------------------------------------- таблица с правами на субсчета текущее состояние------------------------------------------------------------------

        select ss.user_id    fatherID

             , ss.account_id ChildID

             , up.UserCode   ownerfirmid

             , s1.SubAccCode SubAccCodeAN

             , ss.id         idR

        into #t

        from QORT_BACK_DB..UserSubaccs                   ss (nolock)

            left outer join QORT_BACK_DB..UserProperties up (nolock)

                on up.user_id = ss.user_id

            left outer join QORT_BACK_DB..Subaccs        s1 (nolock)

                on ss.account_id = s1.id

        where ss.account_id > 0

              and ss.is_analytic = 'n'

              and up.UserCode <> ''

        select *

        from #t



        -----------------------------------------------------таблица с субсчетами и сейлзами текущее состояние-----------------------------------------------------------

        select sa.SubAccCode SubAccCodeSales

             , sa.id         IDsubacc

             , frS.name

             , frS.id        IDSales

        into #t1

        from QORT_BACK_DB..Subaccs              sa

            left outer join QORT_BACK_DB..Firms fr

                on sa.OwnerFirm_ID = fr.id

            left outer join QORT_BACK_DB..Firms frS

                on fr.Sales_ID = frS.id

        where sa.Enabled <> sa.id

              and sa.OwnerFirm_ID > 0

              and fr.Sales_ID > 0 --and sa.ACSTAT_Const = 5 -- только активные субсчета

        select *

        from #t1



        -----------------------------------------------------таблица с правами на субсчета текущее состояние где не найден текущий сейлз-----------------

        select *

             , t1.SubAccCodeSales SubAccCodeSales1

        into #t3

        from #t           t

            left join #t1 t1

                on t.OwnerFirmID = t1.IDSales

                   and t.childID = t1.IDsubacc

        where IDSales is null -- and SubAccCodeStruct = '00001'

        select *

        from #t3

        ------------------------------------------------------таблица с субсчетами и сейлзами текущее состояние где нет записи в таблице с правами----------

        select *

             , up1.User_ID UserID

        into #t4

        from #t1                                   t1

            left join #t                           t

                on t.OwnerFirmID = t1.IDSales

                   and t.childID = t1.IDsubacc

            left join QORT_BACK_DB..UserProperties up1

                on up1.UserCode = t1.IDSales

        where t.ChildID is null

              and LEFT(t1.SubAccCodeSales, 2) = 'AS'

        select *

        from #t4



    -- /*   ----------------------------------------------------------удаляем записи где не найден текущий сейлз---------------------------------------

        insert into QORT_BACK_TDB..ImportUserSubaccs

        (

            ET_Const

          , IsProcessed

          , UID

          , Subacc_Code

          , ID

        )	

		--*/

        select 8 ET_Const

             , 1 IsProcessed

             , t3.fatherID

             , t3.SubAccCodeAN

             , idR

        from #t3 t3

		where NOT (t3.SubAccCodeAN in ('AS1474','AS1529','AS1854') AND t3.fatherID = '72')

	

   -- /*    ----------------------------------------------------------добавляем записи где текущее состояние - нет записи в таблице с правами----------------------

        insert into QORT_BACK_TDB..ImportUserSubaccs

        (

            ET_Const

          , IsProcessed

          , UID

          , Subacc_Code

          , isAnalytic

        )

		--*/

        select 2 ET_Const

             , 1 IsProcessed

             , t4.UserID

             , t4.SubAccCodeSales

             , 'n'

        from #t4 t4

        where t4.IDSales in ( 942, 1241, 1265, 618, 1358, 1238, 2004 ) -- Елена, Мария, Тигран, Виктор, Карен, Эди, Алексей

		



    end try

    begin catch

        while @@TRANCOUNT > 0

        ROLLBACK TRAN

        set @Message = 'ERROR: ' + ERROR_MESSAGE();

        insert into QORT_ARM_SUPPORT.dbo.uploadLogs

        (

            logMessage

          , errorLevel

        )

        values

        (@message, 1001);

        print @Message

        select @Message Result

             , 'red'    ResultColor

    end catch



END



