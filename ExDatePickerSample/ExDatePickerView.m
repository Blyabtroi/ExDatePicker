#import "ExDatePickerView.h"


// Identifiers of components
#define DAY_COMPONENT 0
#define MONTH_COMPONENT 1
#define YEAR_COMPONENT 2
#define CUSTOM_COMPONENT 3

#define SECONDS_IN_24H 86400

#define DEFAULT_NUMBER_OF_COMPONENTS 3

#define YEAR_WITH_29TH_FEBRUARY 2016

// Identifies for component views
#define LABEL_TAG 43


@interface ExDatePickerView()

@property (nonatomic, strong) NSMutableArray *currentDayIndexPath;
@property (nonatomic, strong) NSArray *months;
@property (nonatomic, strong) NSArray *years;
@property (nonatomic, strong) NSArray *days;


@property (nonatomic, strong) NSArray *components;

-(NSArray *)yearsValues;
-(NSArray *)monthsValues:(NSInteger)year;
-(NSArray *)daysValuesFor:(NSInteger)month year:(NSInteger)year;// noMoreThan:(NSNumber *)maxDaysCount;
-(CGFloat)componentWidthfor:(NSInteger)component;

-(UILabel *)labelForComponent:(NSInteger)component selected:(BOOL)selected;
-(NSString *)titleForRow:(NSInteger)row forComponent:(NSInteger)component;

-(NSMutableArray *)todayPath;
-(NSMutableArray *)pathForDate:(NSDate *)date;

-(NSInteger)bigRowMonthCount;
-(NSInteger)bigRowYearCount;
-(NSInteger)bigRowDayCount;

-(NSNumber *)todayNumber;
-(NSString *)todayMonthName;
-(NSNumber *)todayYearNumber;

-(NSNumber *)dayNumberFrom:(NSDate *)date;
-(NSString *)monthNameFrom:(NSDate *)date;
-(NSInteger)monthNumberFromName:(NSString *)month;
-(NSInteger)monthNumberFrom:(NSDate *)date;
-(NSNumber *)yearNumberFrom:(NSDate *)date;

@end



@implementation ExDatePickerView

const NSInteger bigRowCount = 1000;
const NSInteger minYear = 1700;
const NSInteger maxYear = 2100;
//const NSInteger minDay = 1;
//const NSInteger maxDay = 31;
const CGFloat rowHeight = 44.f;

@synthesize date = _date;
@synthesize currentDayIndexPath;
@synthesize months = _months;
@synthesize years = _years;
@synthesize days = _days;
@synthesize components;
//@synthesize maxDaysCount = _maxDaysCount;
@synthesize customValues = _customValues;
@synthesize pickerType = _pickerType;


- (id) init
{
    self = [super init];
    if (self)
    {
        self.components = [NSArray arrayWithObjects: [NSNumber numberWithInt:DAY_COMPONENT], [NSNumber numberWithInt:MONTH_COMPONENT], [NSNumber numberWithInt:YEAR_COMPONENT], nil];
        
        NSDate *rightNow = [NSDate date];
        NSInteger year = [[self yearNumberFrom:rightNow] integerValue];
        
        self.months = [self monthsValues:year];
        self.years = [self yearsValues];
        self.days = [self daysValuesFor:1 year:year];
        self.currentDayIndexPath = [self todayPath];
        
        self.date = rightNow;// [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
        
        
//        self.months = [self monthsValues];
//        self.years = [self yearsValues];
//        self.days = [self daysValuesFor:1];
//        self.currentDayIndexPath = [self todayPath];
        
        self.delegate = self;
        self.dataSource = self;
        
        [self selectCurrentDay];
    }
    return self;
}

-(void)setDate:(NSDate *)date
{
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    
    if (date != _date)
    {
        _date = date;
        
        NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:_date];

        if (self.pickerType == ExPickerTypeCustomValues)
        {
            NSMutableArray *days = [NSMutableArray array];
            
            for (int i=1; i<=[self.customValues count]; i++) {
                [days addObject:[NSNumber numberWithInt:i]];
            }
            
            self.days = days;
            [self reloadComponent:DAY_COMPONENT];
        }
        else
        {
            self.days = [self daysValuesFor:[dateComponents month] year:[dateComponents year]];
            [self reloadComponent:DAY_COMPONENT];
        }
        
        self.currentDayIndexPath = [self pathForDate:date];
        [self selectCurrentDay];
    }
}


-(NSDate *)date
{
    NSNumber *day;
    NSString *month;
    NSNumber *year;
   
    BOOL isDay = NO;
    BOOL isMonth = NO;
    for (NSNumber *comp in self.components) {
        switch ([comp intValue]) {
            case CUSTOM_COMPONENT: {
                isDay = YES;
                NSInteger dayCount = [self.days count];
                day = [self.days objectAtIndex:([self selectedRowInComponent:DAY_COMPONENT] % dayCount)];
                
            }
                break;
            case DAY_COMPONENT: {
                isDay = YES;
                NSInteger dayCount = [self.days count];
                day = [self.days objectAtIndex:([self selectedRowInComponent:DAY_COMPONENT] % dayCount)];
            }
                break;
            case MONTH_COMPONENT: {
                isMonth = YES;
                NSInteger monthCount = [self.months count];
                month = [self.months objectAtIndex:([self selectedRowInComponent:MONTH_COMPONENT - (isDay ? 0 : 1)] % monthCount)];
            }
                break;
            case YEAR_COMPONENT: {
                NSInteger yearCount = [self.years count];
                year = [self.years objectAtIndex:([self selectedRowInComponent:YEAR_COMPONENT - (isDay ? 0 : 1) - (isMonth ? 0 : 1)] % yearCount)];
            }
                break;
            default:
                break;
        }
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd.MMMM.yyyy"];
    NSString *formatable = [NSString stringWithFormat:@"%@.%@.%@", (day != nil ? day : [self dayNumberFrom:_date]), (month != nil ? month : [self monthNameFrom:_date]), (year != nil ? year : [self yearNumberFrom:_date])];
    NSDate *date = [formatter dateFromString:formatable];
    return date; 
}

-(void)setCustomValues:(NSArray *)customValues
{
    NSUInteger count = [customValues count];
    
    NSAssert(count < 32, @"Количество customValues не может быть больше 31, так как привязано к self.days.");
    
    if (customValues != _customValues)
    {
        NSMutableArray *days = [NSMutableArray array];
        
        _customValues = [NSArray arrayWithArray:customValues];
        
        for (int i=1; i<=count; i++) {
            [days addObject:[NSNumber numberWithInt:i]];
        }
        
        self.days = days;
        
        [self reloadComponent:DAY_COMPONENT];
    }
}

//-(void)setMaxDaysCount:(NSNumber *)maxDaysCount
//{
//    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
//    
//    if (maxDaysCount != _maxDaysCount)
//    {
//        _maxDaysCount = maxDaysCount;
//        
//        NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:self.date];
//        self.days = [self daysValuesFor:[dateComponents month] noMoreThan:maxDaysCount];
//
//        [self reloadComponent:DAY_COMPONENT];
//    }
//}

-(void)setPickerType:(ExPickerType)pickerType
{
    if (_pickerType != pickerType) {
        _pickerType = pickerType;
        
        switch (pickerType) {
            case ExPickerTypeCustomValues:
                self.components = [NSArray arrayWithObjects:[NSNumber numberWithInt:CUSTOM_COMPONENT], nil];
                break;
            case ExPickerTypeDay:
                self.components = [NSArray arrayWithObjects:[NSNumber numberWithInt:DAY_COMPONENT], nil];
                break;
            case ExPickerTypeYear:
                self.components = [NSArray arrayWithObjects:[NSNumber numberWithInt:YEAR_COMPONENT], nil];
                break;
            case ExPickerTypeMonthAndYear:
                self.components = [NSArray arrayWithObjects:[NSNumber numberWithInt:MONTH_COMPONENT], [NSNumber numberWithInt:YEAR_COMPONENT], nil];
                break;
            case ExPickerTypeDayAndMonth:
                self.components = [NSArray arrayWithObjects:[NSNumber numberWithInt:DAY_COMPONENT], [NSNumber numberWithInt:MONTH_COMPONENT], nil];
                break;
            case ExPickerTypeFull:
            default:
                self.components = [NSArray arrayWithObjects: [NSNumber numberWithInt:DAY_COMPONENT], [NSNumber numberWithInt:MONTH_COMPONENT], [NSNumber numberWithInt:YEAR_COMPONENT], nil];
                break;
        }
        [self reloadAllComponents];
        
        [self selectCurrentDay];
    }
}

#pragma mark - UIPickerViewDelegate
-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return [self componentWidthfor:component];
}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView: (UIView *)view
{
    BOOL selected = NO;
    NSNumber *comp = [self.components objectAtIndex:component];
    if ([comp intValue] == DAY_COMPONENT)
    {
        NSInteger dayCount = [self.days count];
        NSNumber *dayNumber = [self.days objectAtIndex:(row % dayCount)];
        NSNumber *currentDayNumber = [self todayNumber];
        if([dayNumber isEqualToNumber:currentDayNumber] == YES)
        {
            selected = YES;
        }
    }
    else if ([comp intValue] == MONTH_COMPONENT)
    {
        NSInteger monthCount = [self.months count];
        NSString *monthName = [self.months objectAtIndex:(row % monthCount)];
        NSString *currentMonthName = [self todayMonthName];
        if([monthName isEqualToString:currentMonthName] == YES)
        {
            selected = YES;
        }
    }
    else if ([comp intValue] == YEAR_COMPONENT)
    {
        NSInteger yearCount = [self.years count];
        NSNumber *yearNumber = [self.years objectAtIndex:(row % yearCount)];
        NSNumber *currenrYearNumber  = [self todayYearNumber];
        if([yearNumber isEqualToNumber:currenrYearNumber] == YES)
        {
            selected = YES;
        }
    }
    
    UILabel *returnView = nil;
    if(view.tag == LABEL_TAG)
    {
        returnView = (UILabel *)view;
    }
    else
    {
        returnView = [self labelForComponent: component selected: selected];
    }
    
    returnView.textColor = selected ? [UIColor blueColor] : [UIColor blackColor];
    returnView.text = [self titleForRow:row forComponent:component];
    return returnView;
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return rowHeight;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ((self.pickerType == ExPickerTypeDayAndMonth) || (self.pickerType == ExPickerTypeFull))
    {
        NSNumber *comp = [self.components objectAtIndex:component];
        
        if (([comp intValue] == MONTH_COMPONENT) || ([comp intValue] == YEAR_COMPONENT))//надо пересчитать количество дней в выбранном месяце
        {
            NSInteger dayCount = [self.days count];
            NSInteger day = [[self.days objectAtIndex:([self selectedRowInComponent:DAY_COMPONENT] % dayCount)] integerValue]; //день, на который надо спозиционироваться в новом месяце
            
            NSInteger monthCount = [self.months count];
            NSString *monthName = [self.months objectAtIndex:([self selectedRowInComponent:MONTH_COMPONENT] % monthCount)];
            NSInteger month = [self monthNumberFromName:monthName];
            
            NSInteger year;
            if (self.pickerType == ExPickerTypeFull) {
                NSInteger yearCount = [self.years count];
                year = [[self.years objectAtIndex:([self selectedRowInComponent:YEAR_COMPONENT] % yearCount)] integerValue];
            }
            else {
                year = YEAR_WITH_29TH_FEBRUARY;
            }
            NSArray *days = [self daysValuesFor:month year:year]; //количество дней в новом месяце
            
            NSInteger newDayCount = [days count];
            if (newDayCount != dayCount) { //обновление только если в новом месяце не столько же дней
            
                self.days = days;
                [self reloadComponent:DAY_COMPONENT];
            
                BOOL isThereDay = day > newDayCount;
                if (isThereDay)
                    day = newDayCount - 1; //если в новом месяце меньше дней, чем выбранный день
                else
                    day = day - 1; //для row нумерация начинается с 0
                day = day + [self bigRowDayCount] / 2;
                [self selectRow: day
                    inComponent: DAY_COMPONENT
                       animated: isThereDay]; //явно надо спозиционироваться на новом дне, когда в новом месяце нет такого дня
            }
        }
    }
    
    if ([self.valueChangedDelegate respondsToSelector:@selector(exDatePickerValueChanged:)]) {
        [self.valueChangedDelegate exDatePickerValueChanged:self];
    }
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return [self.components count];
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSNumber *comp = [self.components objectAtIndex:component];
    if ([comp intValue] == MONTH_COMPONENT)
    {
        return [self bigRowMonthCount];
    }
    else if ([comp intValue] == YEAR_COMPONENT)
    {
        return [self bigRowYearCount];
    }
    else if ([comp intValue] == DAY_COMPONENT)
    {
        return [self bigRowDayCount];
    }
    else //CUSTOM_COMPONENT
    {
        return [self bigRowDayCount];
    }
}

#pragma mark - Util
-(NSInteger)bigRowMonthCount
{
    return [self.months count]  * bigRowCount;
}

-(NSInteger)bigRowYearCount
{
    return [self.years count]  * bigRowCount;
}

-(NSInteger)bigRowDayCount
{
    return [self.days count]  * bigRowCount;
}

-(CGFloat)componentWidthfor:(NSInteger)component
{
    NSNumber *comp = [self.components objectAtIndex:component];
    NSInteger count = [self.components count];
    
    float dayPart = 1.0;
    float monthPart = 1.0;
    float yearPart = 1.0;
    switch (count) {
        case 3:
            dayPart = 0.5;
            monthPart = 1.5;
            yearPart = 1.0;
            break;
        case 2:
        case 1:
            dayPart = 1.0;
            monthPart = 1.0;
            yearPart = 1.0;
            break;
        default:
            break;
    }
    
    
    if ([comp intValue] == DAY_COMPONENT)
    {
        return self.bounds.size.width * dayPart / count;
    }
    else if([comp intValue] == MONTH_COMPONENT)
    {
        return self.bounds.size.width * monthPart / count;
    }
    else
    {
        return self.bounds.size.width * yearPart / count;
    }
}

-(NSString *)titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSNumber *comp = [self.components objectAtIndex:component];
    if ([comp intValue] == DAY_COMPONENT)
    {
        NSInteger dayCount = [self.days count];
        return [NSString stringWithFormat:@"%@", [self.days objectAtIndex:(row % dayCount)]];
    }
    else if([comp intValue] == MONTH_COMPONENT)
    {
        NSInteger monthCount = [self.months count];
        return [self.months objectAtIndex:(row % monthCount)];
    }
    else if([comp intValue] == YEAR_COMPONENT)
    {
        NSInteger yearCount = [self.years count];
        return [NSString stringWithFormat:@"%@", [self.years objectAtIndex:(row % yearCount)]];
    }
    else //CUSTOM_COMPONENT
    {
        NSInteger customCount = [self.customValues count];
        return [NSString stringWithFormat:@"%@", [self.customValues objectAtIndex:(row % customCount)]];
    }
}

-(UILabel *)labelForComponent:(NSInteger)component selected:(BOOL)selected
{
    CGRect frame = CGRectMake(0.f, 0.f, [self componentWidthfor:component],rowHeight);
    
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.textAlignment = NSTextAlignmentCenter;//UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = selected ? [UIColor blueColor] : [UIColor blackColor];
    label.font = [UIFont boldSystemFontOfSize:22.f];
    label.userInteractionEnabled = NO;
    
    label.tag = LABEL_TAG;
    
    return label;
}

-(NSArray *)monthsValues:(NSInteger)year
{
    NSDateComponents* dateComponents = [[NSDateComponents alloc]init];
    [dateComponents setDay:1];
    [dateComponents setMonth:1];
    [dateComponents setYear:year];
    
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
   
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    NSMutableArray *returnMonths = [NSMutableArray arrayWithCapacity:12];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *locale = [NSLocale currentLocale];
    [formatter setLocale:locale];

    [formatter setDateFormat:@"MMMM"];
    for (int i=0; i<12; i++) {
        
        [returnMonths addObject:[formatter stringFromDate:date]];
        
        [dateComponents setMonth:1];
        
        date = [calendar dateByAddingComponents:dateComponents toDate:date options:0];
    }
    
    return returnMonths;
}

-(NSArray *)yearsValues
{
    NSMutableArray *years = [NSMutableArray array];
    
    for(NSInteger year = minYear; year <= maxYear; year++)
    {
        [years addObject:[NSNumber numberWithInt:year]];
    }
    return years;
}

-(NSArray *)daysValuesFor:(NSInteger)month year:(NSInteger)year
{
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    
    NSMutableArray *days = [NSMutableArray array];
    
    NSDateComponents* dateComponents = [[NSDateComponents alloc]init];
    [dateComponents setDay:1];
    [dateComponents setMonth:month];
    [dateComponents setYear:year];
    [dateComponents setHour:6];
    [dateComponents setMinute:0];
    [dateComponents setSecond:0];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    while ([dateComponents month] == month) {
        NSNumber *day = [NSNumber numberWithInteger:[dateComponents day]];
        [days addObject:day];

//        if (maxDaysCount != nil && [day isEqualToNumber:maxDaysCount]) {
//            break;
//        }
        
        date = [date dateByAddingTimeInterval:SECONDS_IN_24H];
       
        dateComponents = [calendar components:unitFlags fromDate:date];
    }

    return days;
}

-(void)selectCurrentDay
{
    BOOL isDay = NO;
    BOOL isMonth = NO;
    for (NSNumber *comp in self.components) {
        switch ([comp intValue]) {
            case CUSTOM_COMPONENT:
            case DAY_COMPONENT:
                isDay = YES;
                [self selectRow: [[self.currentDayIndexPath objectAtIndex:DAY_COMPONENT] integerValue]
                    inComponent: DAY_COMPONENT
                       animated: NO];
                break;
            case MONTH_COMPONENT:
                isMonth = YES;
                [self selectRow: [[self.currentDayIndexPath objectAtIndex:MONTH_COMPONENT] integerValue]
                    inComponent: MONTH_COMPONENT - (isDay ? 0 : 1)
                       animated: NO];
                break;
            case YEAR_COMPONENT:
                [self selectRow: [[self.currentDayIndexPath objectAtIndex:YEAR_COMPONENT] integerValue]
                    inComponent: YEAR_COMPONENT - (isDay ? 0 : 1) - (isMonth ? 0 : 1)
                       animated: NO];
                break;
            default:
                break;
        }
    }
}

-(NSMutableArray *)todayPath 
{
    CGFloat daySection = 0.f;
    CGFloat monthSection = 0.f;
    CGFloat yearSection = 0.f;
    
    NSNumber *day = [self todayNumber];
    NSString *month = [self todayMonthName];
    NSNumber *year  = [self todayYearNumber];
    
    for(NSNumber *cellDay in self.days)
    {
        if([cellDay isEqualToNumber:day])
        {
            daySection = [self.days indexOfObject:cellDay];
            daySection = daySection + [self bigRowMonthCount] / 2;
            break;
        }
    }
    
    //set table on the middle
    for(NSString *cellMonth in self.months)
    {
        if([cellMonth isEqualToString:month])
        {
            monthSection = [self.months indexOfObject:cellMonth];
            monthSection = monthSection + [self bigRowMonthCount] / 2;
            break;
        }
    }
    
    for(NSNumber *cellYear in self.years)
    {
        if([cellYear isEqualToNumber:year])
        {
            yearSection = [self.years indexOfObject:cellYear];
            yearSection = yearSection + [self bigRowYearCount] / 2;
            break;
        }
    }
    
    NSMutableArray *ret = [NSMutableArray arrayWithObjects:@"0",@"0",@"0", nil];
    
    for (NSNumber *comp in self.components) {
        switch ([comp intValue]) {
            case CUSTOM_COMPONENT:
            case DAY_COMPONENT:
                [ret setObject:[NSNumber numberWithFloat:daySection] atIndexedSubscript:DAY_COMPONENT];
                break;
            case MONTH_COMPONENT:
                [ret setObject:[NSNumber numberWithFloat:monthSection] atIndexedSubscript:MONTH_COMPONENT];
                break;
            case YEAR_COMPONENT:
                [ret setObject:[NSNumber numberWithFloat:yearSection] atIndexedSubscript:YEAR_COMPONENT];
                break;
            default:
                break;
        }
    }

    
    return ret;
}

-(NSMutableArray *)pathForDate:(NSDate *)date
{
    CGFloat daySection = 0.f;
    CGFloat monthSection = 0.f;
    CGFloat yearSection = 0.f;
    
    NSNumber *currentYearNumber = [self yearNumberFrom:date];
    for(NSNumber *cellYear in self.years)
    {
        if([cellYear isEqualToNumber: currentYearNumber])
        {
            yearSection = [self.years indexOfObject:cellYear];
            yearSection = yearSection + [self bigRowYearCount] / 2;
            break;
        }
    }
    
    NSString *currentMonthName = [self monthNameFrom:date];
    for(NSString *cellMonth in self.months)
    {
        if([cellMonth isEqualToString:currentMonthName])
        {
            monthSection = [self.months indexOfObject:cellMonth] ;
            monthSection = monthSection + [self bigRowMonthCount] / 2;
            break;
        }
    }
    
    NSNumber *currentDayNumber = [self dayNumberFrom:date];
    for(NSNumber *cellDay in self.days)
    {
        if([cellDay isEqualToNumber:currentDayNumber])
        {
            daySection = [self.days indexOfObject:cellDay];
            daySection = daySection + [self bigRowDayCount] / 2;
            break;
        }
    }



    NSMutableArray *ret = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:daySection], [NSNumber numberWithFloat:monthSection], [NSNumber numberWithFloat:yearSection], nil];
    
    return ret;
}

-(NSNumber *)todayNumber
{
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:[NSDate date]];
    return [NSNumber numberWithInteger:[dateComponents day]];
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"dd"];
//    return [formatter stringFromDate:[NSDate date]];
}

-(NSString *)todayMonthName
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
//    [formatter setLocale:usLocale];
    [formatter setDateFormat:@"MMMM"];
    return [formatter stringFromDate:[NSDate date]];
}

-(NSNumber *)todayYearNumber
{
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
    return [NSNumber numberWithInteger:[dateComponents year]];
}

-(NSNumber *)dayNumberFrom:(NSDate *)date
{
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:date];
    return [NSNumber numberWithInteger:[dateComponents day]];
}

-(NSString *)monthNameFrom:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM"];
    return [formatter stringFromDate:date];
}

-(NSInteger)monthNumberFrom:(NSDate *)date
{
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:date];
    return [dateComponents month];
}

-(NSInteger)monthNumberFromName:(NSString *)month
{
    int i = 1;
    for(NSString *cellMonth in [self monthsValues:YEAR_WITH_29TH_FEBRUARY])
    {
        if([cellMonth isEqualToString:month])
        {
            return i;
        }
        i++;
    }
    return 0;
}

-(NSNumber *)yearNumberFrom:(NSDate *)date
{
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:date];
    return [NSNumber numberWithInteger:[dateComponents year]];
}

@end
