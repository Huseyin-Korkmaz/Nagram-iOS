#import <RLottieBinding/LottieInstance.h>

#include "rlottie.h"

#include <cstring>
#include <exception>

@interface LottieInstance () {
    std::unique_ptr<rlottie::Animation> _animation;
}

@end

@implementation LottieInstance

- (instancetype _Nullable)initWithData:(NSData * _Nonnull)data fitzModifier:(LottieFitzModifier)fitzModifier colorReplacements:(NSDictionary * _Nullable)colorReplacements cacheKey:(NSString * _Nonnull)cacheKey {
    self = [super init];
    if (self != nil) {
        rlottie::FitzModifier modifier;
        switch(fitzModifier) {
            case LottieFitzModifierNone:
                modifier = rlottie::FitzModifier::None;
                break;
            case LottieFitzModifierType12:
                modifier = rlottie::FitzModifier::Type12;
                break;
            case LottieFitzModifierType3:
                modifier = rlottie::FitzModifier::Type3;
                break;
            case LottieFitzModifierType4:
                modifier = rlottie::FitzModifier::Type4;
                break;
            case LottieFitzModifierType5:
                modifier = rlottie::FitzModifier::Type5;
                break;
            case LottieFitzModifierType6:
                modifier = rlottie::FitzModifier::Type6;
                break;
        }
        
        std::vector<std::pair<std::uint32_t, std::uint32_t>> colorsVector;
        if (colorReplacements != nil) {
            for (NSNumber *color in colorReplacements.allKeys) {
                NSNumber *replacement = colorReplacements[color];
                colorsVector.push_back({ color.unsignedIntValue, replacement.unsignedIntValue });
            }
        }
        
        _animation = rlottie::Animation::loadFromData(std::string(reinterpret_cast<const char *>(data.bytes), data.length), std::string([cacheKey UTF8String]), "", cacheKey.length != 0, colorsVector, modifier);
        if (_animation == nullptr) {
            return nil;
        }
        
        _frameCount = (int32_t)_animation->totalFrame();
        _frameCount = MAX(1, _frameCount);
        _frameRate = (int32_t)_animation->frameRate();
        _frameRate = MAX(1, _frameRate);
        
        size_t width = 0;
        size_t height = 0;
        _animation->size(width, height);
        
        if (width > 1536 || height > 1536) {
            return nil;
        }
        
        width = MAX(1, width);
        height = MAX(1, height);
        
        _dimensions = CGSizeMake(width, height);
        
        if ((_frameRate > 360) || _animation->duration() > 9.0) {
            return nil;
        }
    }
    return self;
}

- (void)renderFrameWithIndex:(int32_t)index into:(uint8_t * _Nonnull)buffer width:(int32_t)width height:(int32_t)height bytesPerRow:(int32_t) bytesPerRow{
    rlottie::Surface surface((uint32_t *)buffer, width, height, bytesPerRow);
    // MARK: NAGRAM
    // rlottie sizes its path buffers from animation data (polystar/polygon point counts go straight into
    // VPath::reserve), so a malformed animation makes std::vector throw std::length_error. Nothing above this
    // frame can catch a C++ exception, so it used to terminate the app from the render queue; a frame that
    // cannot be rendered is delivered fully transparent instead.
    try {
        _animation->renderSync(index, surface);
    } catch (const std::exception &exception) {
        NSLog(@"LottieInstance: failed to render frame %d: %s", index, exception.what());
        if (buffer != nullptr && height > 0 && bytesPerRow > 0) {
            memset(buffer, 0, (size_t)height * (size_t)bytesPerRow);
        }
    }
}

@end
