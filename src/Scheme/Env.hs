module Scheme.Env
  ( bindVars
  , defineVar
  , getVar
  , nullEnv
  , setVar
  ) where

import Control.Monad.Except
import Control.Monad.Reader
import Data.IORef

import Scheme.Types

nullEnv :: IO Env
nullEnv = newIORef []

isBound :: Env -> String -> IO Bool
isBound envRef var = readIORef envRef >>= return . maybe False (const True) . lookup var

getVar :: String -> EvalM LispVal
getVar var  =  do
    envRef <- ask
    env <- liftIO $ readIORef envRef
    maybe (throwError $ UnboundVar "Getting an unbound variable" var)
                             (liftIO . readIORef)
                             (lookup var env)

setVar :: String -> LispVal -> EvalM LispVal
setVar var value = do
    envRef <- ask
    env <- liftIO $ readIORef envRef
    maybe (throwError $ UnboundVar "Setting an unbound variable" var)
        (liftIO . (flip writeIORef value))
        (lookup var env)
    return value


defineVar :: String -> LispVal -> EvalM LispVal
defineVar var value = do
    envRef <- ask
    alreadyDefined <- liftIO $ isBound envRef var
    if alreadyDefined
       then setVar var value >> return value
       else liftIO $ do
          valueRef <- newIORef value
          env <- readIORef envRef
          writeIORef envRef ((var, valueRef) : env)
          return value

bindVars :: Env -> [(String, LispVal)] -> IO Env
bindVars envRef bindings = readIORef envRef >>= extendEnv bindings >>= newIORef
    where extendEnv bindings env = fmap (++ env) (mapM addBinding bindings)
          addBinding (var, value) = do ref <- newIORef value
                                       return (var, ref)


