#ifndef Poison_SCSafeUnicode_h
#define Poison_SCSafeUnicode_h

#ifdef TRY_TO_PREVENT_UNICODE_CRASH
#define SC_SANITIZED_STRING(theString) [theString stringByReplacingOccurrencesOfString:killString withString:@""]
#else
#define SC_SANITIZED_STRING(theString) theString
#endif

FOUNDATION_EXPORT NSString *const killString;

#endif