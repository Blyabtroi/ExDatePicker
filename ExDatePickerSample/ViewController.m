//
//  ViewController.m
//  ExDatePickerSample
//
//  Created by Vasiliy Kozlov on 23.01.14.
//  Copyright (c) 2014 vk. All rights reserved.
//

#import "ViewController.h"
#import "ExDatePickerView.h"

static NSString *kCellPickerID = @"CellPicker";

@interface ViewController () <ExDatePickerValueChangedDelegate>

@property (nonatomic, strong) ExDatePickerView *exPicker;

@property (nonatomic, strong) NSIndexPath *datePickerIndexPath;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.exPicker = [[ExDatePickerView alloc] init];
    self.exPicker.backgroundColor = [UIColor whiteColor];
    self.exPicker.showsSelectionIndicator = YES;
    self.exPicker.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth);
    self.exPicker.valueChangedDelegate = self;
    self.exPicker.pickerType = ExPickerTypeFull;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifierData = @"CellDate";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierData];
    
    if ([indexPath compare:self.datePickerIndexPath] == NSOrderedSame && [self hasInlineDatePicker])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kCellPickerID];
        if (nil == cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellPickerID];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        [cell.contentView addSubview:self.exPicker];
        CGRect startFrame = cell.contentView.frame;
        startFrame.origin.y = 0;
        startFrame.size.height = self.exPicker.frame.size.height;
        self.exPicker.frame = startFrame;
        
        return cell;
    }
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierData];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", self.exPicker.date];
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:kCellPickerID])
        return;
    
    switch (indexPath.row) {
        case 0:
            self.exPicker.pickerType = ExPickerTypeFull;
            break;
        case 1:
            self.exPicker.pickerType = ExPickerTypeDayAndMonth;
            break;
        case 2:
            self.exPicker.pickerType = ExPickerTypeMonthAndYear;
            break;
        case 3:
            self.exPicker.pickerType = ExPickerTypeDay;
            break;
        case 4:
            self.exPicker.pickerType = ExPickerTypeYear;
            break;
        case 5:
            [self.exPicker setCustomValues:[NSArray arrayWithObjects:@"one", @"two", @"three", @"four", @"five", nil]];
            self.exPicker.pickerType = ExPickerTypeCustomValues;
            break;
        default:
            break;
    }
    
    [self displayInlineDatePickerForRowAtIndexPath:indexPath];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self hasInlineDatePicker] && section == self.datePickerIndexPath.section)
    {
        return 6;
    }
    return 5;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self hasInlineDatePicker] && self.datePickerIndexPath.row == indexPath.row) {
        return 216.0f;
    }
    return 44.0f;
}

- (void)displayInlineDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // display the date picker inline with the table content
    [self.tableView beginUpdates];
    
    BOOL before = NO;   // indicates if the date picker is below "indexPath", help us determine which row to reveal
    if ([self hasInlineDatePicker])
    {
        before = self.datePickerIndexPath.row < indexPath.row;
    }
    
    BOOL sameCellClicked = (self.datePickerIndexPath.row - 1 == indexPath.row) && (self.datePickerIndexPath.section == indexPath.section);
    
    // remove any date picker cell if it exists
    if ([self hasInlineDatePicker])
    {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.datePickerIndexPath.row inSection:self.datePickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
    }
    
    NSIndexPath *indexPathToReveal = nil;
    
    if (!sameCellClicked)
    {
        // hide the old date picker and display the new one
        NSInteger rowToReveal = (before ? indexPath.row - 1 : indexPath.row);
        indexPathToReveal = [NSIndexPath indexPathForRow:rowToReveal inSection:indexPath.section];
        
        [self toggleDatePickerForSelectedIndexPath:indexPathToReveal];
        self.datePickerIndexPath = [NSIndexPath indexPathForRow:indexPathToReveal.row + 1 inSection:indexPath.section];
    }
    
    // always deselect the row containing the start or end date
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView endUpdates];
    
    if (indexPathToReveal != nil)
        [self.tableView selectRowAtIndexPath:indexPathToReveal animated:YES scrollPosition:UITableViewScrollPositionTop];

}

/*! Adds or removes a UIDatePicker cell below the given indexPath.
 @param indexPath The indexPath to reveal the UIDatePicker.
 */
- (void)toggleDatePickerForSelectedIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
    
    // check if 'indexPath' has an attached date picker below it
    if ([self hasPickerForIndexPath:indexPath])
    {
        // found a picker below it, so remove it
        [self.tableView deleteRowsAtIndexPaths:indexPaths
                                withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        // didn't find a picker below it, so we should insert it
        [self.tableView insertRowsAtIndexPaths:indexPaths
                                withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.tableView endUpdates];
}

/*! Determines if the UITableViewController has a UIDatePicker in any of its cells.
 */
- (BOOL)hasInlineDatePicker
{
    return (self.datePickerIndexPath != nil);
}

/*! Determines if the given indexPath points to a cell that contains the UIDatePicker.
 @param indexPath The indexPath to check if it represents a cell with the UIDatePicker.
 */
- (BOOL)indexPathHasPicker:(NSIndexPath *)indexPath
{
    return ([self hasInlineDatePicker] && self.datePickerIndexPath.row == indexPath.row);
}

/*! Determines if the given indexPath has a cell below it with a UIDatePicker.
 @param indexPath The indexPath to check if its cell has a UIDatePicker below it.
 */
- (BOOL)hasPickerForIndexPath:(NSIndexPath *)indexPath
{
    BOOL hasDatePicker = NO;
    
    NSInteger targetedRow = indexPath.row;
    targetedRow++;
    
    UITableViewCell *checkDatePickerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:targetedRow inSection:indexPath.section]];
    NSArray *subs = [checkDatePickerCell.contentView subviews];
    
    id checkDatePicker = ([subs count] > 0 ? (ExDatePickerView *)subs[0] : nil);
    
    hasDatePicker = [checkDatePicker isKindOfClass:[ExDatePickerView class]];
    return hasDatePicker;
}

- (void)cancelPicker
{
    if ([self hasInlineDatePicker]) {
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[self.datePickerIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
        [self.tableView endUpdates];
    }}
@end
