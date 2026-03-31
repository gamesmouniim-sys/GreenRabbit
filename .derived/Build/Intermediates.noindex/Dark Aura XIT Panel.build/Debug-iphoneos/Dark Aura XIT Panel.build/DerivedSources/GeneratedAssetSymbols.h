#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "AuraProPreview" asset catalog image resource.
static NSString * const ACImageNameAuraProPreview AC_SWIFT_PRIVATE = @"AuraProPreview";

/// The "DefaultIconPreview" asset catalog image resource.
static NSString * const ACImageNameDefaultIconPreview AC_SWIFT_PRIVATE = @"DefaultIconPreview";

/// The "Icon1Preview" asset catalog image resource.
static NSString * const ACImageNameIcon1Preview AC_SWIFT_PRIVATE = @"Icon1Preview";

/// The "Icon2Preview" asset catalog image resource.
static NSString * const ACImageNameIcon2Preview AC_SWIFT_PRIVATE = @"Icon2Preview";

/// The "Icon3Preview" asset catalog image resource.
static NSString * const ACImageNameIcon3Preview AC_SWIFT_PRIVATE = @"Icon3Preview";

/// The "Icon4Preview" asset catalog image resource.
static NSString * const ACImageNameIcon4Preview AC_SWIFT_PRIVATE = @"Icon4Preview";

/// The "Icon5Preview" asset catalog image resource.
static NSString * const ACImageNameIcon5Preview AC_SWIFT_PRIVATE = @"Icon5Preview";

/// The "floaticon" asset catalog image resource.
static NSString * const ACImageNameFloaticon AC_SWIFT_PRIVATE = @"floaticon";

#undef AC_SWIFT_PRIVATE
