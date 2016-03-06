//
//  DownloadTableViewController.h
//  HelloTako
//
//  Created by 熊海涛 on 16/3/5.
//  Copyright © 2016年 熊海涛. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableViewCell.h"
#import "App.h"

@interface DownloadTableViewController : UIViewController

@property UIRefreshControl* refreshControl;
@property NSString* cursor;
@property TableViewCell* currentCell;
@property TakoApp* currentApp;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property NSMutableArray* listData;

-(void)showPasswordConfirm;
-(void)receiveClickDownloadNotification:(NSNotification*)notice;
-(void)receiveCancelDownloadNotification:(NSNotification*)notice;
-(void)downloadApp;
-(void)hideProgressUI:(BOOL)isShow cell:(TableViewCell*)cell;

@end




@interface DownloadHistoryInfo : NSObject
@property (nonatomic,copy) NSString* currentLength;
@property (nonatomic,copy) NSString* TotalLength;
@property (nonatomic,copy) NSString* status;
@property (nonatomic,copy) NSString* appid;
@property (nonatomic,copy) NSString* password;
@end
