{-# LANGUAGE CPP #-}
#if __GLASGOW_HASKELL__ >= 702
{-# LANGUAGE Safe #-}
#endif
{-# LANGUAGE FlexibleContexts #-}

module Hails.Database.MongoDB.Structured ( DCRecord(..) ) where

import LIO
import LIO.DCLabel

import Hails.Database
import Hails.Database.MongoDB

import Data.Monoid (mappend)
import Control.Monad (liftM)

-- | Class for converting from \"structured\" records to documents
-- (and vice versa).
class DCRecord a where
  -- | Convert a document to a record
  fromDocument :: Monad m => Document DCLabel -> m a
  -- | Convert a record to a document
  toDocument :: a -> Document DCLabel
  -- | Get the collection name for the record
  collectionName :: a -> CollectionName
  -- | Find an object with mathing value for the given key
  findBy :: (Val DCLabel v, DatabasePolicy p)
         => p -> CollectionName -> Key -> v -> DC (Maybe a)
  -- | Find an object with given query
  findWhere :: (DatabasePolicy p)
            => p -> Query DCLabel -> DC (Maybe a)
  -- | Insert a record into the database
  insertRecord :: (DatabasePolicy p)
               => p -> a -> DC (Either Failure (Value DCLabel))
  -- | Insert a record into the database
  saveRecord :: (DatabasePolicy p)
             => p -> a -> DC (Either Failure ())
  -- | Same as 'findBy', but using explicit privileges.
  findByP :: (Val DCLabel v, DatabasePolicy p)
          => DCPrivTCB -> p -> CollectionName -> Key -> v -> DC (Maybe a)
  -- | Same as 'findWhere', but using explicit privileges.
  findWhereP :: (DatabasePolicy p)
            => DCPrivTCB -> p -> Query DCLabel -> DC (Maybe a)
  -- | Same as 'insertRecord', but using explicit privileges.
  insertRecordP :: (DatabasePolicy p)
              => DCPrivTCB -> p -> a -> DC (Either Failure (Value DCLabel))
  -- | Same as 'saveRecord', but using explicit privileges.
  saveRecordP :: (DatabasePolicy p)
              => DCPrivTCB -> p -> a -> DC (Either Failure ())

  --
  -- Default definitions
  --

  --
  findBy = findByP noPrivs
  --
  findWhere = findWhereP noPrivs
  --
  insertRecordP p policy record = do
    let colName = collectionName record
    p' <- getPrivileges
    withDB policy $ insertP (p' `mappend` p)  colName $ toDocument record
  --
  insertRecord = insertRecordP noPrivs
  --
  saveRecordP p policy record = do
    let colName = collectionName record
    p' <- getPrivileges
    withDB policy $ saveP (p' `mappend` p) colName $ toDocument record
  --
  saveRecord = saveRecordP noPrivs
  --
  findByP p policy colName k v = do
    findWhereP p policy (select [k =: v] colName)
  --
  findWhereP p policy query  = do
    result <- withDB policy $ findOneP p query
    case result of
      Right (Just r) -> fromDocument `liftM` unlabelP p r
      _ -> return Nothing
  --
