#import "PKSearchIndex.h"
#import <math.h>

@interface PKSearchHit ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic, copy, readwrite) NSString *snippet;
@property (nonatomic, assign, readwrite) double score;
@end

@implementation PKSearchHit
- (instancetype)initWithTitle:(NSString *)title path:(NSString *)path snippet:(NSString *)snippet score:(double)score {
    if ((self = [super init])) {
        _title = [title copy]; _path = [path copy]; _snippet = [snippet copy]; _score = score;
    }
    return self;
}
@end

@interface PKIndexedDocument : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *snippet;
@property (nonatomic, copy) NSArray<NSNumber *> *vector;
@end
@implementation PKIndexedDocument
@end

@interface PKSearchIndex ()
@property (nonatomic, strong) NSMutableArray<PKIndexedDocument *> *documents;
@end

@implementation PKSearchIndex
- (instancetype)init {
    if ((self = [super init])) { _documents = [NSMutableArray array]; }
    return self;
}
- (NSInteger)documentCount { return self.documents.count; }
- (void)removeAllDocuments { [self.documents removeAllObjects]; }
- (void)addDocumentWithTitle:(NSString *)title path:(NSString *)path snippet:(NSString *)snippet vector:(NSArray<NSNumber *> *)vector {
    PKIndexedDocument *document = [[PKIndexedDocument alloc] init];
    document.title = title; document.path = path; document.snippet = snippet; document.vector = vector;
    [self.documents addObject:document];
}
- (NSArray<PKSearchHit *> *)searchWithVector:(NSArray<NSNumber *> *)query limit:(NSInteger)limit {
    NSMutableArray<PKSearchHit *> *results = [NSMutableArray array];
    for (PKIndexedDocument *document in self.documents) {
        NSArray<NSNumber *> *candidate = document.vector;
        if (query.count == 0 || query.count != candidate.count) { continue; }
        double dot = 0, qNorm = 0, cNorm = 0;
        for (NSUInteger i = 0; i < query.count; i++) {
            double q = query[i].doubleValue, c = candidate[i].doubleValue;
            dot += q * c; qNorm += q * q; cNorm += c * c;
        }
        double similarity = qNorm > 0 && cNorm > 0 ? dot / (sqrt(qNorm) * sqrt(cNorm)) : 0;
        [results addObject:[[PKSearchHit alloc] initWithTitle:document.title path:document.path snippet:document.snippet score:similarity]];
    }
    [results sortUsingComparator:^NSComparisonResult(PKSearchHit *a, PKSearchHit *b) {
        if (a.score > b.score) return NSOrderedAscending;
        if (a.score < b.score) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    if (limit > 0 && results.count > (NSUInteger)limit) {
        return [results subarrayWithRange:NSMakeRange(0, (NSUInteger)limit)];
    }
    return results;
}
@end
