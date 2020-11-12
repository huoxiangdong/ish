//
//  NSObject+SaneKVO.h
//  iSH
//
//  Created by Theodore Dubois on 11/10/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^KVOBlock)(id, NSDictionary<NSKeyValueChangeKey,id> *);

@interface KVOObservation : NSObject {
    BOOL _enabled;
    __weak id _object;
    NSString *_keyPath;
    KVOBlock _block;
}
- (void)disable;
@end

@interface NSObject (SaneKVO)

- (KVOObservation *)observe:(NSString *)keyPath
                    options:(NSKeyValueObservingOptions)options
                 usingBlock:(KVOBlock)block;
- (void)observe:(NSArray<NSString *> *)keyPaths
        options:(NSKeyValueObservingOptions)options
         target:(id)target
         action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
