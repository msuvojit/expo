
#import "ABI31_0_0EXFacebook.h"
#import "ABI31_0_0EXNativeAdManager.h"
#import "ABI31_0_0EXNativeAdView.h"
#import "ABI31_0_0EXNativeAdEmitter.h"
#import "ABI31_0_0EXUtil.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <ReactABI31_0_0/ABI31_0_0RCTUtils.h>
#import <ReactABI31_0_0/ABI31_0_0RCTAssert.h>
#import <ReactABI31_0_0/ABI31_0_0RCTBridge.h>
#import <ReactABI31_0_0/ABI31_0_0RCTConvert.h>
#import <ReactABI31_0_0/ABI31_0_0RCTUIManager.h>
#import <ReactABI31_0_0/ABI31_0_0RCTBridgeModule.h>

@implementation ABI31_0_0RCTConvert (ABI31_0_0EXNativeAdView)

ABI31_0_0RCT_ENUM_CONVERTER(FBNativeAdsCachePolicy, (@{
  @"none": @(FBNativeAdsCachePolicyNone),
  @"all": @(FBNativeAdsCachePolicyAll),
}), FBNativeAdsCachePolicyNone, integerValue)

@end

@interface ABI31_0_0EXNativeAdManager () <FBNativeAdsManagerDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString*, FBNativeAdsManager*> *adsManagers;

@end

@implementation ABI31_0_0EXNativeAdManager

ABI31_0_0RCT_EXPORT_MODULE(CTKNativeAdManager)

@synthesize bridge = _bridge;

- (instancetype)init
{
  self = [super init];
  if (self) {
    _adsManagers = [NSMutableDictionary new];
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

ABI31_0_0RCT_EXPORT_METHOD(registerViewsForInteraction:(nonnull NSNumber *)nativeAdViewTag
                            mediaViewTag:(nonnull NSNumber *)mediaViewTag
                            adIconViewTag:(nonnull NSNumber *)adIconViewTag
                            clickableViewsTags:(nonnull NSArray *)tags
                            resolve:(ABI31_0_0RCTPromiseResolveBlock)resolve
                            reject:(ABI31_0_0RCTPromiseRejectBlock)reject)
{
  [_bridge.uiManager addUIBlock:^(ABI31_0_0RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    FBMediaView *mediaView = nil;
    FBAdIconView *adIconView = nil;
    ABI31_0_0EXNativeAdView *nativeAdView = nil;
    
    if ([viewRegistry objectForKey:mediaViewTag] == nil) {
      reject(@"E_NO_VIEW_FOR_TAG", @"Could not find mediaView", nil);
      return;
    }
    
    if ([viewRegistry objectForKey:nativeAdViewTag] == nil) {
      reject(@"E_NO_NATIVEAD_VIEW", @"Could not find nativeAdView", nil);
      return;
    }
    
    if ([[viewRegistry objectForKey:mediaViewTag] isKindOfClass:[FBMediaView class]]) {
      mediaView = (FBMediaView *)[viewRegistry objectForKey:mediaViewTag];
    } else {
      reject(@"E_INVALID_VIEW_CLASS", @"View returned for passed media view tag is not an instance of FBMediaView", nil);
      return;
    }
    
    if ([[viewRegistry objectForKey:nativeAdViewTag] isKindOfClass:[ABI31_0_0EXNativeAdView class]]) {
      nativeAdView = (ABI31_0_0EXNativeAdView *)[viewRegistry objectForKey:nativeAdViewTag];
    } else {
      reject(@"E_INVALID_VIEW_CLASS", @"View returned for passed native ad view tag is not an instance of ABI31_0_0EXNativeAdView", nil);
      return;
    }
    
    if ([viewRegistry objectForKey:adIconViewTag]) {
      if ([[viewRegistry objectForKey:adIconViewTag] isKindOfClass:[FBAdIconView class]]) {
        adIconView  = (FBAdIconView *)[viewRegistry objectForKey:adIconViewTag];
      } else {
        reject(@"E_INVALID_VIEW_CLASS", @"View returned for passed ad icon view tag is not an instance of FBAdIconView", nil);
        return;
      }
    }
    
    NSMutableArray<UIView *> *clickableViews = [NSMutableArray new];
    for (id tag in tags) {
      if ([viewRegistry objectForKey:tag]) {
        [clickableViews addObject:[viewRegistry objectForKey:tag]];
      } else {
        reject(@"E_INVALID_VIEW_TAG", [NSString stringWithFormat:@"Could not find view for tag:  %@", [tag stringValue]], nil);
        return;
      }
    }
    
    [nativeAdView registerViewsForInteraction:mediaView adIcon:adIconView clickableViews:clickableViews];
    resolve(@[]);
  }];
}

ABI31_0_0RCT_EXPORT_METHOD(init:(NSString *)placementId withAdsToRequest:(nonnull NSNumber *)adsToRequest)
{
  if (![ABI31_0_0EXFacebook facebookAppIdFromNSBundle]) {
    ABI31_0_0RCTLogWarn(@"No Facebook app id is specified. Facebook ads may have undefined behavior.");
  }
  FBNativeAdsManager *adsManager = [[FBNativeAdsManager alloc] initWithPlacementID:placementId
                                                                forNumAdsRequested:[adsToRequest intValue]];

  [adsManager setDelegate:self];

  [ABI31_0_0EXUtil performSynchronouslyOnMainThread:^{
    [adsManager loadAds];
  }];

  [_adsManagers setValue:adsManager forKey:placementId];
}

ABI31_0_0RCT_EXPORT_METHOD(setMediaCachePolicy:(NSString*)placementId cachePolicy:(FBNativeAdsCachePolicy)cachePolicy)
{
  [_adsManagers[placementId] setMediaCachePolicy:cachePolicy];
}

ABI31_0_0RCT_EXPORT_METHOD(disableAutoRefresh:(NSString*)placementId)
{
  [_adsManagers[placementId] disableAutoRefresh];
}

- (void)nativeAdsLoaded
{
  NSMutableDictionary<NSString*, NSNumber*> *adsManagersState = [NSMutableDictionary new];

  [_adsManagers enumerateKeysAndObjectsUsingBlock:^(NSString* key, FBNativeAdsManager* adManager, __unused BOOL* stop) {
    [adsManagersState setValue:@([adManager isValid]) forKey:key];
  }];
  
  ABI31_0_0EXNativeAdEmitter *nativeAdEmitter = [_bridge moduleForClass:[ABI31_0_0EXNativeAdEmitter class]];
  [nativeAdEmitter sendManagersState:adsManagersState];
}

- (void)nativeAdsFailedToLoadWithError:(NSError *)errors
{
  // @todo handle errors here
}

- (UIView *)view
{
  return [[ABI31_0_0EXNativeAdView alloc] initWithBridge:_bridge];
}

ABI31_0_0RCT_EXPORT_VIEW_PROPERTY(onAdLoaded, ABI31_0_0RCTBubblingEventBlock)
ABI31_0_0RCT_CUSTOM_VIEW_PROPERTY(adsManager, NSString, ABI31_0_0EXNativeAdView)
{
  view.nativeAd = [_adsManagers[json] nextNativeAd];
}

@end
