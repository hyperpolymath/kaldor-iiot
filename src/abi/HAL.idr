-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- HAL.idr — Hardware Abstraction Layer ABI contract.
--
-- Defines the interface that both the freestanding ESP32 implementation
-- (ffi/zig/src/esp_idf_hal.zig) and the simulation implementation
-- (firmware-zig/src/hal.zig) must satisfy.

module KaldorBBW.ABI.HAL

import KaldorBBW.ABI.Types

%default total

-- --------------------------------------------------------------------------
-- HAL interface
-- --------------------------------------------------------------------------

||| Contract for the hardware abstraction layer.
|||
||| All effectful operations live in some monad @m.  The actual
||| implementations are in Zig (host simulation or ESP-IDF on device).
public export
interface HalABI (0 m : Type -> Type) where

  -- Time
  ||| Current time in milliseconds since boot.
  timerGetMs : m Nat
  ||| Suspend execution for @ms milliseconds.
  delayMs    : Nat -> m ()

  -- GPIO — return False if the pin index is out of range (> 39)
  ||| Configure pin as push-pull output.
  gpioSetOut : GpioPin -> m Bool
  ||| Configure pin as input (floating).
  gpioSetIn  : GpioPin -> m Bool
  ||| Write a digital level to a pin.
  gpioWrite  : GpioPin -> Bool -> m Bool
  ||| Read the current digital level of a pin.
  gpioRead   : GpioPin -> m Bool

  -- UART
  ||| Write raw bytes to UART0 (debug / log output).
  uartPrint  : List Bits8 -> m ()

  -- System
  ||| Read the unique chip identifier from the eFuse MAC address.
  chipId     : m Bits32
  ||| Return the current size of the free heap in bytes.
  freeHeap   : m Nat
  ||| Hard restart the microcontroller.  Does not return.
  restart    : m Void

-- --------------------------------------------------------------------------
-- Derived proofs and combinators
-- --------------------------------------------------------------------------

||| Pin 0 satisfies the GpioPin constraint.
public export
pin0 : GpioPin
pin0 = MkGpioPin 0

||| Pin 39 satisfies the GpioPin constraint (boundary value).
public export
pin39 : GpioPin
pin39 = MkGpioPin 39

||| Convenience: toggle a GPIO pin (read then write the complement).
public export
gpioToggle : HalABI m => Monad m => GpioPin -> m Bool
gpioToggle pin = do
  level <- gpioRead pin
  gpioWrite pin (not level)
