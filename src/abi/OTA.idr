-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- OTA.idr — Over-the-Air update ABI contract with state-machine proofs.
--
-- Implementation: ffi/zig/src/esp_idf_ota.zig (wraps ESP-IDF esp_https_ota).

module KaldorBBW.ABI.OTA

import KaldorBBW.ABI.Types

%default total

-- --------------------------------------------------------------------------
-- OTA state machine
-- --------------------------------------------------------------------------

||| Valid states for the OTA update process.
public export
data OtaState
  = OtaIdle        -- no update in progress
  | OtaDownloading -- receiving firmware bytes
  | OtaVerifying   -- checksum / signature check
  | OtaInstalling  -- writing to flash partition
  | OtaComplete    -- update successful; pending reboot
  | OtaError       -- update failed; back to idle after reset

||| Proof that @begin@ is callable only from the Idle state.
public export
data CanBegin : OtaState -> Type where
  BeginFromIdle : CanBegin OtaIdle

||| Proof that @abort@ is callable only during active (non-terminal) states.
public export
data CanAbort : OtaState -> Type where
  AbortDownloading : CanAbort OtaDownloading
  AbortVerifying   : CanAbort OtaVerifying
  AbortInstalling  : CanAbort OtaInstalling

||| Proof that markValid is callable only when complete.
public export
data CanMarkValid : OtaState -> Type where
  MarkValidWhenComplete : CanMarkValid OtaComplete

-- --------------------------------------------------------------------------
-- OTA interface
-- --------------------------------------------------------------------------

||| Contract for OTA operations with typed state-machine transitions.
public export
interface OtaABI (0 m : Type -> Type) where

  ||| Start a firmware download from the given HTTPS URL.
  ||| Only callable when in the Idle state (enforced by @CanBegin s@).
  begin    : OtaUrl
          -> {0 s : OtaState}
          -> {auto 0 _ : CanBegin s}
          -> m Bool

  ||| Poll download progress.  Returns (bytesReceived, totalBytes).
  progress : m (Nat, Nat)

  ||| Verify the downloaded firmware image.  Returns True if signature valid.
  verify   : m Bool

  ||| Commit the verified image to the active partition.
  finish   : m Bool

  ||| Abort an in-progress update (download / verify / install only).
  abort    : {0 s : OtaState}
          -> {auto 0 _ : CanAbort s}
          -> m ()

  ||| Mark the running firmware as valid to prevent automatic rollback.
  markValid : m ()

  ||| Roll back to the previous firmware image.
  rollback  : m ()
