import Foundation
import Combine
import RevenueCat

@MainActor
final class RevenueCatService: ObservableObject {

    static let shared = RevenueCatService()

    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var currentOffering: Offering?
    @Published var isPro: Bool = false
    @Published var donationPackage: Package?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    let entitlementID = "premium"

    private let apiKey = "appl_iAKKgmaKcHsKzQkfgwFQKteJbiv"
    private let donationProductID = "donation_2_99"

    var canShowCustomerCenter: Bool {
        isPro || customerInfo?.managementURL != nil
    }

    var managementURL: URL? {
        customerInfo?.managementURL
    }

    private init() {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif

        Purchases.configure(withAPIKey: apiKey)
        RCPurchasesDelegate.shared.service = self
        Purchases.shared.delegate = RCPurchasesDelegate.shared

        Task {
            await refresh()
        }
    }

    func refresh() async {
        await fetchOfferings()
        await refreshCustomerInfo()
    }

    func refreshCustomerInfo() async {
        do {
            apply(customerInfo: try await Purchases.shared.customerInfo())
        } catch {
            errorMessage = userFacingMessage(for: error)
            print("[RevenueCat] refreshCustomerInfo failed: \(error.localizedDescription)")
        }
    }

    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current

            guard let current = offerings.current else {
                donationPackage = nil
                errorMessage = "No active RevenueCat offering is configured yet."
                return
            }

            donationPackage = package(in: current, productIdentifier: donationProductID)
        } catch {
            errorMessage = userFacingMessage(for: error)
            print("[RevenueCat] fetchOfferings failed: \(error.localizedDescription)")
        }
    }

    func purchase(package: Package) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            apply(customerInfo: result.customerInfo)
        } catch {
            if revenueCatErrorCode(for: error) == .purchaseCancelledError {
                return
            }
            errorMessage = userFacingMessage(for: error)
        }
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(customerInfo: info)

            if !isPro {
                errorMessage = "No active purchases were restored for this Apple ID."
            }
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    func apply(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        isPro = customerInfo.entitlements[entitlementID]?.isActive == true
        if isPro {
            errorMessage = nil
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func package(in offering: Offering, productIdentifier: String) -> Package? {
        offering.availablePackages.first { package in
            package.storeProduct.productIdentifier == productIdentifier
        }
    }

    private func revenueCatErrorCode(for error: Error) -> ErrorCode? {
        let nsError = error as NSError
        guard nsError.domain == ErrorCode._nsErrorDomain else { return nil }
        return ErrorCode(rawValue: nsError.code)
    }

    private func userFacingMessage(for error: Error) -> String {
        switch revenueCatErrorCode(for: error) {
        case .configurationError:
            return "RevenueCat is configured incorrectly. Check the API key, products, and entitlement setup."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .purchaseNotAllowedError:
            return "Purchases are not allowed on this device right now."
        case .storeProblemError:
            return "The App Store is currently unavailable. Please try again in a moment."
        case .paymentPendingError:
            return "Your purchase is pending approval."
        case .purchaseCancelledError:
            return ""
        default:
            return error.localizedDescription
        }
    }
}

private final class RCPurchasesDelegate: NSObject, PurchasesDelegate, @unchecked Sendable {
    static let shared = RCPurchasesDelegate()
    weak var service: RevenueCatService?

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in
            self?.service?.apply(customerInfo: customerInfo)
        }
    }
}
