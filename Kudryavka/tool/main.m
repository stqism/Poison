#import <Foundation/Foundation.h>
#import <Kudryavka/Kudryavka.h>

void usage(const char *name) {
    printf("usage: %s show <name-of-file>\n", name);
    printf("usage: %s changepass <name-of-file>\n", name);
    printf("usage: %s convert <name-of-v1-file> <name-of-output-file>\n", name);
}

int verb_show(int argc, const char *argv[]) {
    if (argc < 3) {
        puts("show: no file specified");
        return 1;
    }
    NSData *d = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[2]]];
    if (!d) {
        puts("show: can't read file");
        return 1;
    }
    char *pass = getpass("file password? > ");
    NKDataSerializer *kud = [[NKDataSerializer alloc] init];
    NSDictionary *dict = [kud decryptDataBlob:d withPassword:[NSString stringWithUTF8String:pass]];
    if (!dict) {
        puts("show: file corrupt, or password incorrect");
        return 1;
    }
    printf("%s\n", [[dict description] UTF8String]);
    return 0;
}

int verb_cp(int argc, const char *argv[]) {
    return 0;
}

int verb_conv(int argc, const char *argv[]) {
    return 0;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        puts("KudryavkaTool version 1.1.");
        if (argc < 2) {
            usage(argv[0]);
            return 0;
        }
        if (!strcmp(argv[1], "show")) {
            return verb_show(argc, argv);
        } else if (!strcmp(argv[1], "changepass")) {
            return verb_cp(argc, argv);
        } else if (!strcmp(argv[1], "convert")) {
            return verb_conv(argc, argv);
        } else {
            usage(argv[0]);
            return 0;
        }
    }
    return 0;
}

