#import <Foundation/Foundation.h>
#import <Kudryavka/Kudryavka.h>
/* 
 * This simple program demonstrates the usage of the Kudryavka framework.
 * It doesn't do much, just tries to save stuff to the keychain and load it
 * again.
 * Note: this program should not be distributed in Poison binaries.
 */
int main(int argc, char **argv) {
    @autoreleasepool {
        NKDataSerializer *serializer = [NKDataSerializer serializerUsingMethod:NKSerializerKeychain];
        NSError *err = nil;
        [serializer serializePrivateKey:@"728925473812C7AAC482BE7250BCCAD0B8CB9F737BF3D42ABD34459C1768F854" publicKey:@"728925473812C7AAC482BE7250BCCAD0B8CB9F737BF3D42ABD34459C1768F854" options:@{@"username": @"stal", @"overwrite": @YES} error:&err];
        NSLog(@"%@", [err userInfo]);
        
        NSDictionary *a = [serializer loadKeysWithOptions:@{@"username": @"stal"} error:&err];
        NSLog(@"%@", [err userInfo]);
        NSLog(@"%@", a);
        
        return 0;
    }
}
