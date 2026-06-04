// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
/**
 * Kaldor IIoT - MQTT Handler
 */

#ifndef MQTT_HANDLER_H
#define MQTT_HANDLER_H

#include <Arduino.h>
#include <PubSubClient.h>

// Forward declaration
void mqttCallback(char* topic, byte* payload, unsigned int length);

#endif // MQTT_HANDLER_H
