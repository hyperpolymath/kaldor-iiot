#!/usr/bin/env julia
# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors
# Kaldor IIoT Analytics Service - Entry Point

# Activate project environment
using Pkg
Pkg.activate(@__DIR__)

# Include and run the analytics module
include("src/Analytics.jl")
Analytics.main()
