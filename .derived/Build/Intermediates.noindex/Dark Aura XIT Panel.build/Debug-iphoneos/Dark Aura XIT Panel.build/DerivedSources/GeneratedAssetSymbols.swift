import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "AuraProPreview" asset catalog image resource.
    static let auraProPreview = DeveloperToolsSupport.ImageResource(name: "AuraProPreview", bundle: resourceBundle)

    /// The "DefaultIconPreview" asset catalog image resource.
    static let defaultIconPreview = DeveloperToolsSupport.ImageResource(name: "DefaultIconPreview", bundle: resourceBundle)

    /// The "Icon1Preview" asset catalog image resource.
    static let icon1Preview = DeveloperToolsSupport.ImageResource(name: "Icon1Preview", bundle: resourceBundle)

    /// The "Icon2Preview" asset catalog image resource.
    static let icon2Preview = DeveloperToolsSupport.ImageResource(name: "Icon2Preview", bundle: resourceBundle)

    /// The "Icon3Preview" asset catalog image resource.
    static let icon3Preview = DeveloperToolsSupport.ImageResource(name: "Icon3Preview", bundle: resourceBundle)

    /// The "Icon4Preview" asset catalog image resource.
    static let icon4Preview = DeveloperToolsSupport.ImageResource(name: "Icon4Preview", bundle: resourceBundle)

    /// The "Icon5Preview" asset catalog image resource.
    static let icon5Preview = DeveloperToolsSupport.ImageResource(name: "Icon5Preview", bundle: resourceBundle)

    /// The "floaticon" asset catalog image resource.
    static let floaticon = DeveloperToolsSupport.ImageResource(name: "floaticon", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "AuraProPreview" asset catalog image.
    static var auraProPreview: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .auraProPreview)
#else
        .init()
#endif
    }

    /// The "DefaultIconPreview" asset catalog image.
    static var defaultIconPreview: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .defaultIconPreview)
#else
        .init()
#endif
    }

    /// The "Icon1Preview" asset catalog image.
    static var icon1Preview: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icon1Preview)
#else
        .init()
#endif
    }

    /// The "Icon2Preview" asset catalog image.
    static var icon2Preview: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icon2Preview)
#else
        .init()
#endif
    }

    /// The "Icon3Preview" asset catalog image.
    static var icon3Preview: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icon3Preview)
#else
        .init()
#endif
    }

    /// The "Icon4Preview" asset catalog image.
    static var icon4Preview: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icon4Preview)
#else
        .init()
#endif
    }

    /// The "Icon5Preview" asset catalog image.
    static var icon5Preview: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icon5Preview)
#else
        .init()
#endif
    }

    /// The "floaticon" asset catalog image.
    static var floaticon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .floaticon)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "AuraProPreview" asset catalog image.
    static var auraProPreview: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .auraProPreview)
#else
        .init()
#endif
    }

    /// The "DefaultIconPreview" asset catalog image.
    static var defaultIconPreview: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .defaultIconPreview)
#else
        .init()
#endif
    }

    /// The "Icon1Preview" asset catalog image.
    static var icon1Preview: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icon1Preview)
#else
        .init()
#endif
    }

    /// The "Icon2Preview" asset catalog image.
    static var icon2Preview: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icon2Preview)
#else
        .init()
#endif
    }

    /// The "Icon3Preview" asset catalog image.
    static var icon3Preview: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icon3Preview)
#else
        .init()
#endif
    }

    /// The "Icon4Preview" asset catalog image.
    static var icon4Preview: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icon4Preview)
#else
        .init()
#endif
    }

    /// The "Icon5Preview" asset catalog image.
    static var icon5Preview: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icon5Preview)
#else
        .init()
#endif
    }

    /// The "floaticon" asset catalog image.
    static var floaticon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .floaticon)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

