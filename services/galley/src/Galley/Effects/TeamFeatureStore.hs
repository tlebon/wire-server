-- This file is part of the Wire Server implementation.
--
-- Copyright (C) 2021 Wire Swiss GmbH <opensource@wire.com>
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU Affero General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option) any
-- later version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
-- details.
--
-- You should have received a copy of the GNU Affero General Public License along
-- with this program. If not, see <https://www.gnu.org/licenses/>.

module Galley.Effects.TeamFeatureStore
  ( TeamFeatureStore (..),
    getFeatureStatusNoConfig,
    setFeatureStatusNoConfig,
    getApplockFeatureStatus,
    setApplockFeatureStatus,
    getSelfDeletingMessagesStatus,
    setSelfDeletingMessagesStatus,
    setPaymentStatus,
    getPaymentStatus,
  )
where

import Data.Id
import Data.Proxy
import Galley.Data.TeamFeatures
import Imports
import Polysemy
import Wire.API.Team.Feature

data TeamFeatureStore m a where
  -- the proxy argument makes sure that makeSem below generates type-inference-friendly code
  GetFeatureStatusNoConfig' ::
    forall (ps :: IncludePaymentStatus) (a :: TeamFeatureName) m.
    ( FeatureHasNoConfig ps a,
      HasStatusCol a
    ) =>
    Proxy ps ->
    Proxy a ->
    TeamId ->
    TeamFeatureStore m (Maybe (TeamFeatureStatus ps a))
  -- the proxy argument makes sure that makeSem below generates type-inference-friendly code
  SetFeatureStatusNoConfig' ::
    forall (ps :: IncludePaymentStatus) (a :: TeamFeatureName) m.
    ( FeatureHasNoConfig ps a,
      HasStatusCol a
    ) =>
    Proxy ps ->
    Proxy a ->
    TeamId ->
    TeamFeatureStatus ps a ->
    TeamFeatureStore m (TeamFeatureStatus ps a)
  GetApplockFeatureStatus ::
    TeamId ->
    TeamFeatureStore m (Maybe (TeamFeatureStatus ps 'TeamFeatureAppLock))
  SetApplockFeatureStatus ::
    TeamId ->
    TeamFeatureStatus 'WithoutPaymentStatus 'TeamFeatureAppLock ->
    TeamFeatureStore m (TeamFeatureStatus 'WithoutPaymentStatus 'TeamFeatureAppLock)
  GetSelfDeletingMessagesStatus ::
    TeamId ->
    TeamFeatureStore m (Maybe (TeamFeatureStatus 'WithoutPaymentStatus 'TeamFeatureSelfDeletingMessages), Maybe PaymentStatusValue)
  SetSelfDeletingMessagesStatus ::
    TeamId ->
    TeamFeatureStatus 'WithoutPaymentStatus 'TeamFeatureSelfDeletingMessages ->
    TeamFeatureStore m (TeamFeatureStatus 'WithoutPaymentStatus 'TeamFeatureSelfDeletingMessages)
  SetPaymentStatus' ::
    forall (a :: TeamFeatureName) m.
    ( HasPaymentStatusCol a
    ) =>
    Proxy a ->
    TeamId ->
    PaymentStatus ->
    TeamFeatureStore m PaymentStatus
  GetPaymentStatus' ::
    forall (a :: TeamFeatureName) m.
    ( MaybeHasPaymentStatusCol a
    ) =>
    Proxy a ->
    TeamId ->
    TeamFeatureStore m (Maybe PaymentStatus)

makeSem ''TeamFeatureStore

getFeatureStatusNoConfig ::
  forall (ps :: IncludePaymentStatus) (a :: TeamFeatureName) r.
  (Member TeamFeatureStore r, FeatureHasNoConfig ps a, HasStatusCol a) =>
  TeamId ->
  Sem r (Maybe (TeamFeatureStatus ps a))
getFeatureStatusNoConfig = getFeatureStatusNoConfig' (Proxy @ps) (Proxy @a)

setFeatureStatusNoConfig ::
  forall (ps :: IncludePaymentStatus) (a :: TeamFeatureName) r.
  (Member TeamFeatureStore r, FeatureHasNoConfig ps a, HasStatusCol a) =>
  TeamId ->
  TeamFeatureStatus ps a ->
  Sem r (TeamFeatureStatus ps a)
setFeatureStatusNoConfig = setFeatureStatusNoConfig' (Proxy @ps) (Proxy @a)

setPaymentStatus ::
  forall (a :: TeamFeatureName) r.
  (Member TeamFeatureStore r, HasPaymentStatusCol a) =>
  TeamId ->
  PaymentStatus ->
  Sem r PaymentStatus
setPaymentStatus = setPaymentStatus' (Proxy @a)

getPaymentStatus ::
  forall (a :: TeamFeatureName) r.
  (Member TeamFeatureStore r, MaybeHasPaymentStatusCol a) =>
  TeamId ->
  Sem r (Maybe PaymentStatus)
getPaymentStatus = getPaymentStatus' (Proxy @a)
