//
//  EmulatorVariation.h
//  Mini vMac
//
//  Created by Phil Zakharchenko on 1/31/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EmulatorVariation <NSObject>

- (instancetype)initWithROMAtPath:(NSString *)path;

- (void)start;

- (BOOL)insertDiskAtPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
