/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSession.h"
#import "FBSession-Private.h"

#import <objc/runtime.h>

#import "FBConfiguration.h"
#import "FBElementCache.h"
#import "FBExceptions.h"
#import "FBMacros.h"
#import "XCUIApplication+AMHelpers.h"

@interface FBSession ()
@property (nonatomic) NSString *testedApplicationBundleId;
@end

@implementation FBSession

static FBSession *_activeSession = nil;

+ (instancetype)activeSession
{
  return _activeSession;
}

+ (void)markSessionActive:(FBSession *)session
{
  [_activeSession kill];
  _activeSession = session;
}

+ (instancetype)sessionWithIdentifier:(NSString *)identifier
{
  if (!identifier) {
    return nil;
  }
  if (![identifier isEqualToString:_activeSession.identifier]) {
    return nil;
  }
  return _activeSession;
}

+ (instancetype)initWithApplication:(XCUIApplication *)application
{
  FBSession *session = [FBSession new];
  session.identifier = [[NSUUID UUID] UUIDString];
  session.testedApplicationBundleId = application.bundleID;
  session.elementCache = [FBElementCache new];
  [FBSession markSessionActive:session];
  return session;
}

- (void)kill
{
  if (nil != self.testedApplicationBundleId) {
    XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:self.testedApplicationBundleId];
    if (app.state > XCUIApplicationStateNotRunning) {
      [app terminate];
    }
  }
  _activeSession = nil;
}

- (XCUIApplication *)currentApplication
{
  if (nil != self.testedApplicationBundleId) {
    XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:self.testedApplicationBundleId];
    if (app.state <= XCUIApplicationStateNotRunning) {
      NSString *description = [NSString stringWithFormat:@"The application under test with bundle id '%@' is not running, possibly crashed", self.testedApplicationBundleId];
      [[NSException exceptionWithName:FBApplicationCrashedException reason:description userInfo:nil] raise];
    }
    return app;
  }
  return [[XCUIApplication alloc] init];
}

- (XCUIApplication *)launchApplicationWithBundleId:(NSString *)bundleIdentifier
                                         arguments:(nullable NSArray<NSString *> *)arguments
                                       environment:(nullable NSDictionary <NSString *, NSString *> *)environment
{
  XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:bundleIdentifier];
  if (app.state <= XCUIApplicationStateNotRunning) {
    app.launchArguments = arguments ?: @[];
    app.launchEnvironment = environment ?: @{};
    [app launch];
  } else {
    [app activate];
  }
  self.testedApplicationBundleId = app.bundleID;
  return app;
}

- (XCUIApplication *)activateApplicationWithBundleId:(NSString *)bundleIdentifier
{
  XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:bundleIdentifier];
  [app activate];
  self.testedApplicationBundleId = app.bundleID;
  return app;
}

- (BOOL)terminateApplicationWithBundleId:(NSString *)bundleIdentifier
{
  XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:bundleIdentifier];
  BOOL result = NO;
  if (app.state > XCUIApplicationStateNotRunning) {
    [app terminate];
    result = YES;
  }
  self.testedApplicationBundleId = nil;
  return result;
}

- (NSUInteger)applicationStateWithBundleId:(NSString *)bundleIdentifier
{
  XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:bundleIdentifier];
  return app.state;
}

@end