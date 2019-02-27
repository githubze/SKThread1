//
//  ViewController.m
//  Thread
//
//  Created by 徐泽 on 2019/2/20.
//  Copyright © 2019 aze. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //GCD
    //后台执行(通常意义的理解为开分线程)
    [self GCD1];
    
    //UI线程（通常说的主线程）执行(只是为了测试,长时间的加载不能放在主线程)
    [self GCD2];
    
    //一次性执行(常用来写单例，程序执行该代码部分只会被创建一次)
    [self GCD3];
    
    //如根据若干个url异步加载多张图片，然后在都下载完成后合成一张整图
    [self GCD4];
    
    //dispatch_barrier_async（栅栏函数）
    [self GCD5];
    
    //主线程死锁
    [self GCD6];
    
    //并发地执行循环迭代，该方法根据程序运行，不指定在主线程或分线程中
    [self GCD7];
    
    // 延迟执行
    [self GCD8];
    
    //异步缓存图片中途退出
    [self GCD9];
    
    //线程加锁
    [self GCD10];
    
    //动态创建线程
    [self NSThread1];
    
    //静态创建线程
    [self NSThread2];
    
    //隐式创建线程
    [self NSThread3];
    
    //更多基本用法
    [self NSThread4];
    
    //使用子类NSInvocationOperation
    [self NSOperation1];
    
    //使用子类NSBlockOperation
    [self NSOperation2];
    
    
}
- (void)NSOperation2{
    NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
        //执行操作1
    }];
    
    NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
        //执行操作2
    }];
    
    NSBlockOperation *operation3 = [NSBlockOperation blockOperationWithBlock:^{
        //执行操作3
    }];
    
    //前者依赖后者执行
    [operation2 addDependency:operation1];
    [operation3 addDependency:operation2];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation1];
    [queue addOperation:operation2];
    [queue addOperation:operation3];
    
    //控制同时最大并发的线程数量
    [queue setMaxConcurrentOperationCount:2];
}
- (void)NSOperation1{
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadImageSource:) object:nil];
    //直接在主线程中执行
    [operation start];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
    
}
- (void)NSThread4{
    NSThread *current = [NSThread currentThread];  //获取当前线程
    
    NSThread*main = [NSThread mainThread];    //获取主线程
    
    [NSThread sleepForTimeInterval:2];  //暂停等待线程，也就是我们通常所说的延迟执行2秒
    
    //在指定线程上执行操作
    
    [self performSelector:@selector(run) onThread:main withObject:nil waitUntilDone:YES];
    
    //在主线程上执行操作
    
    [self performSelectorOnMainThread:@selector(run) withObject:nil waitUntilDone:YES];
    
    //在当前线程执行操作
    
    [self performSelector:@selector(run) withObject:nil];
}
- (void)NSThread3{
    [self performSelectorInBackground:@selector(loadImageSource:) withObject:nil];
}
- (void)NSThread2{
    [NSThread detachNewThreadWithBlock:^{
        
    }];
    [NSThread detachNewThreadSelector:@selector(loadImageSource:) toTarget:self withObject:nil];
}
- (void)NSThread1{
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadImageSource:) object:nil];
    // 设置线程的优先级(0.0 - 1.0，1.0最高级)
    thread.threadPriority = 1;
    [thread start];
}
- (void)GCD10{
    NSLock * lock = [NSLock new];
    for (int i=0; i<10; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [lock lock];
            NSLog(@"%d",i);
            [lock unlock];
        });
    }
}
- (void)GCD9{
    dispatch_group_t group = dispatch_group_create();
    
    /*
    for(int i=0;i<10;i++){
        
        //进入组
        
        dispatch_group_enter(group);
        
        NSArray*imageArray = [self getImageUrl];
        
        [[SDWebImageManager sharedManager].imageDownloader downloadImageWithURL:[NSURL URLWithString:imageArray[i]] options:SDWebImageDownloaderLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
        
        
        }completed:^(UIImage*_Nullableimage,NSData*_Nullabledata,NSError*_Nullableerror,BOOLfinished) {
        
        NSLog(@"正在缓存第%d张",i+1);
        
        //离开组
        
        dispatch_group_leave(group);
        
    }];
     */
        
        //通知缓存完成
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            
            NSLog(@"缓存完成");
            
        });
}
- (void)GCD8{
     double delayInSeconds =2.0;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds*NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        //2s后执行
    });
}
- (void)GCD7{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    size_t count = 10;
    dispatch_apply(count, queue, ^(size_t i) {
        NSLog(@"循环执行第%li次",i);
    });
}
- (void)GCD6{
    NSLog(@"1");
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"2");
    });
    NSLog(@"3");
    //结果输出1,主线程死锁(主线程和主队列相互等待)
}
- (void)GCD5{
    //dispatch_barrier_async（栅栏函数）
    /*
    1.在它前面的任务执行结束后它才执行，它后面的任务要等它执行完成后才会开始执行。
    2.避免数据竞争
     */
    
    //创建并发队列
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"任务1---%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务2---%@",[NSThread currentThread]);
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"任务3---%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务4---%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务5---%@",[NSThread currentThread]);
    });
}
- (void)GCD4{
    //如根据若干个url异步加载多张图片，然后在都下载完成后合成一张整图
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_async(group, queue, ^{
        //加载图片1
        
    });
    
    dispatch_group_async(group, queue, ^{
        //加载图片2
        
    });
    
    dispatch_group_async(group, queue, ^{
        //加载图片3
        
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        //合成图片

    });
    
    //或者
    
    dispatch_async(queue, ^{
        dispatch_group_t group = dispatch_group_create();
        
        dispatch_group_async(group, queue, ^{
            //加载图片1
        });
        
        dispatch_group_async(group, queue, ^{
            //加载图片2
        });
        
        dispatch_group_async(group, queue, ^{
            //加载图片3
        });
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        //合成图片
        
    });
}

- (void)GCD3{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        //执行操作
    });
}
- (void)GCD2{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //执行操作
        
    });
}
- (void)GCD1{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //执行操作
        
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       //并发执行操作1
       //并发执行操作2
    });
    
    //自定义队列
    dispatch_queue_t urls_queue =dispatch_queue_create("minggo.app.com",NULL);
    
    dispatch_async(urls_queue, ^{
        //执行操作
    });
}



@end
