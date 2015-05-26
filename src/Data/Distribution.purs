-- | This module defines a monad of _distributions_, which generalizes the probability monad
-- | to an arbitrary `Semiring`.

module Data.Distribution 
  ( Dist()
  , dist
  , observe
  ) where

import Data.List
import Data.Tuple
import Data.Foldable (fold)
import Data.Function (on)
import Data.Monoid.Additive

import Control.Alt
import Control.Alternative
import Control.Plus
import Control.MonadPlus

-- | A distribution of values of type `a`, with "probabilities" in some `Semiring p`.
data Dist p a = Dist (List (Tuple p a))

-- | Create a distribution from a list of values and probabilities.
dist :: forall p a. List (Tuple p a) -> Dist p a
dist = Dist

runDist :: forall p a. Dist p a -> List (Tuple p a)
runDist (Dist d) = d

-- | Unpack the observations in a distribution, combining any probabilities for
-- | duplicate observations.
observe :: forall p a. (Semiring p, Eq a) => Dist p a -> List (Tuple p a)
observe d = collect <$> groupBy ((==) `on` snd) (runDist d)
  where
  collect :: List (Tuple p a) -> Tuple p a
  collect d@(Cons (Tuple _ a) _) = 
    let p = runAdditive (fold (Additive <<< fst <$> d))
    in Tuple p a

instance functorDist :: Functor (Dist p) where
  (<$>) f (Dist d) = Dist ((f <$>) <$> d)

instance applyDist :: (Semiring p) => Apply (Dist p) where
  (<*>) = ap
  
instance applicativeDist :: (Semiring p) => Applicative (Dist p) where
  pure a = Dist (pure (Tuple one a))
  
instance bindDist :: (Semiring p) => Bind (Dist p) where
  (>>=) d f = Dist do
     Tuple p1 a <- runDist d
     Tuple p2 b <- runDist (f a)
     return (Tuple (p1 * p2) b)
     
instance monadDist :: (Semiring p) => Monad (Dist p)

instance altDist :: Alt (Dist p) where
  (<|>) d1 d2 = Dist (runDist d1 <|> runDist d2)
  
instance plusDist :: Plus (Dist p) where
  empty = Dist empty
  
instance alternativeDist :: (Semiring p) => Alternative (Dist p)
  
instance monadPlusDist :: (Semiring p) => MonadPlus (Dist p)
