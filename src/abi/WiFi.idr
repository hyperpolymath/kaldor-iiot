-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- WiFi.idr — WiFi management ABI contract.
--
-- Implementation: ffi/zig/src/esp_idf_wifi.zig (wraps ESP-IDF esp_wifi).

module KaldorBBW.ABI.WiFi

%default total

-- --------------------------------------------------------------------------
-- RSSI
-- --------------------------------------------------------------------------

||| WiFi signal strength in dBm.
||| Constrained to the ESP32 reporting range (–100 to 0 dBm).
||| The value 31 returned by ESP-IDF when no signal is available is mapped
||| to –100 by the Zig FFI wrapper (see ffi/zig/src/esp_idf_wifi.zig).
public export
record Rssi where
  constructor MkRssi
  dBm   : Int
  lower : dBm >= -100 = True
  upper : dBm <=    0 = True

-- --------------------------------------------------------------------------
-- WiFi interface
-- --------------------------------------------------------------------------

||| Contract for WiFi status queries.
||| Connection management (connect / disconnect) is handled at the HAL level.
public export
interface WiFiABI (0 m : Type -> Type) where

  ||| Return True if the station is currently associated with an AP.
  isConnected : m Bool

  ||| Return the current RSSI.
  ||| The returned @Rssi@ proof guarantees the value is in –100..0.
  getRssi     : m Rssi

-- --------------------------------------------------------------------------
-- Proofs
-- --------------------------------------------------------------------------

||| –50 dBm is a valid RSSI (good signal).
public export
goodSignal : Rssi
goodSignal = MkRssi (-50) Refl Refl

||| –100 dBm is the worst valid RSSI (no signal sentinel).
public export
noSignal : Rssi
noSignal = MkRssi (-100) Refl Refl
