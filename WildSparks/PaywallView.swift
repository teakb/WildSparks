import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            SubscriptionStoreView(groupID: "D584D3C3") {
                VStack {
                    Image(systemName: "crown.fill")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    Text("WildSparks Premium")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Unlock unlimited broadcasts and advanced filters!")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .storeButton(.visible, for: .restorePurchases)
            .subscriptionStoreControlStyle(.prominentPicker)
            .containerBackground(.blue.gradient, for: .subscriptionStoreFullHeight)
            .onInAppPurchaseCompletion { _, result in
                if case .success = result {
                    await storeManager.checkSubscriptionStatus()
                    dismiss()
                }
            }

            Button("Close") {
                dismiss()
            }
            .padding()
            .foregroundColor(.red)
        }
        .navigationTitle("Upgrade to Premium")
    }
}
