//
//  ViewController.m
//  MySatrs
//
//  Created by hfy on 2017/4/1.
//  Copyright © 2017年 hihfy. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"

#import "TFHpple.h"
#import "MyStarsModel.h"

@interface ViewController () <UISearchBarDelegate>
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@property (nonatomic, assign) NSInteger page;

@property (nonatomic, assign) BOOL nextPagedisabled;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.page = 1;
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds);
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
    searchBar.delegate = self;
    searchBar.placeholder = @"输入github用户名";
    searchBar.text = @"hello--world";
    
    self.searchBar = searchBar;
    self.navigationItem.titleView = searchBar;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self fetchHTML];

}

- (NSString *)filePath {
    return [NSString stringWithFormat:@"%@/Documents/stars.html",NSHomeDirectory()];
}

- (NSString *)filePathWith:(NSInteger)page {
    return [NSString stringWithFormat:@"%@/Documents/stars_%@.html",NSHomeDirectory(),@(page)];

}

- (NSString *)mdFilePaht {
    return [NSString stringWithFormat:@"%@/Documents/stars.md",NSHomeDirectory()];
}

- (void)fetchHTML {
    NSString *userName = self.searchBar.text;
    if (userName.length == 0) {
        return;
    }
    
    // 暂时用缓存
//    NSData *data = [NSData dataWithContentsOfFile:[self filePath]];
//    if (data) {
//        NSString *content = @"";
//        NSLog(@"file -->> %@",[self filePath]);
//        
//       NSArray *datas = [self htmlParser:data];
//        for (MyStarsModel *model in datas) {
//            NSString *title = [[model.title componentsSeparatedByString:@"/"] lastObject];
//            content = [NSString stringWithFormat:@"%@[%@-->%@](https://github.com/%@)\n\n",content,title, model.detail,model.title];
//        }
//        NSError *error = nil;
//        
//        [content writeToFile:[self mdFilePaht] atomically:YES encoding:NSUTF8StringEncoding error:&error];
//        if (error) {
//            NSLog(@"write error -->> %@",error);
//        } else {
//            NSLog(@"write succeed");
//        }
//        return;
//    }
    // https://github.com/hello--world?page=1&tab=stars
    NSString *url = [NSString stringWithFormat:@"https://github.com/%@?page=%@&tab=stars",userName, @(self.page)];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSString * userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
    [manager.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    [manager GET:url parameters:nil progress:NULL success:^(NSURLSessionDataTask * _Nonnull task, NSData *responseObject) {
        
        BOOL isSucceed = [responseObject writeToFile:[self filePathWith:self.page] atomically:YES];
        NSLog(@"isSucceed --> %@",@(isSucceed));
        self.page++;
        
        if (self.page < 23) {
            
            [self fetchHTML];
        }
//        [self htmlParser:responseObject];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
}



- (NSMutableArray *)htmlParser:(NSData *)data {
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    NSString *rootXPath = @"//*[@id='js-pjax-container']//div[@class='col-12 d-block width-full py-4 border-bottom']";
    
    NSArray *array = [hpple searchWithXPathQuery:rootXPath];
    NSMutableArray *datas = [NSMutableArray arrayWithCapacity:array.count];
    for (TFHppleElement *element in array) {
        
        NSString *childXPath = @"//h3//a";
        NSArray *titleElements = [element searchWithXPathQuery:childXPath];
        TFHppleElement *firstTitleElement = [titleElements firstObject];
        NSString *title = [firstTitleElement objectForKey:@"href"];
        title = [title stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        childXPath = @"//div[@class='py-1']//p";
        NSArray *detailsElements = [element searchWithXPathQuery:childXPath];
        TFHppleElement *firstDetailsElement = [detailsElements firstObject];
        
        NSString *detail = [firstDetailsElement content];
        detail = [detail stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        
        childXPath = @"//span";
        NSArray *langougesElements = [element searchWithXPathQuery:childXPath];
        TFHppleElement *lastLangougesElements = [langougesElements lastObject];
        
        NSString *langouge = [lastLangougesElements content];
        langouge = [langouge stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        langouge = [langouge stringByReplacingOccurrencesOfString:@" " withString:@""];

        MyStarsModel *model = [MyStarsModel new];
        model.title = title;
        model.detail = detail;
        model.language = langouge;
        [datas addObject:model];
    }
    return datas;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

    [self fetchHTML];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//    [textField endEditing:YES];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
