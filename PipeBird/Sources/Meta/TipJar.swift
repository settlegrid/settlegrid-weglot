// TipJar.swift — UNVERIFIED (Phase D / COULD). StoreKit 2 tip jar. Requires products configured in
// App Store Connect (human-only); gated by FeatureFlags.tipJarEnabled (default OFF). Tips are
// consumables — nothing to unlock, so no entitlement bookkeeping beyond finishing the transaction.

import Foundation
#if canImport(StoreKit)
    import StoreKit

    @MainActor
    final class TipJar: ObservableObject {
        static let productIDs = [
            "ai.settlegrid.pipebird.tip.small",
            "ai.settlegrid.pipebird.tip.medium",
            "ai.settlegrid.pipebird.tip.large"
        ]

        @Published private(set) var products: [Product] = []

        func load() async {
            guard FeatureFlags.tipJarEnabled else { return }
            products = await (try? Product.products(for: Self.productIDs))?
                .sorted { $0.price < $1.price } ?? []
        }

        func purchase(_ product: Product) async {
            guard let result = try? await product.purchase() else { return }
            if case let .success(verification) = result,
               case let .verified(transaction) = verification
            {
                await transaction.finish()
            }
        }
    }
#else
    final class TipJar: ObservableObject {
        @Published private(set) var products: [Never] = []
        func load() async {}
    }
#endif
