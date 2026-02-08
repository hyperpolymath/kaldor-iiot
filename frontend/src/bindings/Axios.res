// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// FFI bindings for axios

type config = {
  baseURL: string,
  timeout: int,
}

type headers = {mutable \"Authorization": string}

type requestConfig = {headers: headers}

type responseData<'a> = {data: 'a}

type response<'a> = {
  data: responseData<'a>,
  status: int,
}

type errorResponse = {status: int}
type axiosError = {response: Nullable.t<errorResponse>}

type interceptorHandler<'a> = {use: 'a => 'a}
type responseInterceptorError

type interceptors = {
  request: interceptorHandler<requestConfig>,
}

type instance

@module("axios")
external create: config => instance = "create"

@send
external get: (instance, string) => promise<response<'a>> = "get"

@send
external getWithParams: (instance, string, {..}) => promise<response<'a>> = "get"

@send
external post: (instance, string, 'body) => promise<response<'a>> = "post"

@send
external postNoBody: (instance, string) => promise<response<'a>> = "post"

@send
external put: (instance, string, 'body) => promise<response<'a>> = "put"

@send
external delete: (instance, string) => promise<response<'a>> = "delete"

// Interceptor setup via raw JS interop
@send
external addRequestInterceptor: (
  instance,
  @as("interceptors") _,
) => {..} = "get"
