#define EX_PICKER_TYPE @"ex_picker_type"
#define CUSTOM_VALUES @"custom_values"

typedef enum {
    ExPickerTypeFull = 0,
    ExPickerTypeDay,
    ExPickerTypeYear,
    ExPickerTypeMonthAndYear,
    ExPickerTypeDayAndMonth,
    ExPickerTypeCustomValues
} ExPickerType;

@protocol ExDatePickerValueChangedDelegate <NSObject>
@optional

- (void)exDatePickerValueChanged:(id)sender;

@end

@interface ExDatePickerView : UIPickerView <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) NSDate *date;

-(void)selectCurrentDay;

//-(void)setPickerType:(ExPickerType)type;
@property (nonatomic) ExPickerType pickerType;

@property (nonatomic, weak) id <ExDatePickerValueChangedDelegate> valueChangedDelegate;

//@property (nonatomic, strong) NSNumber *maxDaysCount;
@property (nonatomic, strong) NSArray *customValues;

@end
