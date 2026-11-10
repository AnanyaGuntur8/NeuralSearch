#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PKSearchHit : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSString *snippet;
@property (nonatomic, assign, readonly) double score;
- (instancetype)initWithTitle:(NSString *)title
                          path:(NSString *)path
                       snippet:(NSString *)snippet
                         score:(double)score;
@end

@interface PKSearchIndex : NSObject
- (void)removeAllDocuments;
- (void)addDocumentWithTitle:(NSString *)title
                        path:(NSString *)path
                     snippet:(NSString *)snippet
                      vector:(NSArray<NSNumber *> *)vector;
- (NSArray<PKSearchHit *> *)searchWithVector:(NSArray<NSNumber *> *)vector limit:(NSInteger)limit;
@property (nonatomic, readonly) NSInteger documentCount;
@end

NS_ASSUME_NONNULL_END
