------------------------------------------------------------------------
-- Event:        Delphi & Dintorni - July 09, 2020                     -
-- Session:      SQL Server Execution Plans: From Zero to Hero         -
--               https://bit.ly/3e9vLAB                                -
-- Demo:         The Execution Plan of an "Update"                     -
-- Author:       Sergio Govoni                                         -
-- Notes:        --                                                    -
------------------------------------------------------------------------

USE [AdventureWorks2017];
GO

-- Insert, Update and Delete Execution Plans


-- Insert

/*
select * from Production.ProductSubcategory order by ProductSubcategoryID desc;

delete from Production.ProductSubcategory where ProductSubcategoryID = 43;

DBCC CHECKIDENT ('Production.ProductSubcategory');
DBCC CHECKIDENT ('Production.ProductSubcategory', RESEED, x);
*/

INSERT INTO Production.ProductSubcategory
(
  ProductCategoryID, Name, rowguid, ModifiedDate
)
VALUES
(
  (SELECT ProductCategoryID FROM Production.ProductCategory WHERE Name = 'Bikes')
  ,'Blue Bikes', NEWID(), GETDATE()
);

-- L'esecuzione inizia con un Constant Scan ==> "costruisce" la riga

-- Compute Scalar esegue la GETIDENTITY(), qui viene generato l'identity per l'ID

-- Si spiega perch� quando un Insert fallisce l'ID generato � "consumato"

-- Dopo aver letto ProductCategory, Compute Scalar ==> esegue GETDATE(), NEWID()

-- Clustered Index Insert ha il costo maggiore, implementa l'INSERT!

-- Viene poi verificata l'integrit� referenziale per ProductCategoryID
-- (= letture in un comando di Insert)

-- L'Assert, in questo caso, verifica il rispetto dell'integrit� referenziale





/*** Update ***/

/*
select * from Production.ProductSubcategory where name like '%blue%'
*/

UPDATE
  Production.ProductSubcategory
SET
  Name = 'Bikes color Blue'
  --,ModifiedDate = GETDATE()
WHERE
  Name = 'Blue Bikes';
GO


-- Uno statement due piani di esecuzione...

-- L'esecuzione inizia con un Index Seek vengono individuate le righe da aggiornare

-- TOP nel piano di esecuzione di un UPDATE forza il numero di righe

-- I Compute Scalar sono utilizzati per valutare le espressioni

-- Il cuore dell'UPDATE � il Clustered Index Update, in input le
-- righe da aggiornare ==> le aggiorna

-- Performance: come vengono reperite le righe da aggiornare?





/*** Delete ***/

DELETE
FROM
  Person.Address
WHERE
  AddressID=32525;
GO

-- Che piano di esecuzione ci aspettiamo per un DELETE?

-- Il piano assomiglia di pi� a quello di una SELECT

-- Clustered Index Delete � la prima operazione che viene eseguita

-- Nel predicato seek notiamo l'utilizzo del parametro @1, perch�?

-- Da dove arriva il parametro? ==> l'engine ha generato un piano riutilizzabile

-- Serie di Clustered Index Seek e Scan combinati con Nested Loop Join,
-- restituiscono un valore per indicare o meno la presenza di un match
-- tra la riga che si sta eliminando e una o pi� righe nelle tabelle
-- collegate

-- Assert controlla che tutte le integrit� siano rispettare ==> DELETE andr� a buon fine