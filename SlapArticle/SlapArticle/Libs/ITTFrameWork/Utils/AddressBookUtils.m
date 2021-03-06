//
//  AddressBookUtils.m
//
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AddressBookUtils.h"
#import "LocaleUtils.h"
#import "UIImage+ITTAdditions.h"
@implementation AddressBookUtils

//get all contacts获取通讯录中的所有人
+(NSMutableArray *)getAllContacts
{
	ABAddressBookRef addressBook;
	if (IS_IOS_7) {
		addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
	}
	else {
		addressBook = ABAddressBookCreate();
	}
	NSMutableArray *personArray = (__bridge_transfer NSMutableArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSMutableArray *validPersonArray = [NSMutableArray array];
    for (id person in personArray) {
        ABRecordRef personRef = (__bridge ABRecordRef)person;
        if (![AddressBookUtils hasCellPhones:personRef]) {
            continue;
        }
        [validPersonArray addObject:@{@"name": [AddressBookUtils getFullName:personRef],@"phone": [AddressBookUtils getFirstCellPhoneNum:personRef],@"mail": [AddressBookUtils getFirstEmail:personRef]}];
        
        ITTDINFO(@"\nname:%@ number:%@", [AddressBookUtils getFullName:personRef],[AddressBookUtils getFirstCellPhoneNum:personRef]);
        if ([AddressBookUtils hasImageByPerson:personRef]) {
            ITTDINFO(@"has image%@", [AddressBookUtils getImageByPerson:personRef]);
        }
    }
    CFRelease(addressBook);
	return validPersonArray;
}


// return label, but remove prefix and suffix in "_$!<Mobile>!$_"
+ (NSString *)getPhoneLabel:(ABMultiValueRef)phones index:(int)index
{
    NSString* origLabel = (NSString *)CFBridgingRelease(ABMultiValueCopyLabelAtIndex(phones, index));    
    
    NSString* localizedLabel = (__bridge_transfer NSString *)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)origLabel);
    
    NSString* finalLabel = [NSString stringWithString:localizedLabel];
    
    finalLabel = [finalLabel stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
    finalLabel = [finalLabel stringByReplacingOccurrencesOfString:@">!$_" withString:@""];    
    
    
    return finalLabel;
}

+ (NSDate*)copyModificationDate:(ABRecordRef)person
{
    NSDate* date = (NSDate *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonModificationDateProperty));
    
    return date;
}

+ (NSString *)getFullName:(ABAddressBookRef)addressBook personId:(int)personId
{
    ABRecordRef personRef = ABAddressBookGetPersonWithRecordID(addressBook, personId);
    if (!personRef)
        return nil;
    else {
        return [AddressBookUtils getFullName:personRef];
    }
}

+ (NSString *)getFullName:(ABRecordRef)person
{
    
    
    CFStringRef name = ABRecordCopyCompositeName(person);
    if (name == NULL){
        return @"";
    }
    
    NSString* ret = [NSString stringWithString:(__bridge NSString*)name];
    
    CFRelease(name);
    
    return ret;
}

+ (NSArray *)getPhonesWithAddressBook:(ABRecordID)personId addressBook:(ABAddressBookRef)addressBook
{
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, personId);
    if (person){
        return [AddressBookUtils getPhones:person];
    }
    else {
        return nil;
    }
}

// get the first phone number to display
+ (BOOL)hasPhones:(ABRecordRef)person
{
    NSArray* phones = [AddressBookUtils getPhones:person];
    if (phones != nil && [phones count] > 0){
        return YES;
    }
    else {
        return NO;
    }
}

//TODO:adjust the logic of cellphone validation
+ (BOOL)isCellPhoneNum:(NSString*)num
{
    if (!num || num.length == 0) {
        return NO;
    }
    return YES;
    /*
    if (num.length == 11 && ([num hasPrefix:@"13"] || [num hasPrefix:@"15"] || [num hasPrefix:@"18"]) ) {
        return YES;
    }
    return  NO;*/
}

+ (BOOL)hasCellPhones:(ABRecordRef)person
{
    NSArray* phones = [AddressBookUtils getPhones:person];
    if (phones != nil && [phones count] > 0){
        for (NSString *phoneNum in phones) {
            if ([AddressBookUtils isCellPhoneNum:phoneNum]) {
                return YES;
            }
        }
        return NO;
    }else {
        return NO;
    }
}

+ (NSString*)getFirstCellPhoneNum:(ABRecordRef)person
{
    NSArray* phones = [AddressBookUtils getPhones:person];
    if (phones != nil && [phones count] > 0){
        for (NSString *phoneNum in phones) {
            if ([AddressBookUtils isCellPhoneNum:phoneNum]) {
                return phoneNum;
            }
        }
        return nil;
    }
    return nil;
    
}

+ (BOOL)hasEmails:(ABRecordRef)person
{
    NSArray* emails = [AddressBookUtils getEmails:person];
    if (emails != nil && [emails count] > 0){
        return YES;
    }
    else {
        return NO;
    }
    
}
+ (NSArray *)getPhones:(ABRecordRef)person
{
    NSMutableArray* phoneList = [[NSMutableArray alloc] init];
    
    ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);    
    if (phones){
        int count = ABMultiValueGetCount(phones);
        for (CFIndex i = 0; i < count; i++) {
            NSString *phoneNumber = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(phones, i));
            [phoneList addObject:phoneNumber];
            
        }
        CFRelease(phones);
    }
    return phoneList;
}

+ (NSArray *)getEmailsWithAddressBook:(ABRecordID)personId addressBook:(ABAddressBookRef)addressBook
{
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, personId);
    if (person){
        return [AddressBookUtils getEmails:person];
    } else {
        return nil;
    }
}
// can be refactored to the same implementation later
+ (NSArray *)getEmails:(ABRecordRef)person
{
    NSMutableArray* emailList = [[NSMutableArray alloc] init];
    
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);    
    if (emails){
        for (CFIndex i = 0; i < ABMultiValueGetCount(emails); i++) {
            NSString *label       = (NSString *)CFBridgingRelease(ABMultiValueCopyLabelAtIndex(emails, i));
            NSString *value      = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, i));
            
            NSLog(@"email label (%@), number (%@)", label, value);
            
            [emailList addObject:value];
            
        }
        CFRelease(emails);
    }
    
    return emailList;
}

+ (NSString *)getFirstEmail:(ABRecordRef)person
{
    NSArray* emails = [AddressBookUtils getEmails:person];
    if (emails != nil && [emails count] > 0){
        return emails[0];
    }
    else {
        return @"";
    }
}

+ (UIImage*)getImageByPerson:(ABRecordRef)person
{
    UIImage* image = nil;
    
    if (ABPersonHasImageData(person)){
        
        NSData* data = (NSData *)CFBridgingRelease(ABPersonCopyImageData(person));
        image = [UIImage imageWithData:data];
        
    }
    
    return image;    
}

+ (BOOL)hasImageByPerson:(ABRecordRef)person
{
    return ([AddressBookUtils getImageByPerson:person] != nil);
}

+ (UIImage*)getSmallImage:(ABRecordRef)person size:(CGSize)size
{
    UIImage* image = [AddressBookUtils getImageByPerson:person];
    
    if (image != nil){
        // resize image
        return [image imageFitInSize:size];
    }
    
    return nil;
}

+ (NSString*)getShortName:(ABRecordRef)person
{
    NSString* firstName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
    NSString* lastName  = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
    NSString* orgName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonOrganizationProperty));
    
    BOOL useOrgName = NO;
    
    if (firstName == nil && lastName == nil)
        useOrgName = YES;
    
    if (firstName == nil)
        firstName = @"";
    
    if (lastName == nil)
        lastName = @"";        
    
    NSString* fullName;
    
    if (useOrgName == NO){
        NSString* countryCode = [LocaleUtils getCountryCode];
        if (countryCode != nil && ( [countryCode isEqualToString:@"CN"] == YES ||
                                   [countryCode isEqualToString:@"TW"] == YES ||
                                   [countryCode isEqualToString:@"KR"] == YES ||
                                   [countryCode isEqualToString:@"JP"] == YES)                                  
            )
        {
            if ([lastName length] > 0){
                fullName = [NSString stringWithFormat:@"%@ %@", lastName, firstName];    
            }
            else {
                fullName = [NSString stringWithString:firstName];
            }
            
        }
        else {            
            if ([firstName length] > 0){
                fullName = [NSString stringWithFormat:@"%@", firstName];    
            }
            else {
                fullName = [NSString stringWithString:lastName];
            }
            
        }    
    } else {
        
        if (orgName == nil){
            orgName = @"";
        }
        
        fullName = [NSString stringWithFormat:@"%@", orgName];
    }
    
    
    return fullName;
    
}

+ (BOOL)addPhone:(ABRecordRef)person phone:(NSString*)phone
{
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    
    CFErrorRef anError = NULL;
    
    // The multivalue identifier of the new value isn't used in this example,
    // multivalueIdentifier is just for illustration purposes.  Real-world
    // code can use this identifier to do additional work with this value.
    ABMultiValueIdentifier multivalueIdentifier;
    
    if (!ABMultiValueAddValueAndLabel(multi, (__bridge CFStringRef)phone, kABPersonPhoneMainLabel, &multivalueIdentifier)){
        CFRelease(multi);
        return NO;
    }
    
    if (!ABRecordSetValue(person, kABPersonPhoneProperty, multi, &anError)){
        CFRelease(multi);
        return NO;
    }
    CFRelease(multi);
    return YES;
}

+ (BOOL)addAddress:(ABRecordRef)person street:(NSString*)street
{
    ABMutableMultiValueRef address = ABMultiValueCreateMutable(kABDictionaryPropertyType);
    
    static int  homeLableValueCount = 5;
    
    // Set up keys and values for the dictionary.
    CFStringRef keys[homeLableValueCount];
    CFStringRef values[homeLableValueCount];
    keys[0]      = kABPersonAddressStreetKey;
    keys[1]      = kABPersonAddressCityKey;
    keys[2]      = kABPersonAddressStateKey;
    keys[3]      = kABPersonAddressZIPKey;
    keys[4]      = kABPersonAddressCountryKey;
    values[0]    = (__bridge CFStringRef)street;
    values[1]    = CFSTR("");
    values[2]    = CFSTR("");
    values[3]    = CFSTR("");
    values[4]    = CFSTR("");
    
    CFDictionaryRef aDict = CFDictionaryCreate(
                                               kCFAllocatorDefault,
                                               (void *)keys,
                                               (void *)values,
                                               homeLableValueCount,
                                               &kCFCopyStringDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks
                                               );
    
    // Add the street address to the person record.
    ABMultiValueIdentifier identifier;
    
    ABMultiValueAddValueAndLabel(address, aDict, kABHomeLabel, &identifier);    
    CFErrorRef error = NULL;
    BOOL result = ABRecordSetValue(person, kABPersonAddressProperty, address, &error);
    
    CFRelease(aDict);    
    CFRelease(address);    
    
    return result;
}

+ (BOOL)addImage:(ABRecordRef)person image:(UIImage*)image
{
    CFErrorRef error = NULL;
    
    // remove old image data firstly
    ABPersonRemoveImageData(person, NULL);
    
    // add new image data
    BOOL result = ABPersonSetImageData (
                                        person,
                                        (__bridge CFDataRef)UIImagePNGRepresentation(image),
                                        &error
                                        );    
    
    //    CFRelease(error);
    
    return result;
}

+ (NSString*)getPersonNameByPhone:(NSString*)phone addressBook:(ABAddressBookRef)addressBook
{
    ABRecordRef personRef = [AddressBookUtils getPersonByPhone:phone addressBook:addressBook];
    if (personRef == NULL){
        return @"";
    } else {
        return [AddressBookUtils getFullName:personRef];
    }
    
}

+ (ABRecordRef)getPersonByPhone:(NSString*)phone addressBook:(ABAddressBookRef)addressBook
{
    if (phone == nil || [phone length] <= 0 || addressBook == NULL){
        return NULL;
    }
    
    NSArray* people = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
    ABRecordRef retPersonRef = NULL;
    
    BOOL found = NO;
    for (NSObject* person in people){
        ABRecordRef personRef = (__bridge ABRecordRef)person;
        
        NSArray* phonesOfPerson = [AddressBookUtils getPhones:personRef];
        for (NSString* phoneOfPerson in phonesOfPerson){
            if ([phone isEqualToString:phoneOfPerson] == YES){
                found = YES;
                break;
            }
        }
        
        if (found){
            retPersonRef = (__bridge ABRecordRef)person;
            break;
        }
    }
    
    
    return retPersonRef;
}
@end