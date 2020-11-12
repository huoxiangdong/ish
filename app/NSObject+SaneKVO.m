//
//  NSObject+SaneKVO.m
//  iSH
//
//  Created by Theodore Dubois on 11/10/20.
//

#import <objc/runtime.h>
#import "NSObject+SaneKVO.h"

static void *kKVOObservations = &kKVOObservations;

@interface KVOObservation ()
- (instancetype)initWithKeyPath:(NSString *)keyPath object:(id)object block:(KVOBlock)block;
@end

@implementation NSObject (SaneKVO)

- (KVOObservation *)observe:(NSString *)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(void (^)(id _Nonnull, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull))block {
    KVOObservation *observation = [[KVOObservation alloc] initWithKeyPath:keyPath object:self block:block];
    [self addObserver:observation forKeyPath:keyPath options:options context:NULL];
    return observation;
}

- (void)observe:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options target:(id)target action:(SEL)action {
    @synchronized (target) {
        __weak id weakTarget = target;
        for (NSString *keyPath in keyPaths) {
            KVOBlock block = ^(id object, NSDictionary<NSKeyValueChangeKey,id> *change) {
                id target = weakTarget;
                if (target) {
                    // This is to silence the warning about how performSelector may cause a leak if the method you're calling returns an object
                    ((void (*)(id, SEL)) [target methodForSelector:action])(target, action);
                }
            };
            NSMutableSet *observations = objc_getAssociatedObject(target, kKVOObservations);
            if (observations == nil) {
                observations = [NSMutableSet new];
                objc_setAssociatedObject(target, kKVOObservations, observations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            [observations addObject:[self observe:keyPath options:options usingBlock:block]];
        }
    }
}

@end

@implementation KVOObservation

- (instancetype)initWithKeyPath:(NSString *)keyPath object:(id)object block:(KVOBlock)block {
    if (self = [super init]) {
        _keyPath = keyPath;
        _object = object;
        _block = block;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    _block(object, change);
}

- (void)disable {
    if (_enabled) {
        [_object removeObserver:self forKeyPath:_keyPath context:NULL];
        _enabled = NO;
    }
}
- (void)dealloc {
    [self disable];
}

@end
