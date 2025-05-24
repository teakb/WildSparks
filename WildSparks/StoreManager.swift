import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var currentTransaction: Transaction? // Add this to store the current transaction
    private var updatesTask: Task<Void, Never>?

    private let subscriptionGroupID = "D584D3C3" // Updated group ID

    init() {
        updatesTask = Task { await listenForTransactions() }
        Task { await fetchProducts() }
        Task { await checkSubscriptionStatus() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func fetchProducts() async {
        do {
            let products = try await Product.products(for: [subscriptionGroupID])
            if products.isEmpty {
                print("No products fetched for groupID: \(subscriptionGroupID)")
            } else {
                print("Fetched products: \(products.map { $0.id })")
            }
            subscriptions = products.sorted { $0.price < $1.price }
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
            if let skError = error as? SKError {
                print("SKError code: \(skError.code.rawValue)")
            }
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await checkSubscriptionStatus()
                return transaction
            case .unverified:
                throw StoreError.unverifiedTransaction
            }
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.pending
        @unknown default:
            throw StoreError.unknown
        }
    }

    func checkSubscriptionStatus() async {
        isSubscribed = false
        currentTransaction = nil // Reset current transaction
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productType == .autoRenewable && transaction.revocationDate == nil {
                    isSubscribed = true
                    currentTransaction = transaction // Store the current transaction
                    print("User is subscribed: \(transaction.productID)")
                }
            case .unverified:
                print("Unverified transaction")
                continue
            }
        }
        print("Subscription status: \(isSubscribed)")
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                await transaction.finish()
                await checkSubscriptionStatus()
            case .unverified:
                continue
            }
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
}

enum StoreError: Error {
    case unverifiedTransaction
    case userCancelled
    case pending
    case unknown
}
