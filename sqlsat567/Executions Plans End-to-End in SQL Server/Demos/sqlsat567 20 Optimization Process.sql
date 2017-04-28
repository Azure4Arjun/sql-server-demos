------------------------------------------------------------------------
-- Event:        SQL Saturday #567 Ljubljana, December 10 2016         -
--               http://www.sqlsaturday.com/567/eventhome.aspx         -
-- Session:      Executions Plans End-to-End in SQL Server             -
-- Demo:         The Optimization Process                              -
-- Author:       Sergio Govoni                                         -
-- Notes:        --                                                    -
------------------------------------------------------------------------

USE [AdventureWorks2016];
GO



------------------------------------------------------------------------
-- The Optimization Process                                            -
------------------------------------------------------------------------

-- Returns detailed statistics about the operation of the Query Optimizer
-- All values are cumulative since the system starts

-- You can use this DMV when tuning a workload to identify query optimization 
-- problems or improvements

-- counter = The name of the optimizer event
-- occurrence = The number of occurrences of the optimization event for this counter
-- value = The average value per event occurrence

SELECT * FROM sys.dm_exec_query_optimizer_info;
GO



-- Detailed statistics from the Query Optimizer

-- Thanks to the result of this CTE we can observe the percentage of trivial plan,
-- the percentage of plans generated by these phases: search 0, 1 and 2.

-- We can also observe the percentage of time-out, with time-out, I intend the end of the time
-- assigned to the optimization phases

WITH QO AS
(
  SELECT
    occurrence
  FROM
    sys.dm_exec_query_optimizer_info
  WHERE
    ([counter] = 'optimizations')
),
QOInfo AS
(
  SELECT
    [counter]
    ,[%] = CAST((occurrence * 100.00)/(SELECT occurrence FROM QO) AS DECIMAL(5, 2))
  FROM
    sys.dm_exec_query_optimizer_info
  WHERE
    [counter] IN (
                   'optimizations'
                   ,'trivial plan'
                   ,'no plan'
                   ,'search 0'
                   ,'search 1'
                   ,'search 2'
                   ,'timeout'
                   ,'memory limit exceeded'
                   ,'contains subquery'
                   ,'view reference'
                   ,'remote query'
                   ,'dynamic cursor request'
                   ,'fast forward cursor request'
	               )
)
SELECT
  [optimizations] AS [optimizations %]
  ,[trivial plan] AS [trivial plan %]
  ,[no plan] AS [no plan %]
  ,[search 0] AS [search 0 %]
  ,[search 1] AS [search 1 %]
  ,[search 2] AS [search 2 %]
  ,[timeout] AS [timeout %]
  ,[memory limit exceeded] AS [memory limit exceeded %]
  ,[contains subquery] AS [contains subquery %]
  ,[view reference] AS [view reference %]
  ,[remote query] AS [remote query %]
  ,[dynamic cursor request] AS [dynamic cursor request %]
  ,[fast forward cursor request] AS [fast forward cursor request %]
FROM
  QOInfo
PIVOT (MAX([%]) FOR [counter] 
  IN ([optimizations]
      ,[trivial plan]
      ,[no plan]
      ,[search 0]
      ,[search 1]
      ,[search 2]
      ,[timeout]
      ,[memory limit exceeded]
      ,[contains subquery]
      ,[view reference]
      ,[remote query]
      ,[dynamic cursor request]
      ,[fast forward cursor request])) AS p;
GO

-- What's this query for?
-- Its goal is to understand better the workload!





------------------------------------------------------------------------
-- How to obtain information about the optimization                    -
-- applied to a particular query                                       -
------------------------------------------------------------------------

-- Because the DMV stores cumulative values since the SQL Server service
-- starts we must use the following technique:

-- 1) Saving optimization values in a particular moment
--    before the execution of the query we are focusing on
-- 2) Execute the query
-- 3) Another saving of the optimization values
-- 4) Make a SUBTRACTION of the values in step 1 and 3


-- To let the system know the query used in the first and third steps,
-- we have to execute them at the very beginning, discarding the results


DBCC FREEPROCCACHE;
GO

SELECT * INTO #optimizer_info_before_query FROM sys.dm_exec_query_optimizer_info;
GO

SELECT * INTO #optimizer_info_after_query FROM sys.dm_exec_query_optimizer_info;
GO

DROP TABLE #optimizer_info_before_query;
DROP TABLE #optimizer_info_after_query;
GO

SELECT * INTO #optimizer_info_before_query FROM sys.dm_exec_query_optimizer_info;
GO

-- 2. This query retrieves sales order starting from October 2007
-- grouped by order number, ordered by total
SELECT
  h.SalesOrderNumber
  ,SUM(d.LineTotal) AS LinesTotal
FROM
  Sales.SalesOrderHeader AS h
JOIN
  Sales.SalesOrderDetail AS d
  ON h.SalesOrderID=d.SalesOrderID
WHERE
  (h.OrderDate >= '20071001')
GROUP BY
  h.SalesOrderNumber
ORDER BY
  LinesTotal DESC;
GO

SELECT * INTO #optimizer_info_after_query FROM sys.dm_exec_query_optimizer_info;
GO

-- SUBTRACTION of the values in step 1 and 3
SELECT
  a.counter
  ,occurrence = (a.occurrence - b.occurrence)
  ,value = ((a.occurrence * a.value) - (b.occurrence * b.value))
FROM
  #optimizer_info_before_query AS b
JOIN
  #optimizer_info_after_query AS a ON a.counter=b.counter
WHERE
  (a.occurrence <> b.occurrence);
GO

DROP TABLE #optimizer_info_before_query;
DROP TABLE #optimizer_info_after_query;
GO






------------------------------------------------------------------------
-- *** Bonus queries ***                                               -
------------------------------------------------------------------------


------------------------------------------------------------------------
-- Transformation rules                                                -
------------------------------------------------------------------------

-- 399 rules on SQL Server 2016
SELECT * FROM sys.dm_exec_query_transformation_stats;
GO

DBCC FREEPROCCACHE;
GO

SELECT * INTO #query_transformation_stats_before_query
FROM sys.dm_exec_query_transformation_stats;
GO

SELECT * INTO #query_transformation_stats_after_query
FROM sys.dm_exec_query_transformation_stats;
GO

DROP TABLE #query_transformation_stats_before_query;
DROP TABLE #query_transformation_stats_after_query;
GO


SELECT * INTO #query_transformation_stats_before_query
FROM sys.dm_exec_query_transformation_stats;
GO


SELECT
  P.FirstName
  ,P.LastName
  ,C.AccountNumber
FROM
  Person.Person AS P
JOIN
  Sales.Customer AS C ON C.PersonID=P.BusinessEntityID;

-- Query
-- 0,769501 with GbAggToHS ON
-- 2,48905  with GbAggToHS OFF
--SELECT
--  t.TerritoryID
--  ,COUNT(*)
--FROM
--  Sales.SalesTerritory AS t
--JOIN
--  Sales.SalesOrderHeader AS h ON h.TerritoryID=t.TerritoryID
--GROUP BY
--  t.TerritoryID;
--GO


--SELECT
--  P.FirstName
--  ,P.LastName
--  ,C.AccountNumber
--FROM
--  Person.Person AS P
--JOIN
--  Sales.Customer AS C ON C.PersonID = P.BusinessEntityID
----OPTION (RECOMPILE);
----OPTION (RECOMPILE, LOOP JOIN, MERGE JOIN);
--OPTION(RECOMPILE, QUERYRULEOFF JNtoHS, QUERYRULEOFF JNtoSM);


SELECT * INTO #query_transformation_stats_after_query
FROM sys.dm_exec_query_transformation_stats;
GO

SELECT
  a.name
  ,promised = (a.promised - b.promised)
FROM
  #query_transformation_stats_before_query AS b
JOIN
  #query_transformation_stats_after_query AS a ON a.name=b.name
WHERE
  (a.succeeded <> b.succeeded);
GO

DROP TABLE #query_transformation_stats_before_query;
DROP TABLE #query_transformation_stats_after_query;
GO


------------------------------------------------------------------------
-- Disable/Enable transformation rules                                 -
--                                                                     -
-- DBCC RULEON(), DBCC RULEOFF()                                       -
------------------------------------------------------------------------

DBCC RULEOFF('GbAggBeforeJoin');
DBCC RULEOFF('GbAggToHS'); -- Group By Aggregate to Hash
GO

DBCC RULEON('GbAggBeforeJoin');
DBCC RULEON('GbAggToHS'); -- Group By Aggregate to Hash
GO

DBCC SHOWOFFRULES;
GO

DBCC SHOWONRULES;
GO