------------------------------------------------------------------------
-- Event:        SQL Saturday #707 Pordenone, February 17 2018         -
--               http://www.sqlsaturday.com/707/eventhome.aspx         -
-- Session:      SQL Server 2017 Graph Database                        -
-- Demo:         Setup                                                 -
-- Author:       Sergio Govoni                                         -
-- Notes:        --                                                    -
------------------------------------------------------------------------


-- Full backup of WideWorldImporters sample database is available on GitHub
-- https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0

-- Documentation about WideWorldImporters sample database for SQL Server
-- and Azure SQL Database
-- https://github.com/Microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers


USE [WideWorldImporters];
GO

CREATE SCHEMA [Nodes];
GO

CREATE SCHEMA [Edges];
GO