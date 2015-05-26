//
//  TRYHomeViewController.m
//  LoginTabbedApp
//
//  Created by shruti gupta on 24/06/14.
//  Copyright (c) 2014 Shruti Gupta. All rights reserved.
//

#import "TRYHomeViewController.h"
#import "TRYSetupScreenViewController.h"
#import "TRYItemStore.h"
#import "TRYModel.h"


@interface TRYHomeViewController ()
@property (strong, nonatomic) IBOutlet UILabel *labelDate;
@property (strong, nonatomic) IBOutlet UIImageView *background;
@property (strong, nonatomic) IBOutlet UIButton *buttonNo;
- (IBAction)medNoAction:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *buttonYes;
- (IBAction)medYesAction:(id)sender;

@property(strong,nonatomic)NSDate *savedDate;
@property(strong,nonatomic)NSDate *nextReminderDate;
@property(strong,nonatomic)NSUserDefaults *preferences;
@property NSInteger missedCount;
@property NSInteger takenCount;
@property NSInteger notTakenCount;
@property NSInteger flag;
@property NSTimer *timer;
@property (assign, nonatomic) NSInteger index;
@property (strong, nonatomic) IBOutlet UILabel *screenNumber;

@end

@implementation TRYHomeViewController

NSString *const prefReminderTime1 = @"reminderTimeFinal";
NSString *const prefReminderTime2 = @"reminderTimeFinal1";
NSString *const prefmedLastTaken = @"medLastTaken";
NSString *const prefhasSetUp = @"hasSetUp";
NSString *const prefDosesInARow = @"dosesInARow";
NSInteger medTaken ;
NSInteger frequency;
//medTaken = 0 no action = 1 taken = -1 not taken
NSString *medName;
NSInteger   dosesInARow=0;
bool visited = false;
bool dateChanged = false;
NSDate *medLastTaken;
TRYModel *currentModelObject;
int const STATUS_TAKEN = 1;
int const STATUS_MISSED = 0;
int const STATUS_NOT_TAKEN = -1;

-(id)init
{
    self = [super init];
    if (!self) return nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSignificantTimeChange:)
                                                 name:UIApplicationSignificantTimeChangeNotification
                                               object:nil];
     return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background1.png"]];
    _flag =0;
   
}
- (void) viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:true];
     [self updation];
}
- (void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIApplicationSignificantTimeChangeNotification
                                               object:nil];
}
-(void) updation
{
    _preferences = [NSUserDefaults standardUserDefaults];
    BOOL hasSetUp = [_preferences boolForKey:prefhasSetUp];
    if(hasSetUp)
    {
        
        //Update saved date if required
        //Initially saved Date = date when setup screen was created
         _savedDate = [(NSDate*)[_preferences objectForKey:prefReminderTime1] dateByAddingTimeInterval:0];
        _nextReminderDate =[(NSDate*)[_preferences objectForKey:prefReminderTime2] dateByAddingTimeInterval:0];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"dd/MM/yyyy"];
       
        //today < saved date => do nothing
        NSInteger dateCompare = [self compareDates:[NSDate date] :_savedDate];
        if(dateCompare == -1)
        {
            [_buttonYes setEnabled:NO];
            [_buttonNo setEnabled:NO];
            [dateFormat setDateFormat:@"dd/MM/yyyy"];
            [_labelDate setText:[dateFormat stringFromDate:_savedDate]];
            [dateFormat setDateFormat:@"EEEE"];
            [_labelDay setText:[dateFormat stringFromDate:_savedDate]];
            [self syncUserDefaults];
            
        }
        //if today == saved date
       
        else if(dateCompare == 0)
        {
            [_buttonYes setEnabled:YES];
            [_buttonNo setEnabled:YES];
            if(_flag == 0 && !visited)
            {
            visited = true;
            _nextReminderDate = (NSDate*)[[self getNextReminderDate] dateByAddingTimeInterval:0];
            [self syncUserDefaults];
            }
            
            else if(_flag==1 )
                _flag=0;
        }
        
        else
        {
            
            NSInteger dateCompareNext;
            dateCompareNext = [self compareDates:[NSDate date] :_nextReminderDate];
            //today < nextDate not possible for daily
            //today < nextDate for weekly => missed count = missed count + 1, change color of label to red
            if (dateCompareNext == -1) {
                if ((NSInteger)[_preferences integerForKey:@"medFrequency"] == 7) {
                    [_labelDay setTextColor:[UIColor redColor]];
                    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:prefDosesInARow];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                }
            }
            
            //today > nextDate => missed count = (today - nextDate), nextdate = today, saved date = next date
            if(dateCompareNext == 1)
            {
                
                [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:prefDosesInARow];
                [[NSUserDefaults standardUserDefaults] synchronize];
                visited = false;
                _flag = 1;
                bool weekly = [_preferences integerForKey:@"medFrequency"] == (NSInteger)7;
                bool daily =  [_preferences integerForKey:@"medFrequency"] == (NSInteger)1;
                if(daily){
                _nextReminderDate = [NSDate date];
                [self syncUserDefaults];
                    }
                if (weekly) {
                    [_labelDay setTextColor:[UIColor redColor]];
                }
                _savedDate = (NSDate*)[_nextReminderDate dateByAddingTimeInterval:0];
                _nextReminderDate = (NSDate*)[[self getNextReminderDate] dateByAddingTimeInterval:0];
               [self syncUserDefaults];
            }
            
            else if(dateCompareNext == 0)
            {
                [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:prefDosesInARow];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [_labelDay setTextColor:[UIColor blackColor]];
                [_buttonYes setEnabled:YES];
                [_buttonNo setEnabled:YES];
                medLastTaken = [NSDate date];
                _savedDate = _nextReminderDate;
                [self syncUserDefaults];
                [self changeLabel];
                dateChanged = false;
             }
          }
        //today == saved date => alarm
        [self changeLabel];
        [self syncUserDefaults];
        }
}
- (IBAction)setupScreenAction:(id)sender {
  
    TRYSetupScreenViewController *loginVC = [[TRYSetupScreenViewController alloc] init];
    [self.view.window.rootViewController presentViewController:loginVC animated:YES completion:nil];
    
}
- (IBAction)medNoAction:(id)sender {
    [currentModelObject setMedStatus:STATUS_NOT_TAKEN];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:prefDosesInARow];
    
  }
- (IBAction)medYesAction:(id)sender {
    
    visited = false;
    dosesInARow = (NSInteger)[_preferences integerForKey:prefDosesInARow];
    dosesInARow=dosesInARow+1;
    [[NSUserDefaults standardUserDefaults] setInteger:dosesInARow forKey:prefDosesInARow];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _savedDate = _nextReminderDate;
    medLastTaken = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:medLastTaken forKey:prefmedLastTaken];
    [[NSUserDefaults standardUserDefaults] synchronize];
   [self syncUserDefaults];
   [currentModelObject setMedStatus:STATUS_TAKEN];
   [self changeLabel];
   [self createNotification];
   [_buttonYes setEnabled:NO];
   [_buttonNo setEnabled:NO];
   [_labelDay setTextColor:[UIColor blackColor]];
 
}

-(void) createNotification
{
    bool weekly = [_preferences integerForKey:@"medFrequency"] == (NSInteger)7;
    bool daily =  [_preferences integerForKey:@"medFrequency"] == (NSInteger)1;
    NSDate *currentTime = (NSDate*)[_preferences valueForKey:@"reminderTime"];
    if (weekly)
        currentTime = [currentTime dateByAddingTimeInterval:+7*24*60*60];
    else if (daily)
        currentTime = [currentTime dateByAddingTimeInterval:+1*24*60*60];
    
    [_preferences setObject:currentTime forKey:@"remiderTime"];
    [_preferences synchronize];
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = currentTime;
    localNotification.alertBody = @"Time to take your medicine";
    localNotification.alertAction = @"Show me the item";
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
}

-(void) changeLabel
{
    NSString *oldDateLabel = [_labelDate text];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MM/yyyy"];
    [_labelDate setText:[dateFormat stringFromDate:_savedDate]];
    [dateFormat setDateFormat:@"EEEE"];
    [_labelDay setText:[dateFormat stringFromDate:_savedDate]];
    NSString *newDateLabel = [_labelDate text];
    if(![oldDateLabel isEqualToString:newDateLabel])
    {
        //Date changed
        currentModelObject = [[TRYItemStore sharedStore]createItem:_savedDate];
    }
}
- (void)onSignificantTimeChange:(NSNotification *)notification {
    [_labelDate setText:@"Date changed"];
    dateChanged = true;
    [self updation];
}

    -(NSDate*)getNextReminderDate
{
    
    bool weekly = [_preferences integerForKey:@"medFrequency"] == (NSInteger)7;
    bool daily =  [_preferences integerForKey:@"medFrequency"] == (NSInteger)1;
    _nextReminderDate= [(NSDate*)[_preferences objectForKey:prefReminderTime2] dateByAddingTimeInterval:0];
    if (daily)
        _nextReminderDate = [_nextReminderDate dateByAddingTimeInterval:+1*24*60*60];
    if (weekly)
        _nextReminderDate = [_nextReminderDate dateByAddingTimeInterval:+7*24*60*60];
    [self syncUserDefaults];
    return _nextReminderDate ;
}

-(void) syncUserDefaults
{
    [[NSUserDefaults standardUserDefaults] setObject:_nextReminderDate forKey:prefReminderTime2];
    [[NSUserDefaults standardUserDefaults] setObject:_savedDate forKey:prefReminderTime1];
    
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}
-(NSInteger) compareDates:(NSDate*)date1
                         :(NSDate*)date2
{
    
    //date1<date2 = -1 ; date1 == date2 = 0 ; date1 > date2 = 1
    NSDateComponents *components1 = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date1];
    
    NSInteger day1 = [components1 day];
    NSInteger month1 = [components1 month];
    NSInteger year1 = [components1 year];
    
    
    NSDateComponents *components2 = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date2];
    
    NSInteger day2 = [components2 day];
    NSInteger month2 = [components2 month];
    NSInteger year2 = [components2 year];
    
    if(year1 < year2)
        return -1;
    else if(year1 > year2)
        return 1;
    else
    {
        //year1 = year2
        if(month1 < month2)
            return -1;
        else if(month1 > month2)
            return 1;
        else
        {
            //year1 = year2 && month1 = month2
            if(day1 < day2)
                return -1;
            else if(day1 > day2)
                return 1;
            else
                return 0;
        }
    }
    return 0;
}




@end
