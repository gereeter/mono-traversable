{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE FlexibleContexts #-}
module Data.Sequences where

import Data.Monoid
import Data.MonoTraversable
import Data.Int (Int64, Int)
import qualified Data.List as List
import qualified Control.Monad (filterM, replicateM)
import Prelude (Bool (..), Monad (..), Maybe (..), Ordering (..), Ord (..), Eq (..), Functor (..), fromIntegral)
import qualified Data.ByteString as S
import qualified Data.ByteString.Lazy as L
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import Control.Category
import Control.Arrow ((***), second)
import Control.Monad (liftM)

-- | Laws:
--
-- > fromList . toList = id
-- > fromList (x <> y) = fromList x <> fromList y
-- > ctoList (fromList x <> fromList y) = x <> y
class (Monoid c, MonoTraversable c) => IsSequence c where
    singleton :: Element c -> c

    fromList :: [Element c] -> c
    fromList = mconcat . fmap singleton

    replicate :: Int -> Element c -> c
    replicate i = fromList . List.replicate i
    
    replicate64 :: Int64 -> Element c -> c
    replicate64 i = fromList . List.genericReplicate i
    
    replicateM :: Monad m => Int -> m (Element c) -> m c
    replicateM i = liftM fromList . Control.Monad.replicateM i
    
    filter :: (Element c -> Bool) -> c -> c
    filter f = fromList . List.filter f . ctoList

    filterM :: Monad m => (Element c -> m Bool) -> c -> m c
    filterM f = Control.Monad.liftM fromList . filterM f . ctoList

    intersperse :: Element c -> c -> c
    intersperse e = fromList . List.intersperse e . ctoList

    break :: (Element c -> Bool) -> c -> (c, c)
    break f = (fromList *** fromList) . List.break f . ctoList

    span :: (Element c -> Bool) -> c -> (c, c)
    span f = (fromList *** fromList) . List.span f . ctoList

    dropWhile :: (Element c -> Bool) -> c -> c
    dropWhile f = fromList . List.dropWhile f . ctoList
    
    takeWhile :: (Element c -> Bool) -> c -> c
    takeWhile f = fromList . List.takeWhile f . ctoList

    splitAt :: Int -> c -> (c, c)
    splitAt i = (fromList *** fromList) . List.splitAt i . ctoList

    splitAt64 :: Int64 -> c -> (c, c)
    splitAt64 i = (fromList *** fromList) . List.genericSplitAt i . ctoList

    -- FIXME split :: (Element c -> Bool) -> c -> [c]

    reverse :: c -> c
    reverse = fromList . List.reverse . ctoList

    find :: (Element c -> Bool) -> c -> Maybe (Element c)
    find f = List.find f . ctoList
    
    partition :: (Element c -> Bool) -> c -> (c, c)
    partition f = (fromList *** fromList) . List.partition f . ctoList
    
    sortBy :: (Element c -> Element c -> Ordering) -> c -> c
    sortBy f = fromList . List.sortBy f . ctoList
    
    cons :: Element c -> c -> c
    cons e = fromList . (e:) . ctoList

    uncons :: c -> Maybe (Element c, c)
    uncons = fmap (second fromList) . uncons . ctoList

    groupBy :: (Element c -> Element c -> Bool) -> c -> [c]
    groupBy f = fmap fromList . List.groupBy f . ctoList
    
    -- FIXME take, drop

instance IsSequence [a] where
    singleton = return
    fromList = id
    {-# INLINE fromList #-}
    replicate = List.replicate
    replicate64 = List.genericReplicate
    replicateM = Control.Monad.replicateM
    filter = List.filter
    filterM = Control.Monad.filterM
    intersperse = List.intersperse
    break = List.break
    span = List.span
    dropWhile = List.dropWhile
    takeWhile = List.takeWhile
    splitAt = List.splitAt
    splitAt64 = List.genericSplitAt
    reverse = List.reverse
    find = List.find
    partition = List.partition
    sortBy = List.sortBy
    cons = (:)
    uncons [] = Nothing
    uncons (x:xs) = Just (x, xs)
    groupBy = List.groupBy

instance IsSequence S.ByteString where
    singleton = S.singleton
    fromList = S.pack
    replicate = S.replicate
    replicate64 i = S.replicate (fromIntegral i)
    filter = S.filter
    intersperse = S.intersperse
    break = S.break
    span = S.span
    dropWhile = S.dropWhile
    takeWhile = S.takeWhile
    splitAt = S.splitAt
    splitAt64 i = S.splitAt (fromIntegral i)
    reverse = S.reverse
    find = S.find
    partition = S.partition
    cons = S.cons
    uncons = S.uncons
    groupBy = S.groupBy
    -- sortBy

instance IsSequence T.Text where
    singleton = T.singleton
    fromList = T.pack
    replicate i c = T.replicate i (T.singleton c)
    replicate64 i c = T.replicate (fromIntegral i) (T.singleton c)
    filter = T.filter
    intersperse = T.intersperse
    break = T.break
    span = T.span
    dropWhile = T.dropWhile
    takeWhile = T.takeWhile
    splitAt = T.splitAt
    splitAt64 i = T.splitAt (fromIntegral i)
    reverse = T.reverse
    find = T.find
    partition = T.partition
    cons = T.cons
    uncons = T.uncons
    groupBy = T.groupBy
    -- sortBy

instance IsSequence L.ByteString where
    singleton = L.singleton
    fromList = L.pack
    replicate i = L.replicate (fromIntegral i)
    replicate64 = L.replicate
    filter = L.filter
    intersperse = L.intersperse
    break = L.break
    span = L.span
    dropWhile = L.dropWhile
    takeWhile = L.takeWhile
    splitAt i = L.splitAt (fromIntegral i)
    splitAt64 = L.splitAt
    reverse = L.reverse
    find = L.find
    partition = L.partition
    cons = L.cons
    uncons = L.uncons
    groupBy = L.groupBy
    -- sortBy

instance IsSequence TL.Text where
    singleton = TL.singleton
    fromList = TL.pack
    replicate i c = TL.replicate (fromIntegral i) (TL.singleton c)
    replicate64 i c = TL.replicate i (TL.singleton c)
    filter = TL.filter
    intersperse = TL.intersperse
    break = TL.break
    span = TL.span
    dropWhile = TL.dropWhile
    takeWhile = TL.takeWhile
    splitAt i = TL.splitAt (fromIntegral i)
    splitAt64 = TL.splitAt
    reverse = TL.reverse
    find = TL.find
    partition = TL.partition
    cons = TL.cons
    uncons = TL.uncons
    groupBy = TL.groupBy
    -- sortBy

class (IsSequence c, Eq (Element c)) => EqSequence c where
    stripPrefix :: c -> c -> Maybe c
    isPrefixOf :: c -> c -> Bool
    stripSuffix :: c -> c -> Maybe c
    isSuffixOf :: c -> c -> Bool
    isInfixOf :: c -> c -> Bool

instance Eq a => EqSequence [a] where
    stripPrefix = List.stripPrefix
    isPrefixOf = List.isPrefixOf
    stripSuffix x y = fmap reverse (List.stripPrefix (reverse x) (reverse y))
    isSuffixOf x y = List.isPrefixOf (reverse x) (reverse y)
    isInfixOf = List.isInfixOf

class (EqSequence c, Ord (Element c)) => OrdSequence c where
    sort :: c -> c
    sort = sortBy compare
    group :: c -> [c]
    group = groupBy (==)

class (IsSequence l, IsSequence s) => LazySequence l s | l -> s, s -> l where
    toChunks :: l -> [s]
    fromChunks :: [s] -> l
    toStrict :: l -> s
    fromStrict :: s -> l

class (IsSequence t, IsSequence b) => Textual t b | t -> b, b -> t where
    words :: t -> [t]
    unwords :: [t] -> t
    lines :: t -> [t]
    unlines :: [t] -> t
    encodeUtf8 :: t -> b
    decodeUtf8 :: b -> t
    toLower :: t -> t
    toUpper :: t -> t
    toCaseFold :: t -> t