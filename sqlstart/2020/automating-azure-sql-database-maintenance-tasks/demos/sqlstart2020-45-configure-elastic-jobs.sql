-------------------------------------------------------------------------
-- Event:       SQL Start 2020 - June 26, 2020                          -
--              https://www.sqlstart.it/2020/Speakers/Sergio-Govoni     -
-- Session:     Automating Azure SQL Database maintenance tasks         -
-- Demo:        Configure Elastic Jobs                                  -
-- Author:      Sergio Govoni                                           -
-- Notes:       --                                                      -
-------------------------------------------------------------------------

-- Connect to the job database specified when creating the job agent
USE [DBJobs];
GO


SELECT * FROM sys.symmetric_keys;
GO


-- Create a db master key if one does not already exist,
-- using your own password
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SiCrJvjZX}QXT6wODwXf';
GO


-- Create a database scoped credential
CREATE DATABASE SCOPED CREDENTIAL jobcredential
  WITH IDENTITY = 'sql-job-user'
  ,SECRET = 'SiCrJvjZX}QXT6wODwXf'; 
GO


-- Create a database scoped credential for the master database of the first server
CREATE DATABASE SCOPED CREDENTIAL masterjobcredential
  WITH IDENTITY = 'sql-job-master',
  SECRET = 'SiCrJvjZX}QXT6wODwXf'; 
GO


SELECT * FROM sys.database_scoped_credentials;
GO


-- https://docs.microsoft.com/en-us/azure/sql-database/elastic-jobs-powershell#create-job-credentials-so-that-jobs-can-execute-scripts-on-its-targets
USE [master];


CREATE LOGIN [sql-job-master] WITH PASSWORD = 'SiCrJvjZX}QXT6wODwXf';
CREATE USER [sql-job-master] FOR LOGIN [sql-job-master];
GO


CREATE LOGIN [sql-job-user] WITH PASSWORD = 'SiCrJvjZX}QXT6wODwXf';
GO


SELECT * FROM sys.sql_logins;
GO



USE [Maintenance];
GO

CREATE USER [sql-job-user] FOR LOGIN [sql-job-user];
GO

--EXEC sp_addrolemember [sql-job-user], db_ddladmin
--EXEC sp_addrolemember [sql-job-user], [db_datawriter]

GRANT EXECUTE ON OBJECT::[dbo].[IndexOptimize] TO [sql-job-user];
GRANT EXECUTE ON OBJECT::[dbo].[CommandExecute] TO [sql-job-user];
GO


SELECT * FROM sys.database_principals;
GO


-- Connect to the job database specified when creating the job agent
USE [DBJobs];
GO


-- Add a target group containing server(s)
EXEC jobs.sp_add_target_group 'ServerGroupDemo';
GO


-- Add a server target member
EXEC jobs.sp_add_target_group_member
  'ServerGroupDemo',
  @target_type = 'SqlServer',
  -- Credential required to refresh the databases in server
  @refresh_credential_name='masterjobcredential',
  @server_name='sql-start.database.windows.net';
GO


-- View the recently created target group and target group members
SELECT * FROM jobs.target_groups WHERE target_group_name = 'ServerGroupDemo';
SELECT * FROM jobs.target_group_members WHERE target_group_name = 'ServerGroupDemo';
GO


-- Add job for rebuild/reorganize indexes
EXEC jobs.sp_add_job
  @job_name='IndexOptimize'
  ,@description='Rebuild or reorganize all indexes with fragmentation';
GO


-- Add job step for create table
EXEC jobs.sp_add_jobstep
  @job_name='IndexOptimize'
  ,@command=N'EXECUTE dbo.IndexOptimize @Databases = ''Maintenance'', @FragmentationLow = NULL, @FragmentationMedium = ''INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'', @FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'', @FragmentationLevel1 = 5, @FragmentationLevel2 = 30'
  ,@credential_name='jobcredential'
  ,@target_group_name='ServerGroupDemo';
GO


EXEC jobs.sp_update_jobstep
  @job_name='IndexOptimize'
  ,@step_id = 1
  ,@command=N'EXECUTE dbo.IndexOptimize @Databases = ''Maintenance'', @FragmentationLow = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'', @FragmentationMedium = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'', @FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'', @FragmentationLevel1 = 5, @FragmentationLevel2 = 30, @UpdateStatistics = ''COLUMNS'', @OnlyModifiedStatistics = ''Y'''
  ,@credential_name='jobcredential'
  ,@target_group_name='ServerGroupDemo';
GO


-- Exclude a database target member from the server target group
EXEC jobs.sp_add_target_group_member
  @target_group_name = N'ServerGroupDemo'
  ,@membership_type = N'Exclude'
  ,@target_type = N'SqlDatabase'
  ,@server_name = N'sql-start.database.windows.net'
  ,@database_name =N'DBJobs';
GO


SELECT * FROM jobs.jobs;
SELECT * FROM jobs.jobsteps;
SELECT * FROM jobs.target_groups WHERE target_group_name = 'ServerGroupDemo';
SELECT * FROM jobs.target_group_members WHERE target_group_name = 'ServerGroupDemo';
GO


-- Drop job
EXEC jobs.sp_delete_job
  @job_name='IndexOptimize';
GO