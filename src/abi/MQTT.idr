-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- MQTT.idr — MQTT client ABI contract.
--
-- Implementation: ffi/zig/src/esp_idf_mqtt.zig (wraps ESP-IDF esp_mqtt_client).

module KaldorBBW.ABI.MQTT

import KaldorBBW.ABI.Types

%default total

-- --------------------------------------------------------------------------
-- MQTT interface
-- --------------------------------------------------------------------------

||| Contract for MQTT operations.
|||
||| @m  the effect monad (IO on the device, test monad in simulation)
public export
interface MqttABI (0 m : Type -> Type) where

  ||| Initiate a connection to the configured broker.  Returns True on success.
  connect    : m Bool

  ||| Return True if the client is currently connected.
  isConnected : m Bool

  ||| Subscribe to a topic.  The MqttTopic proof guarantees valid length.
  subscribe  : MqttTopic -> m Bool

  ||| Publish a message.
  ||| @topic    valid MQTT topic (1–256 bytes)
  ||| @payload  message payload (any bytes, including empty)
  ||| @qos      delivery guarantee level
  ||| @retain   whether the broker should retain the message
  publish    : MqttTopic -> List Bits8 -> MqttQos -> Bool -> m Bool

  ||| Poll for one pending received message.  Returns Nothing if queue empty.
  poll       : m (Maybe (MqttTopic, List Bits8))

-- --------------------------------------------------------------------------
-- Proof-bearing combinators
-- --------------------------------------------------------------------------

||| Proof: QoS 0 (fire-and-forget) is always a valid QoS choice.
public export
defaultQos : MqttQos
defaultQos = QosAtMostOnce

||| Proof: the topic-length bound is preserved through the ABI.
||| If @t : MqttTopic then @t.bounded witnesses len(t.bytes) <= 256.
public export
topicBoundIntact : (t : MqttTopic) -> LTE (length t.bytes) 256
topicBoundIntact t = t.bounded

||| Convenience: publish a telemetry value using QoS 0, non-retained.
public export
publishTelemetry : MqttABI m => Monad m =>
                   MqttTopic -> List Bits8 -> m Bool
publishTelemetry topic payload =
  publish topic payload QosAtMostOnce False
