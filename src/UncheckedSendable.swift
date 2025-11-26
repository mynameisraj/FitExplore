// Copyright © 2025 Raj Ramamurthy.

/// Unsafely wraps a non-Sendable value for use in contexts requiring Sendable.
@propertyWrapper
struct UncheckedSendable<Value>: @unchecked Sendable {
  var wrappedValue: Value
}
