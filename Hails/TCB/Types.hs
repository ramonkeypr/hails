{-# LANGUAGE CPP #-}
#if __GLASGOW_HASKELL__ >= 704
{-# LANGUAGE Unsafe #-}
#endif
{-# LANGUAGE DeriveFunctor,
             GeneralizedNewtypeDeriving #-}
             
module Hails.TCB.Types ( AppName
                       , AppConf(..)
                       , AppReqHandler
                       , AppRoute
                       ) where

import qualified Data.ByteString.Lazy as L
import Data.IterIO
import Data.IterIO.Http
import Data.IterIO.HttpRoute

import LIO
import DCLabel.TCB
import LIO.DCLabel

type L = L.ByteString

-- | Application name
type AppName = String

-- | Application configuration.
data AppConf = AppConf { appUser :: !Principal
                         -- ^ User the app is running on behalf of
                         , appName :: !AppName
                         -- ^ The app's name
                         , appPriv :: !TCBPriv
                         -- ^ The app's privileges.
                         , appReq  :: HttpReq ()
                         -- ^ The request message
                         } deriving (Show)

-- | Application handler.
type AppReqHandler = Labeled DCLabel (HttpReq (), L) -> Iter L DC (HttpResp DC)

-- | Application route.
type AppRoute = HttpRoute DC ()
