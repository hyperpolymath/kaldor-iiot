-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- Types.idr — Dependent-typed domain definitions for the Kaldor BBW board.
--
-- Every type here carries a proof that its value is within the valid physical
-- or protocol range.  The Zig FFI layer (ffi/zig/src/) enforces the same
-- bounds at runtime; these types make the contract explicit at compile time.

module KaldorBBW.ABI.Types

%default total

-- --------------------------------------------------------------------------
-- GPIO
-- --------------------------------------------------------------------------

||| ESP32 GPIO pin number, constrained to the Xtensa LX6 valid range 0–39.
public export
data GpioPin : Type where
  MkGpioPin : (n : Nat) -> {auto 0 prf : LTE n 39} -> GpioPin

||| GPIO operating mode — mirrors the esp_idf @c gpio_mode_t enum.
public export
data GpioMode
  = GpioDisable         -- 0  (no driver)
  | GpioInput           -- 1  (input only)
  | GpioOutput          -- 2  (push-pull output)
  | GpioOutputOD        -- 6  (open-drain output)
  | GpioInputOutput     -- 3  (bidirectional)

-- --------------------------------------------------------------------------
-- MQTT
-- --------------------------------------------------------------------------

||| MQTT QoS level.
||| 0 = at most once, 1 = at least once, 2 = exactly once.
public export
data MqttQos = QosAtMostOnce | QosAtLeastOnce | QosExactlyOnce

||| Encode QoS as the unsigned byte value expected on the wire.
public export
qosToU8 : MqttQos -> Bits8
qosToU8 QosAtMostOnce  = 0
qosToU8 QosAtLeastOnce = 1
qosToU8 QosExactlyOnce = 2

||| A valid MQTT topic string (MQTT 3.1.1 §4.7).
||| Non-empty, at most 256 bytes, no embedded NUL.
public export
record MqttTopic where
  constructor MkTopic
  bytes    : List Bits8
  nonEmpty : NonEmpty bytes
  bounded  : LTE (length bytes) 256

-- --------------------------------------------------------------------------
-- OTA
-- --------------------------------------------------------------------------

||| An HTTPS URL for firmware downloads.
||| Non-empty, at most 8192 characters, prefixed with "https://".
public export
record OtaUrl where
  constructor MkOtaUrl
  chars    : List Char
  nonEmpty : NonEmpty chars
  bounded  : LTE (length chars) 8192
  isHttps  : isPrefixOf (unpack "https://") chars = True

-- --------------------------------------------------------------------------
-- BBW sensor domain
-- --------------------------------------------------------------------------

||| Back Beam Width measurement in millimetres.
||| Physical operating range of the Kaldor loom: 10–500 mm (config.zig).
public export
record BbwMm where
  constructor MkBbwMm
  value : Double
  lower : value >= 10.0  = True
  upper : value <= 500.0 = True

||| Temperature reading in degrees Celsius (DHT22 range: –40 to +80 °C).
public export
record TempC where
  constructor MkTempC
  value : Double
  lower : value >= -40.0 = True
  upper : value <=  80.0 = True

||| Ultrasonic distance reading in millimetres (HC-SR04 range: 20–4000 mm).
public export
record DistanceMm where
  constructor MkDistanceMm
  value : Double
  lower : value >=   20.0 = True
  upper : value <= 4000.0 = True

-- --------------------------------------------------------------------------
-- Convenience constructors with proof obligations
-- --------------------------------------------------------------------------

||| Smart constructor: build a GpioPin if n <= 39, else Nothing.
public export
mkGpioPin : (n : Nat) -> Maybe GpioPin
mkGpioPin n with (isLTE n 39)
  | Yes prf = Just (MkGpioPin n)
  | No _    = Nothing
